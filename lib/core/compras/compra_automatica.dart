import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../features/accounts/accounts_service.dart';
import '../../features/categories/categories_service.dart';
import '../../features/transactions/category_suggestion.dart';
import '../../features/transactions/transactions_service.dart';
import '../api/api_client.dart';
import '../currency/exchange_rates.dart';
import '../home_widget/home_widget_sync.dart';
import '../models/cuenta_models.dart';
import '../models/transaccion_models.dart';
import '../notifications/notification_service.dart';
import '../prefs/form_prefs.dart';
import '../quick_launch/quick_launch.dart';
import 'compra_parser.dart';

/// Registro automático de las compras que se pagan con el teléfono (NFC) o
/// con tarjeta: `PurchaseListenerService.kt` ve la notificación del pago y
/// arranca `compraDetectadaMain` (main.dart), que llega aquí.
class CompraAutomatica {
  CompraAutomatica._();

  static const _storage = FlutterSecureStorage();
  static const _activoKey = 'comprasAutomaticas';
  static const _ingresosKey = 'ingresosAutomaticos';
  static const _registroKey = 'comprasDetectadas';
  static const _ajustes = MethodChannel('financially/compras_ajustes');
  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

  static bool get soportado => !kIsWeb && Platform.isAndroid;

  // ── Ajustes (Perfil) ────────────────────────────────────────────────────

