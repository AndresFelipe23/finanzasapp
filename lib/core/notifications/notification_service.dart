import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../features/accounts/accounts_service.dart';
import '../../features/prestamos/prestamos_service.dart';
import '../../features/presupuestos/presupuestos_service.dart';
import '../../features/recurring/recurring_service.dart';
import '../api/api_client.dart';
import '../currency/exchange_rates.dart';
import '../models/cuenta_models.dart';
import '../models/pago_recurrente_models.dart';
import '../models/prestamo_models.dart';
import '../models/presupuesto_models.dart';
import '../models/transaccion_models.dart';
import '../quick_launch/quick_launch.dart';
import 'quick_record.dart';
import 'resumen_semanal.dart';

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>(
      (ref) => NotificationsEnabledNotifier(),
    );

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  NotificationsEnabledNotifier() : super(NotificationService.instance.enabled);

  /// Al activar se pide el permiso del sistema; si lo niega queda apagado.
  Future<bool> setEnabled(bool enabled) async {
    final ok = await NotificationService.instance.setEnabled(enabled);
    state = NotificationService.instance.enabled;
    return ok;
  }
}

/// Notificaciones locales: recordatorios de pagos recurrentes y alertas de
/// presupuesto. No necesita servidor de push; se sincroniza al abrir la app.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _enabledKey = 'notificationsEnabled';
  static const _budgetAlertsKey = 'budgetAlertsSent';
  // Rango de ids reservado para recordatorios de pagos recurrentes
  static const _recurringIdBase = 100000;
  static const _recurringIdMax = 199999;
  static const _quickId = 300000;
  static const _tarjetaIdBase = 600000; // recordatorios de pago de tarjeta
  static const _cuotaIdBase = 700000; // recordatorios de cuotas de préstamos
  static const _quickKey = 'quickRecordEnabled';
  static const _resumenKey = 'weeklySummaryEnabled';
  static const _resumenId = 800000;
  static const quickRecordAction = 'registro_rapido_gasto';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  final _money = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
    locale: 'es_CO',
  );

  bool enabled = false;
  bool _ready = false;

  static const _recurringChannel = AndroidNotificationDetails(
    'pagos_recurrentes',
    'Pagos recurrentes',
    channelDescription: 'Recordatorios de pagos que se repiten',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _budgetChannel = AndroidNotificationDetails(
    'presupuestos',
    'Presupuestos',
    channelDescription: 'Avisos cuando te acercas al límite de un presupuesto',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _quickChannel = AndroidNotificationDetails(
    'registro_rapido',
    'Registro rápido',
    channelDescription:
        'Notificación fija para registrar gastos sin abrir la app',
    // Baja: queda en la lista sin sonar ni aparecer encima
    importance: Importance.low,
    priority: Priority.low,
  );

  /// También se llama desde el isolate de segundo plano que atiende la
  /// respuesta de la notificación de registro rápido.
  Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          // Ícono de un color para la barra de estado (la F de la marca)
          android: AndroidInitializationSettings(
            '@drawable/ic_stat_financially',
          ),
          // Los permisos se piden cuando el usuario activa las notificaciones
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onResponse,
        onDidReceiveBackgroundNotificationResponse: quickRecordBackground,
      );
      enabled = await _storage.read(key: _enabledKey) == 'true';
      quickRecordEnabled = await _storage.read(key: _quickKey) == 'true';
      // El resumen semanal viene encendido; solo se apaga si el usuario lo apaga
      resumenSemanalEnabled = await _storage.read(key: _resumenKey) != 'false';
      _ready = true;

      // La app se abrió tocando una notificación
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
        _onResponse(response);
      }
    } catch (e) {
      debugPrint('No se pudieron iniciar las notificaciones: $e');
    }
  }

  /// Toque en una notificación o en un botón que abre la app: el id del
  /// botón o el payload dicen qué pantalla abrir (`financially://...`).
  void _onResponse(NotificationResponse r) {
    if (r.actionId == quickRecordAction) {
      // Normalmente llega al isolate de segundo plano; por si acaso
      QuickRecord.handle(r.input ?? '');
      return;
    }
    final action = r.actionId;
    QuickLaunch.request(
      action != null && action.startsWith('financially://')
          ? action
          : r.payload,
    );
  }

  Future<bool> setEnabled(bool value) async {
    if (!_ready) return false;
    if (value && !await _requestPermission()) {
      return false;
    }
    enabled = value;
    if (!value) {
      await _plugin.cancelAll();
      // El registro rápido tiene su propio interruptor
      await showQuickRecord();
    }
    try {
      await _storage.write(key: _enabledKey, value: '$value');
    } catch (_) {
      // El cambio ya se aplicó en memoria aunque no persista
    }
    if (value) await syncFromServer(ApiClient());
    return true;
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  /// Descarga presupuestos y pagos recurrentes para programar avisos. Se
  /// llama al entrar a la app; los errores se ignoran para no molestar.
  Future<void> syncFromServer(ApiClient api) async {
    if (!_ready || !enabled) return;
    try {
      await scheduleRecurringReminders(await RecurringService(api).getAll());
    } catch (e) {
      debugPrint('Recordatorios no sincronizados: $e');
    }
    await revisarPresupuestos(api);
    try {
      await programarPagosTarjeta(await AccountsService(api).getAllAccounts());
    } catch (e) {
      debugPrint('Recordatorios de tarjeta no programados: $e');
    }
    try {
      await programarCuotasPrestamos(await PrestamosService(api).getAll());
    } catch (e) {
      debugPrint('Recordatorios de cuotas no programados: $e');
    }
  }

  /// Préstamos en cuotas activos: aviso a las 9:00 tres días antes de la
  /// próxima cuota y el día que vence. En los que te deben, el aviso es para
  /// cobrar. Se reprograman cada vez que se cargan los préstamos.
  Future<void> programarCuotasPrestamos(List<Prestamo> prestamos) async {
    if (!_ready || !enabled) return;
    final pendientes = await _plugin.pendingNotificationRequests();
    for (final p in pendientes) {
      if (p.id >= _cuotaIdBase && p.id < _cuotaIdBase + 100000) {
        await _plugin.cancel(id: p.id);
      }
    }

    final ahora = DateTime.now();
    for (final p in prestamos.where(
      (p) => p.activa && !p.estaPagado && p.enCuotas,
    )) {
      final vence = p.proximoVencimiento;
      if (vence == null) continue;
      final debo = p.tipo == 'DEUDA';
      final cuota = 'Cuota ${p.proximaCuota} de ${p.numeroCuotas}';
      final monto = _money.format(p.cuotaTotal);
      final avisos = [
        (
          vence.subtract(const Duration(days: 3)),
          0,
          debo
              ? '$cuota de ${p.nombre} en 3 días'
              : '${p.nombre} te paga en 3 días',
        ),
        (
          vence,
          1,
          debo
              ? 'Hoy vence la cuota de ${p.nombre}'
              : 'Hoy ${p.nombre} te debe pagar',
        ),
      ];
      for (final (dia, n, titulo) in avisos) {
        final cuando = DateTime(dia.year, dia.month, dia.day, 9);
        if (!cuando.isAfter(ahora)) continue;
        await _plugin.zonedSchedule(
          id: _cuotaIdBase + (p.id * 2 + n) % 100000,
          scheduledDate: tz.TZDateTime.from(cuando, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: _recurringChannel,
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: titulo,
          body:
              '$cuota: $monto. Toca para ${debo ? 'pagarla' : 'registrar el cobro'}.',
          payload: 'financially://${QuickRequest.prestamos}',
        );
      }
    }
  }

  /// Tarjetas de crédito con día de pago y deuda: aviso a las 9:00 tres días
  /// antes y el mismo día. Se reprograman al abrir la app y al pagar.
  Future<void> programarPagosTarjeta(List<Cuenta> cuentas) async {
    if (!_ready || !enabled) return;
    final pendientes = await _plugin.pendingNotificationRequests();
    for (final p in pendientes) {
      if (p.id >= _tarjetaIdBase && p.id < _tarjetaIdBase + 100000) {
        await _plugin.cancel(id: p.id);
      }
    }

    final ahora = DateTime.now();
    for (final c in cuentas.where(
      (c) => c.activa && c.esTarjetaCredito && c.deuda > 0,
    )) {
      final pago = c.proximoPago(ahora);
      if (pago == null) continue;
      final avisos = [
        (
          pago.subtract(const Duration(days: 3)),
          0,
          'Tu tarjeta ${c.nombre} se paga en 3 días',
        ),
        (pago, 1, 'Hoy se paga tu tarjeta ${c.nombre}'),
      ];
      for (final (dia, n, titulo) in avisos) {
        final cuando = DateTime(dia.year, dia.month, dia.day, 9);
        if (!cuando.isAfter(ahora)) continue;
        await _plugin.zonedSchedule(
          id: _tarjetaIdBase + (c.id * 2 + n) % 100000,
          scheduledDate: tz.TZDateTime.from(cuando, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: _recurringChannel,
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: titulo,
          body: 'Deuda de ${_money.format(c.deuda)}. Toca para pagarla.',
          payload: 'financially://${QuickRequest.cuenta}?id=${c.id}',
        );
      }
    }
  }

  /// Revisa los presupuestos justo después de registrar un gasto (en la app,
  /// desde la notificación o automáticamente) para avisar al momento si pasó
  /// del 80% o del 100%. [causa] ("tu compra de $85.000 en Éxito") se
  /// menciona en los presupuestos que ese gasto afecta ([categoriaId] y
  /// [cuentaId] del gasto).
  Future<void> revisarPresupuestos(
    ApiClient api, {
    String? causa,
    int? categoriaId,
    int? cuentaId,
  }) async {
    if (!_ready || !enabled) return;
    try {
      await checkBudgets(
        await PresupuestosService(api).getAll(activos: true),
        causa: causa,
        categoriaId: categoriaId,
        cuentaId: cuentaId,
      );
    } catch (e) {
      debugPrint('Alertas de presupuesto no revisadas: $e');
    }
  }

  /// Programa un aviso a las 9:00 del día del próximo cobro de cada pago
  /// activo. Se reemplazan todos los recordatorios anteriores.
  Future<void> scheduleRecurringReminders(List<PagoRecurrente> items) async {
    if (!_ready || !enabled) return;

    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _recurringIdBase && p.id <= _recurringIdMax) {
        await _plugin.cancel(id: p.id);
      }
    }

    final now = DateTime.now();
    for (final p in items.where((p) => p.activo)) {
      var fecha = p.proximaFecha(now);
      if (fecha == null) continue;
      var aviso = DateTime(fecha.year, fecha.month, fecha.day, 9);
      if (!aviso.isAfter(now)) {
        // El aviso de hoy ya pasó: programar el siguiente cobro
        fecha = p.proximaFecha(fecha.add(const Duration(days: 1)));
        if (fecha == null) continue;
        aviso = DateTime(fecha.year, fecha.month, fecha.day, 9);
      }

      final nombre = p.descripcion.isEmpty
          ? (p.categoriaNombre ?? 'Pago recurrente')
          : p.descripcion;
      await _plugin.zonedSchedule(
        id: _recurringIdBase + p.id % (_recurringIdMax - _recurringIdBase),
        // TZDateTime.from conserva el instante exacto aunque tz.local sea UTC
        scheduledDate: tz.TZDateTime.from(aviso, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: _recurringChannel,
          iOS: DarwinNotificationDetails(),
        ),
        // Inexacto: no requiere el permiso de alarmas exactas de Android 12+
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Hoy se registra: $nombre',
        body:
            '${_money.format(p.monto)} · ${p.frecuenciaLabel}'
            '${p.cuentaNombre != null ? ' · ${p.cuentaNombre}' : ''}',
        payload: 'financially://${QuickRequest.recurrentes}',
      );
    }
  }

  /// Avisa una sola vez por presupuesto y periodo al pasar el 80% y el 100%.
  Future<void> checkBudgets(
    List<Presupuesto> items, {
    String? causa,
    int? categoriaId,
    int? cuentaId,
  }) async {
    if (!_ready || !enabled) return;

    final sent = (await _storage.read(key: _budgetAlertsKey) ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toSet();
    final keep = <String>{};

    for (final b in items.where((b) => b.activo && b.montoLimite > 0)) {
      final umbral = b.porcentaje >= 100
          ? 100
          : b.porcentaje >= 80
          ? 80
          : 0;
      if (umbral == 0) continue;

      // La clave incluye el inicio del periodo para volver a avisar en el
      // siguiente mes / semana
      final periodo = DateFormat('yyyyMMdd').format(b.fechaInicio);
      final key = '${b.id}-$periodo-$umbral';
      keep.add(key);
      if (umbral == 100) keep.add('${b.id}-$periodo-80');
      if (sent.contains(key)) continue;

      final restante = b.montoLimite - b.montoGastado;
      // "Con tu compra de $85.000 en Éxito, …" solo si ese gasto cuenta aquí
      final afecta =
          causa != null &&
          (b.categoriaId == null || b.categoriaId == categoriaId) &&
          (b.cuentaId == null || b.cuentaId == cuentaId);
      final detalle = umbral == 100
          ? 'te pasaste por ${_money.format(-restante)} '
                'de ${_money.format(b.montoLimite)}.'
          : 'te quedan ${_money.format(restante)} '
                'de ${_money.format(b.montoLimite)}.';
      final cuerpo = afecta
          ? 'Con $causa, $detalle'
          : detalle[0].toUpperCase() + detalle.substring(1);
      await _plugin.show(
        id: 200000 + b.id % 100000,
        title: umbral == 100
            ? 'Superaste el presupuesto "${b.nombre}"'
            : 'Vas en el ${b.porcentaje.round()}% de "${b.nombre}"',
        body: cuerpo,
        notificationDetails: const NotificationDetails(
          android: _budgetChannel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'financially://${QuickRequest.presupuestos}',
      );
    }

    try {
      await _storage.write(key: _budgetAlertsKey, value: keep.join(','));
    } catch (_) {
      // Si no persiste, en el peor caso se repite un aviso
    }
  }

  // ── Registro rápido (solo Android) ──────────────────────────────────────

  bool quickRecordEnabled = false;

  /// Resumen de la semana, los domingos a las 8:00 p. m.
  bool resumenSemanalEnabled = true;

  bool get quickRecordSupported => !kIsWeb && Platform.isAndroid;

  Future<bool> setQuickRecord(bool value) async {
    if (!_ready || !quickRecordSupported) return false;
    if (value && !await _requestPermission()) return false;
    quickRecordEnabled = value;
    try {
      await _storage.write(key: _quickKey, value: '$value');
    } catch (_) {
      // El cambio ya se aplicó en memoria aunque no persista
    }
    value ? await showQuickRecord() : await hideQuickRecord();
    return true;
  }

  /// Muestra (o actualiza) la notificación fija. [estado] reemplaza el texto
  /// de ayuda con el resultado del último registro; [payload] es lo que se
  /// abre al tocarla (por defecto, un gasto nuevo).
  Future<void> showQuickRecord({String? estado, String? payload}) async {
    if (!_ready || !quickRecordSupported || !quickRecordEnabled) return;
    final texto =
        estado ?? 'Toca "Gasto" y escribe, por ejemplo: 25000 almuerzo';
    try {
      await _plugin.show(
        id: _quickId,
        title: 'Registro rápido',
        body: texto,
        payload: payload ?? 'financially://${QuickRequest.gasto}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _quickChannel.channelId,
            _quickChannel.channelName,
            channelDescription: _quickChannel.channelDescription,
            importance: _quickChannel.importance,
            priority: _quickChannel.priority,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: estado != null,
            styleInformation: BigTextStyleInformation(texto),
            actions: const [
              AndroidNotificationAction(
                quickRecordAction,
                'Gasto',
                inputs: [
                  AndroidNotificationActionInput(
                    label: 'Monto y nota: 25000 almuerzo',
                  ),
                ],
                // Se registra sin abrir la app; la notificación se queda
                cancelNotification: false,
              ),
              AndroidNotificationAction(
                'financially://${QuickRequest.ingreso}',
                'Ingreso',
                showsUserInterface: true,
                cancelNotification: false,
              ),
              AndroidNotificationAction(
                'financially://${QuickRequest.transferencia}',
                'Transferir',
                showsUserInterface: true,
                cancelNotification: false,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Registro rápido no mostrado: $e');
    }
  }

  /// Resultado de una compra registrada automáticamente (o que no se pudo).
  /// Se muestra aunque los recordatorios estén apagados: es parte de una
  /// función que el usuario activó aparte.
  Future<void> showCompra({
    required int id,
    required String titulo,
    required String cuerpo,
    required String payload,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 500000 + id % 100000,
        title: titulo,
        body: cuerpo,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'compras_automaticas',
            'Compras registradas',
            channelDescription:
                'Compras con tarjeta o el teléfono que se registran solas',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(cuerpo),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Aviso de compra no mostrado: $e');
    }
  }

  // ── Resumen semanal ─────────────────────────────────────────────────────

  AndroidNotificationDetails _resumenAndroid(String cuerpo) =>
      AndroidNotificationDetails(
        'resumen_semanal',
        'Resumen semanal',
        channelDescription: 'Tu semana en números, los domingos por la noche',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(cuerpo),
      );

  /// Programa el resumen del próximo domingo a las 8:00 p. m. Una notificación
  /// local no puede calcular su texto cuando suena, así que el contenido es el
  /// de ahora y se vuelve a programar cada vez que cambian los movimientos
  /// (en la app, en el registro rápido y en el registro automático). Si no
  /// hubo movimientos en 14 días no se programa nada: no hay nada que contar.
  ///
  /// [presupuestos]: los ya cargados; si es null y hay [api], se consultan.
  Future<void> programarResumenSemanal({
    required List<Transaccion> trans,
    List<Presupuesto>? presupuestos,
    ApiClient? api,
  }) async {
    if (!_ready) return;
    try {
      final ahora = DateTime.now();
      final hayActividad = trans.any(
        (t) => t.fechaTransaccion.isAfter(
          ahora.subtract(const Duration(days: 14)),
        ),
      );
      if (!enabled || !resumenSemanalEnabled || !hayActividad) {
        await _plugin.cancel(id: _resumenId);
        return;
      }
      if (presupuestos == null && api != null) {
        try {
          presupuestos = await PresupuestosService(api).getAll(activos: true);
        } catch (_) {
          // Sin presupuestos el resumen sale igual, solo sin esa línea
        }
      }
      final resumen = ResumenSemanal.calcular(
        trans,
        presupuestos ?? const [],
        ahora,
        tasas: await ExchangeRates.enCache(),
      );
      await _plugin.zonedSchedule(
        id: _resumenId,
        // TZDateTime.from conserva el instante exacto aunque tz.local sea UTC
        scheduledDate: tz.TZDateTime.from(
          ResumenSemanal.proximoDomingo(ahora),
          tz.UTC,
        ),
        notificationDetails: NotificationDetails(
          android: _resumenAndroid(resumen.cuerpo),
          iOS: const DarwinNotificationDetails(),
        ),
        // Inexacto: no requiere el permiso de alarmas exactas de Android 12+
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: resumen.titulo,
        body: resumen.cuerpo,
        payload: 'financially://${QuickRequest.movimientos}',
      );
    } catch (e) {
      debugPrint('Resumen semanal no programado: $e');
    }
  }

  /// Muestra ahora cómo se verá el resumen (con lo que va de la semana).
  Future<void> vistaPreviaResumen({
    required List<Transaccion> trans,
    List<Presupuesto>? presupuestos,
  }) async {
    if (!_ready) return;
    final resumen = ResumenSemanal.calcular(
      trans,
      presupuestos ?? const [],
      DateTime.now(),
      tasas: await ExchangeRates.enCache(),
    );
    final cuerpo = resumen.sinActividad
        ? 'Aún no hay movimientos esta semana. Cuando los registres, aquí verás '
              'cuánto gastaste, en qué y cómo vas con tus presupuestos.'
        : resumen.cuerpo;
    await _plugin.show(
      id: _resumenId + 1,
      title: 'Así se verá tu resumen · ${resumen.titulo}',
      body: cuerpo,
      payload: 'financially://${QuickRequest.movimientos}',
      notificationDetails: NotificationDetails(
        android: _resumenAndroid(cuerpo),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Activa o apaga el resumen. Al activarlo hacen falta las notificaciones:
  /// se pide el permiso si todavía no estaban activas.
  Future<bool> setResumenSemanal(bool value) async {
    if (!_ready) return false;
    if (value && !enabled && !await setEnabled(true)) return false;
    resumenSemanalEnabled = value;
    try {
      await _storage.write(key: _resumenKey, value: '$value');
    } catch (_) {
      // El cambio ya se aplicó en memoria aunque no persista
    }
    if (!value) await _plugin.cancel(id: _resumenId);
    return true;
  }

  Future<void> hideQuickRecord() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _quickId);
    } catch (_) {
      // Ya no estaba visible
    }
  }
}

final quickRecordEnabledProvider =
    StateNotifierProvider<QuickRecordEnabledNotifier, bool>(
      (ref) => QuickRecordEnabledNotifier(),
    );

class QuickRecordEnabledNotifier extends StateNotifier<bool> {
  QuickRecordEnabledNotifier()
    : super(NotificationService.instance.quickRecordEnabled);

  /// Al activar se pide el permiso del sistema; si lo niega queda apagado.
  Future<bool> setEnabled(bool enabled) async {
    final ok = await NotificationService.instance.setQuickRecord(enabled);
    state = NotificationService.instance.quickRecordEnabled;
    return ok;
  }
}

final resumenSemanalEnabledProvider =
    StateNotifierProvider<ResumenSemanalEnabledNotifier, bool>(
      (ref) => ResumenSemanalEnabledNotifier(),
    );

class ResumenSemanalEnabledNotifier extends StateNotifier<bool> {
  ResumenSemanalEnabledNotifier()
    : super(
        NotificationService.instance.enabled &&
            NotificationService.instance.resumenSemanalEnabled,
      );

  /// Al activar se pide el permiso del sistema si hace falta; si lo niega
  /// queda apagado.
  Future<bool> setEnabled(bool enabled) async {
    final ok = await NotificationService.instance.setResumenSemanal(enabled);
    state =
        NotificationService.instance.enabled &&
        NotificationService.instance.resumenSemanalEnabled;
    return ok;
  }
}
