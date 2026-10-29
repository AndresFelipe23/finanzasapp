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
      await _anotar(fuente, '$titulo · $texto', 'No parece una compra');
      return;
    }

    final notif = NotificationService.instance;
    final montoTxt = _money.format(compra.monto);
    final lugar = compra.comercio ?? compra.fuente ?? 'compra con tarjeta';
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

      // ¿Ya está? (registrada a mano, o avisada por dos apps)
      final yaEsta = trans.any((t) =>
          t.tipoNombre == 'GASTO' &&
          (t.monto - compra.monto).abs() < 0.01 &&
          t.fechaTransaccion.difference(cuando).inMinutes.abs() <= 10);
      if (yaEsta) {
        await _anotar(fuente, '$titulo · $texto', 'Ya estaba registrada');
        return;
      }

      final cuentas = cuentasAll.where((c) => c.activa).toList();
      if (cuentas.isEmpty) {
        await _anotar(fuente, '$titulo · $texto', 'No tienes cuentas');
        return;
      }
      final cuenta = await _cuentaPara(compra, cuentas);

      // Compra en otra moneda (p. ej. US$ en Netflix): se convierte a la de
      // la cuenta y el valor original queda en las notas
      var monto = compra.monto;
      String? original;
      if (compra.moneda != null && compra.moneda != cuenta.moneda) {
        final tasas = await ExchangeRates.obtener(cuenta.moneda);
        if (tasas.puede(compra.moneda!)) {
          monto = tasas.aBase(compra.monto, compra.moneda!);
          original = '${compra.moneda} ${compra.monto.toStringAsFixed(2)}';
        }
      }

      // Categoría por el comercio, como la sugerencia por nota del formulario
      final validas = categoriasAll
          .where((c) => c.activo && (c.tipo == 'GASTO' || c.tipo == 'AMBOS'))
          .map((c) => c.id)
          .toSet();
      final categoriaId = compra.comercio == null
          ? null
          : sugerirCategoriaPorNota(compra.comercio!, 'GASTO', trans, validas);
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
          tipoTransaccionId: 2,
          categoriaId: categoriaId,
          monto: monto,
          moneda: cuenta.moneda,
          titulo: compra.comercio ?? 'Compra con tarjeta',
          notas: notas,
          fechaTransaccion: cuando,
        ),
      );

      await notif.showCompra(
        id: creada.id,
        titulo: '✓ Gasto de ${_money.format(monto)} · $lugar',
        cuerpo: categoria != null
            ? '${categoria.nombre} · ${cuenta.nombre}. Toca para revisarlo'
            : 'Sin categoría · ${cuenta.nombre}. Toca para elegirla',
        payload: 'financially://${QuickRequest.movimiento}?id=${creada.id}',
      );
      await HomeWidgetSync.update([...trans, creada]);
      await _anotar(fuente, '$titulo · $texto', 'Registrada: $montoTxt en $lugar');
    } catch (e) {
      debugPrint('Compra automática no registrada: $e');
      await notif.showCompra(
        id: cuando.millisecondsSinceEpoch ~/ 1000,
        titulo: 'Compra de $montoTxt en $lugar sin registrar',
        cuerpo: 'No hubo conexión con Financially. Toca para registrarla',
        payload: QuickRequest(
          QuickRequest.gasto,
          monto: compra.monto,
          nota: compra.comercio,
        ).encode(),
      );
      await _anotar(fuente, '$titulo · $texto', 'Error: sin conexión');
    }
  }

  /// La tarjeta que el usuario ya asoció a esos 4 dígitos; si no, la primera
  /// tarjeta; si no, la última cuenta usada en gastos o la de más saldo.
  static Future<Cuenta> _cuentaPara(CompraDetectada compra, List<Cuenta> cuentas) async {
    if (compra.ultimos4 != null) {
      final id = await FormPrefs.getInt(FormPrefs.tarjeta(compra.ultimos4!));
      final match = cuentas.where((c) => c.id == id).firstOrNull;
      if (match != null) return match;
    }
    final tarjeta = cuentas
        .where((c) => c.tipo == 'TARJETA_CREDITO' || c.tipo == 'TARJETA_DEBITO')
        .firstOrNull;
    if (tarjeta != null) return tarjeta;
    final ultima = await FormPrefs.getInt(FormPrefs.lastAccount('GASTO'));
    double saldo(Cuenta c) => c.saldoActual ?? c.saldoInicial;
    return cuentas.where((c) => c.id == ultima).firstOrNull ??
        (cuentas..sort((a, b) => saldo(b).compareTo(saldo(a)))).first;
  }

  /// Al editar un movimiento automático y cambiarle la cuenta, se recuerda
  /// para esa tarjeta: las próximas compras con ella van a esa cuenta.
  static Future<void> aprenderTarjeta(String? notas, int cuentaId) async {
    final m = RegExp(r'tarjeta \*(\d{4})').firstMatch(notas ?? '');
    if (m != null) await FormPrefs.setInt(FormPrefs.tarjeta(m.group(1)!), cuentaId);
  }
}