  static Future<bool> activo() async {
    try {
      return await _storage.read(key: _activoKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setActivo(bool v) async {
    try {
      await _storage.write(key: _activoKey, value: '$v');
    } catch (_) {
      // Sin almacenamiento el registro automático queda apagado
    }
  }

  /// También el dinero que entra ("Recibiste $50.000 de…"). Encendido por
  /// defecto mientras el registro automático esté activo.
  static Future<bool> ingresosActivos() async {
    try {
      return await _storage.read(key: _ingresosKey) != 'false';
    } catch (_) {
      return true;
    }
  }

  static Future<void> setIngresosActivos(bool v) async {
    try {
      await _storage.write(key: _ingresosKey, value: '$v');
    } catch (_) {
      // Queda con el valor por defecto
    }
  }

  /// true si el usuario ya dio "Acceso a notificaciones" a Financially.
  static Future<bool> tieneAcceso() async {
    if (!soportado) return false;
    try {
      return await _ajustes.invokeMethod<bool>('tieneAcceso') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> abrirAjuste() async {
    try {
      await _ajustes.invokeMethod('abrirAjuste');
    } catch (_) {
      // Sin la pantalla del sistema no hay nada que abrir
    }
  }

  /// Últimas notificaciones de pago vistas y qué se hizo con cada una (para
  /// revisar en Perfil si un banco no se está entendiendo).
  static Future<List<Map<String, dynamic>>> registro() async {
    try {
      final raw = await _storage.read(key: _registroKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _anotar(String fuente, String texto, String resultado) async {
    final lista = await registro()
      ..insert(0, {
        'fecha': DateTime.now().toIso8601String(),
        'fuente': fuente,
        'texto': texto.length > 160 ? '${texto.substring(0, 160)}…' : texto,
        'resultado': resultado,
      });
    try {
      await _storage.write(key: _registroKey, value: jsonEncode(lista.take(15).toList()));
    } catch (_) {
      // El registro es solo informativo
    }
  }

  // ── Procesar una notificación ───────────────────────────────────────────

  static Future<void> procesar(
    String paquete,
    String titulo,
    String texto,
    DateTime cuando,
  ) async {
    if (!await activo()) return;
    final compra = leerCompra(paquete, titulo, texto);
    final fuente = compra?.fuente ?? paquete;
    if (compra == null) {
      await _anotar(fuente, '$titulo · $texto', 'No parece una compra ni un ingreso');
      return;
    }
    if (compra.ingreso && !await ingresosActivos()) {
      await _anotar(fuente, '$titulo · $texto', 'Ingreso sin registrar (apagado)');
      return;
    }

    final tipo = compra.ingreso ? 'INGRESO' : 'GASTO';
    final tipoLabel = compra.ingreso ? 'Ingreso' : 'Gasto';
    final notif = NotificationService.instance;
    final montoTxt = _money.format(compra.monto);
    // "en Éxito" para una compra, "de Juan Perez" para un ingreso
    final lugar = compra.comercio == null
        ? (compra.fuente ?? (compra.ingreso ? 'dinero recibido' : 'compra con tarjeta'))
        : '${compra.ingreso ? 'de' : 'en'} ${compra.comercio}';
    final api = ApiClient();
    if (await api.readRefreshToken() == null && !await api.hasToken()) {
      await _anotar(fuente, '$titulo · $texto', 'Sin sesión iniciada');
      return;
    }

    try {
      final (cuentasAll, categoriasAll, trans) = await (
        AccountsService(api).getAllAccounts(),
        CategoriesService(api).getAllCategories(),
        TransactionsService(api).getAllTransactions(
          fechaInicio: cuando.subtract(const Duration(days: 90)),
        ),
      ).wait;

      // ¿Ya está? Registrada a mano, avisada por dos apps, o una
      // transferencia entre tus cuentas (Bancolombia → Nequi avisa
      // "Recibiste…" y no es un ingreso nuevo)
      final yaEsta = trans.any((t) =>
          (t.monto - compra.monto).abs() < 0.01 &&
          t.fechaTransaccion.difference(cuando).inMinutes.abs() <= 10);
      if (yaEsta) {
        await _anotar(fuente, '$titulo · $texto', 'Ya estaba registrado');
        return;
      }

      final cuentas = cuentasAll.where((c) => c.activa).toList();
      if (cuentas.isEmpty) {
        await _anotar(fuente, '$titulo · $texto', 'No tienes cuentas');
        return;
      }
      final cuenta = await _cuentaPara(compra, cuentas);

      // En otra moneda (p. ej. US$ en Netflix): se convierte a la de la
      // cuenta y el valor original queda en las notas
      var monto = compra.monto;
      String? original;
      if (compra.moneda != null && compra.moneda != cuenta.moneda) {
        final tasas = await ExchangeRates.obtener(cuenta.moneda);
        if (tasas.puede(compra.moneda!)) {
          monto = tasas.aBase(compra.monto, compra.moneda!);
          original = '${compra.moneda} ${compra.monto.toStringAsFixed(2)}';
        }
      }

      // Categoría por el comercio (o por quién envía el dinero), como la
      // sugerencia por nota del formulario
      final validas = categoriasAll
          .where((c) => c.activo && (c.tipo == tipo || c.tipo == 'AMBOS'))
          .map((c) => c.id)
          .toSet();
      final categoriaId = compra.comercio == null
          ? null
          : sugerirCategoriaPorNota(compra.comercio!, tipo, trans, validas);
      final categoria = categoriasAll.where((c) => c.id == categoriaId).firstOrNull;

      final notas = [
        'Registrado automáticamente',
        if (compra.fuente != null) compra.fuente!,
        if (compra.ultimos4 != null) 'tarjeta *${compra.ultimos4}',
        if (original != null) original,
      ].join(' · ');

      final creada = await TransactionsService(api).createTransaction(
        CreateTransaccionRequest(
          cuentaId: cuenta.id,
          tipoTransaccionId: compra.ingreso ? 1 : 2,
          categoriaId: categoriaId,
          monto: monto,
          moneda: cuenta.moneda,
          titulo: compra.comercio ?? (compra.ingreso ? 'Dinero recibido' : 'Compra con tarjeta'),
          notas: notas,
          fechaTransaccion: cuando,
        ),
      );

      await notif.showCompra(
        id: creada.id,
        titulo: '✓ $tipoLabel de ${_money.format(monto)} · $lugar',
        cuerpo: categoria != null
            ? '${categoria.nombre} · ${cuenta.nombre}. Toca para revisarlo'
            : 'Sin categoría · ${cuenta.nombre}. Toca para elegirla',
        payload: 'financially://${QuickRequest.movimiento}?id=${creada.id}',
      );
      await HomeWidgetSync.update([...trans, creada]);
      await _anotar(fuente, '$titulo · $texto', '$tipoLabel registrado: $montoTxt $lugar');
    } catch (e) {
      debugPrint('Registro automático falló: $e');
      await notif.showCompra(
        id: cuando.millisecondsSinceEpoch ~/ 1000,
        titulo: '$tipoLabel de $montoTxt $lugar sin registrar',
        cuerpo: 'No hubo conexión con Financially. Toca para registrarlo',
        payload: QuickRequest(
          compra.ingreso ? QuickRequest.ingreso : QuickRequest.gasto,
          monto: compra.monto,
          nota: compra.comercio,
        ).encode(),
      );
      await _anotar(fuente, '$titulo · $texto', 'Error: sin conexión');
    }
  }

  /// Cuenta del movimiento, en este orden: la asociada a esa tarjeta (4
  /// dígitos); la asociada a la app que avisó (Nequi → tu cuenta Nequi), o
  /// una cuenta con ese nombre; en compras, la primera tarjeta; y si no, la
  /// última usada para ese tipo o la de más saldo.
  static Future<Cuenta> _cuentaPara(CompraDetectada compra, List<Cuenta> cuentas) async {
    Cuenta? porId(int? id) => cuentas.where((c) => c.id == id).firstOrNull;

    if (compra.ultimos4 != null) {
      final match = porId(await FormPrefs.getInt(FormPrefs.tarjeta(compra.ultimos4!)));
      if (match != null) return match;
    }
    final fuente = compra.fuente;
    if (fuente != null) {
      final match = porId(await FormPrefs.getInt(FormPrefs.fuente(fuente))) ??
          cuentas
              .where((c) => c.nombre.toLowerCase().contains(fuente.toLowerCase()))
              .firstOrNull;
      if (match != null) return match;
    }
    if (!compra.ingreso) {
      final tarjeta = cuentas
          .where((c) => c.tipo == 'TARJETA_CREDITO' || c.tipo == 'TARJETA_DEBITO')
          .firstOrNull;
      if (tarjeta != null) return tarjeta;
    }
    final ultima = porId(
      await FormPrefs.getInt(FormPrefs.lastAccount(compra.ingreso ? 'INGRESO' : 'GASTO')),
    );
    if (ultima != null) return ultima;
    double saldo(Cuenta c) => c.saldoActual ?? c.saldoInicial;
    return (cuentas..sort((a, b) => saldo(b).compareTo(saldo(a)))).first;
  }

  /// Al editar un movimiento automático y cambiarle la cuenta, se recuerda:
  /// para esa tarjeta si traía sus 4 dígitos; si no, para la app que avisó
  /// (Nequi, Daviplata…). Los próximos van a esa cuenta.
  static Future<void> aprenderTarjeta(String? notas, int cuentaId) async {
    final partes = (notas ?? '').split(' · ');
    if (partes.first != 'Registrado automáticamente') return;
    final m = RegExp(r'^tarjeta \*(\d{4})$');
    final tarjeta = partes.map(m.firstMatch).whereType<RegExpMatch>().firstOrNull;
    if (tarjeta != null) {
      await FormPrefs.setInt(FormPrefs.tarjeta(tarjeta.group(1)!), cuentaId);
    } else if (partes.length > 1 && !RegExp(r'^[A-Z]{3} ').hasMatch(partes[1])) {
      // partes[1] es la app ("Nequi"), salvo que sea un monto en otra moneda
      await FormPrefs.setInt(FormPrefs.fuente(partes[1]), cuentaId);
    }
  }
}
