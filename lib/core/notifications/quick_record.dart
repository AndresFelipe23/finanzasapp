
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../../features/accounts/accounts_service.dart';
import '../../features/categories/categories_service.dart';
import '../../features/transactions/category_suggestion.dart';
import '../../features/transactions/transactions_service.dart';
import '../api/api_client.dart';
import '../config/app_config.dart';
import '../home_widget/home_widget_sync.dart';
import '../models/cuenta_models.dart';
import '../models/transaccion_models.dart';
import '../prefs/form_prefs.dart';
import '../quick_launch/quick_launch.dart';
import 'notification_service.dart';

/// Respuesta escrita en la notificación de registro rápido. Android la
/// entrega en un isolate aparte aunque la app esté cerrada, así que aquí se
/// prepara lo mínimo (configuración y notificaciones) antes de registrar.
@pragma('vm:entry-point')
Future<void> quickRecordBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await AppConfig.initialize();
  await NotificationService.instance.init();
  await QuickRecord.handle(response.input ?? '');
}

/// Registra un gasto a partir de un texto como "25000 almuerzo", con la
/// categoría sugerida por la nota y la última cuenta usada en gastos. Cuando
/// falta algo, la notificación queda lista para abrir el formulario lleno.
class QuickRecord {
  QuickRecord._();

