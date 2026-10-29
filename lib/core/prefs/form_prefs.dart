import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Recuerda elecciones de los formularios para proponerlas la próxima vez
/// (cuenta usada en gastos, en ingresos, par de cuentas de transferencia).
class FormPrefs {
  FormPrefs._();

  static const _storage = FlutterSecureStorage();

  static Future<int?> getInt(String key) async {
    try {
      final v = await _storage.read(key: 'form_$key');
      return v == null ? null : int.tryParse(v);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setInt(String key, int? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: 'form_$key');
      } else {
        await _storage.write(key: 'form_$key', value: '$value');
      }
    } catch (_) {
      // Si no persiste, la próxima vez simplemente no hay sugerencia
    }
  }

  // Claves usadas por los formularios
  static String lastAccount(String tipo) => 'lastAccount_$tipo';
  static const transferFrom = 'transferFrom';
  static const transferTo = 'transferTo';

  /// Cuenta asociada a una tarjeta por sus 4 últimos dígitos (compras
  /// registradas automáticamente).
  static String tarjeta(String ultimos4) => 'tarjeta_$ultimos4';

  /// Cuenta asociada a la app que avisó un movimiento automático ("Nequi").
  static String fuente(String nombre) =>
      'fuente_${nombre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
}
