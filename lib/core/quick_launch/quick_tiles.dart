import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mosaicos de Ajustes rápidos ("Nuevo gasto", "Nuevo ingreso"): pedir al
/// sistema que los agregue (MainActivity.kt, Android 13+).
class QuickTiles {
  QuickTiles._();

  static const _channel = MethodChannel('financially/tiles');

  static bool get esAndroid => !kIsWeb && Platform.isAndroid;

  /// true si el sistema puede mostrar el diálogo para agregarlos.
  static Future<bool> puedePedir() async {
    if (!esAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('soportado') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Muestra el diálogo del sistema. Devuelve el texto para avisar al usuario.
  static Future<String> agregar(String tipo) async {
    final nombre = tipo == 'INGRESO' ? 'Nuevo ingreso' : 'Nuevo gasto';
    try {
      final codigo = await _channel.invokeMethod<int>('agregar', {'tipo': tipo});
      // StatusBarManager.TILE_ADD_REQUEST_RESULT_*
      return switch (codigo) {
        2 => '"$nombre" quedó en tus Ajustes rápidos',
        1 => '"$nombre" ya estaba en tus Ajustes rápidos',
        0 => 'No se agregó "$nombre"',
        _ => _manual,
      };
    } catch (_) {
      return _manual;
    }
  }

  static const _manual =
      'Baja el panel de notificaciones, toca el lápiz (Editar) y arrastra '
      '"Nuevo gasto" o "Nuevo ingreso"';

  static String get instruccionesManuales => _manual;
}