  static final _money = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
    locale: 'es_CO',
  );

  // Número (con . o , como separadores) y opcionalmente "k" o "mil"
  static final _montoRe = RegExp(
    r'(\d[\d.,]*)\s*(k|mil)?(?![a-záéíóúñ])',
    caseSensitive: false,
  );

  /// "25000 almuerzo", "almuerzo 25.000", "12,5 café", "25k taxi", "30 mil".
  static ({double monto, String nota})? parse(String text) {
    final m = _montoRe.firstMatch(text);
    if (m == null) return null;
    var n = m.group(1)!.replaceFirst(RegExp(r'[.,]+$'), '');
    if (n.contains(',')) {
      // 25.000,50: el punto separa miles y la coma los decimales
      n = n.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(n)) {
      n = n.replaceAll('.', ''); // 25.000
    }
    var monto = double.tryParse(n);
    if (monto == null || monto <= 0) return null;
    if (m.group(2) != null) monto *= 1000;
    final nota = text
        .replaceRange(m.start, m.end, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return (monto: monto, nota: nota);
  }

  // ── Sin conexión: los textos se guardan y se registran después ──────────
  static const _pendientesKey = 'quickRecordPendientes';
  static const _storage = FlutterSecureStorage();
  static bool _enviando = false;

  static Future<List<Map<String, dynamic>>> _leerPendientes() async {
    try {
      final raw = await _storage.read(key: _pendientesKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _guardarPendiente(String texto, DateTime fecha) async {
    final lista = await _leerPendientes()
      ..add({'texto': texto, 'fecha': fecha.toIso8601String()});
    try {
      await _storage.write(key: _pendientesKey, value: jsonEncode(lista));
    } catch (_) {
      // Si no se puede guardar, el aviso ya le pidió hacerlo en la app
    }
  }

  /// Registra los gastos que quedaron guardados sin conexión, con su fecha y
  /// hora originales. Se llama al abrir la app y tras cada registro rápido
  /// que sale bien; si sigue sin red, vuelven a quedar guardados.
  static Future<void> enviarPendientes() async {
    if (_enviando) return;
    _enviando = true;
    try {
      final lista = await _leerPendientes();
      if (lista.isEmpty) return;
      // Se sacan de la lista antes de enviarlos para no registrarlos dos veces
      await _storage.delete(key: _pendientesKey);
      for (final p in lista) {
        await handle(
          '${p['texto']}',
          fecha: DateTime.tryParse('${p['fecha']}'),
          desdeCola: true,
        );
      }
    } catch (e) {
      debugPrint('Pendientes sin enviar: $e');
    } finally {
      _enviando = false;
    }
  }

  /// [fecha]: la del momento en que se escribió (gastos guardados sin
  /// conexión); sin ella, ahora.
  static Future<void> handle(
    String text, {
    DateTime? fecha,
    bool desdeCola = false,
  }) async {
    final notif = NotificationService.instance;
    final cuando = fecha ?? DateTime.now();
    final parsed = parse(text);
    if (parsed == null) {
      await notif.showQuickRecord(
        estado: 'No encontré el monto en "$text". '
            'Escribe, por ejemplo: 25000 almuerzo',
      );
      return;
    }
    final (:monto, :nota) = parsed;
    final montoTxt = _money.format(monto);
    // Si no se puede registrar solo, tocar la notificación abre el formulario
    final abrirFormulario = QuickRequest(
      QuickRequest.gasto,
      monto: monto,
      nota: nota.isEmpty ? null : nota,
    ).encode();

    final api = ApiClient();
    if (await api.readRefreshToken() == null && !await api.hasToken()) {
      await notif.showQuickRecord(
        estado: 'Inicia sesión en Financially para registrar $montoTxt',
        payload: abrirFormulario,
      );
      return;
    }

    try {
      final hoy = DateTime.now();
      final (cuentasAll, categoriasAll, trans) = await (
        AccountsService(api).getAllAccounts(),
        CategoriesService(api).getAllCategories(),
        TransactionsService(api).getAllTransactions(
          fechaInicio: hoy.subtract(const Duration(days: 90)),
        ),
      ).wait;

      // Cuenta: la última usada en gastos o la de más saldo
      final cuentas = cuentasAll.where((c) => c.activa).toList();
      if (cuentas.isEmpty) {
        await notif.showQuickRecord(
          estado: 'Primero crea una cuenta en la app',
          payload: abrirFormulario,
        );
        return;
      }
      final ultima = await FormPrefs.getInt(FormPrefs.lastAccount('GASTO'));
      double saldo(Cuenta c) => c.saldoActual ?? c.saldoInicial;
      final cuenta = cuentas.where((c) => c.id == ultima).firstOrNull ??
          (cuentas..sort((a, b) => saldo(b).compareTo(saldo(a)))).first;

      // Categoría: solo si la nota la deja clara; si no, se elige en la app
      final validas = categoriasAll
          .where((c) => c.activo && (c.tipo == 'GASTO' || c.tipo == 'AMBOS'))
          .map((c) => c.id)
          .toSet();
      final categoriaId = sugerirCategoriaPorNota(nota, 'GASTO', trans, validas);
      if (categoriaId == null) {
        await notif.showQuickRecord(
          estado: nota.isEmpty
              ? 'Toca aquí para elegir la categoría de $montoTxt'
              : 'Toca aquí para elegir la categoría de $montoTxt ($nota)',
          payload: abrirFormulario,
        );
        return;
      }
      final categoria = categoriasAll.firstWhere((c) => c.id == categoriaId);

      if (cuenta.tipo != 'TARJETA_CREDITO' && monto > saldo(cuenta)) {
        await notif.showQuickRecord(
          estado: 'Saldo insuficiente en ${cuenta.nombre} '
              '(${_money.format(saldo(cuenta))}). Toca para elegir otra cuenta',
          payload: abrirFormulario,
        );
        return;
      }

      final creada = await TransactionsService(api).createTransaction(
        CreateTransaccionRequest(
          cuentaId: cuenta.id,
          tipoTransaccionId: 2,
          categoriaId: categoria.id,
          monto: monto,
          moneda: cuenta.moneda,
          titulo: nota.isEmpty ? null : nota,
          // Fecha y hora del teléfono (la de cuando se escribió, si quedó
          // guardado sin conexión): el servidor la guarda tal cual
          fechaTransaccion: cuando,
        ),
      );
      await notif.showQuickRecord(
        estado: desdeCola
            ? '✓ Registrado al volver la conexión: $montoTxt en ${categoria.nombre}'
            : '✓ Gasto de $montoTxt en ${categoria.nombre} · ${cuenta.nombre}',
      );
      await HomeWidgetSync.update([...trans, creada]);
      // Hay red: registrar lo que haya quedado guardado antes
      if (!desdeCola) await enviarPendientes();
    } catch (e) {
      // Los servicios envuelven el DioException en un Exception con su mensaje
      debugPrint('Registro rápido falló: $e');
      final msg = e.toString().toLowerCase();
      final sinRed = const [
        'connection',
        'socket',
        'network',
        'host lookup',
        'timeout',
        'timed out',
      ].any(msg.contains);
      if (sinRed) {
        // Se guarda y se registra cuando vuelva la conexión
        await _guardarPendiente(text, cuando);
        await notif.showQuickRecord(
          estado: 'Sin conexión: guardé "$text". Se registrará cuando '
              'vuelvas a tener internet y abras la app o registres otro gasto',
        );
      } else {
        await notif.showQuickRecord(
          estado: 'No se pudo registrar $montoTxt. Toca para hacerlo en la app',
          payload: abrirFormulario,
        );
      }
    }
  }
}
