import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

/// Pantalla que se pide abrir desde fuera de la app (acceso directo del
/// ícono, widget o notificación), con datos opcionales para el formulario.
///
/// Se codifica como `financially://gasto?monto=25000&nota=almuerzo`.
class QuickRequest {
  const QuickRequest(this.destino, {this.monto, this.nota, this.id});

  static const gasto = 'gasto';
  static const ingreso = 'ingreso';
  static const transferencia = 'transferencia';
  static const recurrentes = 'recurrentes';
  static const presupuestos = 'presupuestos';
  static const movimiento = 'movimiento'; // detalle de un movimiento (id)
  static const _destinos = {
    gasto,
    ingreso,
    transferencia,
    recurrentes,
    presupuestos,
    movimiento,
  };

  final String destino;
  final double? monto;
  final String? nota;
  final int? id;

  static QuickRequest? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final destino = uri.host.isNotEmpty ? uri.host : uri.path;
    if (!_destinos.contains(destino)) return null;
    final nota = uri.queryParameters['nota'];
    return QuickRequest(
      destino,
      monto: double.tryParse(uri.queryParameters['monto'] ?? ''),
      nota: nota == null || nota.isEmpty ? null : nota,
      id: int.tryParse(uri.queryParameters['id'] ?? ''),
    );
  }

  String encode() => Uri(
    scheme: 'financially',
    host: destino,
    queryParameters: {
      if (monto != null) 'monto': '$monto',
      if (nota != null) 'nota': nota!,
      if (id != null) 'id': '$id',
    },
  ).toString().replaceFirst(RegExp(r'\?$'), '');
}

/// Reúne los pedidos de abrir una pantalla. Si llegan antes de iniciar sesión
/// quedan pendientes hasta que la navegación principal los atiende.
class QuickLaunch {
  QuickLaunch._();

  static final pending = ValueNotifier<QuickRequest?>(null);

  static void request(String? raw) {
    final r = QuickRequest.parse(raw);
    if (r != null) pending.value = r;
  }

  /// Entrega el pedido pendiente (y lo descarta) o null.
  static QuickRequest? take() {
    final r = pending.value;
    pending.value = null;
    return r;
  }

  static Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    // Accesos directos al mantener presionado el ícono de la app
    try {
      const actions = QuickActions();
      await actions.initialize(request);
      await actions.setShortcutItems(const [
        ShortcutItem(
          type: 'financially://gasto',
          localizedTitle: 'Nuevo gasto',
          icon: 'ic_shortcut_gasto',
        ),
        ShortcutItem(
          type: 'financially://ingreso',
          localizedTitle: 'Nuevo ingreso',
          icon: 'ic_shortcut_ingreso',
        ),
        ShortcutItem(
          type: 'financially://transferencia',
          localizedTitle: 'Transferir',
          icon: 'ic_shortcut_transfer',
        ),
      ]);
    } catch (e) {
      debugPrint('Accesos directos no disponibles: $e');
    }

    // Botones del widget de la pantalla de inicio (solo Android por ahora)
    if (Platform.isAndroid) {
      try {
        HomeWidget.widgetClicked.listen((uri) => request(uri?.toString()));
        request((await HomeWidget.initiallyLaunchedFromHomeWidget())?.toString());
      } catch (e) {
        debugPrint('Widget no disponible: $e');
      }
    }
  }
}
