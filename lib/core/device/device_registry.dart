import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

class DeviceRegistry {
  static const _deviceIdKey = 'dispositivoNfcId';
  static const _deviceUuidKey = 'device_uuid';

  static final _storage = const FlutterSecureStorage();

  static Future<int> ensureRegistered(ApiClient api) async {
    // Verificar si el UUID almacenado es válido; si no, regenerar y limpiar id cacheado
    var storedUuid = await _storage.read(key: _deviceUuidKey);
    if (storedUuid == null || _isBadUuid(storedUuid)) {
      storedUuid = _generatePseudoUuid();
      await _storage.write(key: _deviceUuidKey, value: storedUuid);
      await _storage.delete(key: _deviceIdKey);
    }

    final cachedId = await _storage.read(key: _deviceIdKey);
    if (cachedId != null) return int.tryParse(cachedId) ?? 0;

    final unique = storedUuid;
    final nombre = Platform.isAndroid ? 'Mi Teléfono (Android)' : Platform.isIOS ? 'Mi Teléfono (iOS)' : 'Mi Dispositivo';
    final tipo = 'TELEFONO';
    final modelo = await _getModel();

    final res = await api.dio.post('/api/dispositivos-nfc/register', data: {
      'nombre': nombre,
      'tipo_dispositivo': tipo,
      'identificador_unico': unique,
      'modelo': modelo,
    });

    // El backend puede devolver id como String o num (dependiendo de SQL Server)
    final idValue = res.data['id'];
    final id = idValue is String ? int.parse(idValue) : (idValue as num).toInt();

    await _storage.write(key: _deviceIdKey, value: id.toString());
    return id;
  }

  static Future<int?> getCachedDeviceId() async {
    final v = await _storage.read(key: _deviceIdKey);
    return v == null ? null : int.tryParse(v);
  }

  static Future<String> _getUniqueId() async {
    // Deprecated: mantenido por compatibilidad
    final existing = await _storage.read(key: _deviceUuidKey);
    if (existing != null && existing.isNotEmpty && !_isBadUuid(existing)) return existing;
    final uid = _generatePseudoUuid();
    await _storage.write(key: _deviceUuidKey, value: uid);
    return uid;
  }

  static Future<String?> _getModel() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}';
      }
      if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {}
    return null;
  }

  static bool _isBadUuid(String value) {
    // Identificadores no únicos (build id como 'AP3A.240905.015.A2', etc.)
    if (value.contains('.')) return true;
    if (value == 'android-unknown' || value == 'ios-unknown') return true;
    // Si es muy corto, probablemente no sea UUID
    if (value.length < 16) return true;
    return false;
  }

  static String _generatePseudoUuid() {
    // Genera un UUID v4-like simple sin dependencias
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = (now ^ 0x9E3779B97F4A7C15).abs();
    String toHex(int x) => x.toRadixString(16).padLeft(16, '0');
    final a = toHex(now);
    final b = toHex(rnd);
    final raw = (a + b).substring(0, 32).toUpperCase();
    return '${raw.substring(0,8)}-${raw.substring(8,12)}-${raw.substring(12,16)}-${raw.substring(16,20)}-${raw.substring(20,32)}';
  }
}


