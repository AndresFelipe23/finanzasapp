import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../session/current_user.dart';

/// Tasas de cambio para sumar cuentas y movimientos de monedas distintas en
/// la moneda predeterminada del usuario (antes se sumaban sin convertir).
class Tasas {
  const Tasas(this.base, this.porUnidadBase, this.fecha);

  /// Moneda en la que se expresan los totales (la predeterminada).
  final String base;

  /// Cuántas unidades de cada moneda vale 1 [base] ({'USD': 0.00025, …}).
  final Map<String, double> porUnidadBase;
  final DateTime fecha;

  static Tasas sinDatos(String base) => Tasas(base, const {}, DateTime(2000));

  /// [monto] en [moneda] expresado en la moneda base. Sin tasa para esa
  /// moneda se deja igual (y [puede] lo avisa).
  double aBase(double monto, String moneda) {
    if (moneda == base) return monto;
    final tasa = porUnidadBase[moneda];
    return tasa == null || tasa == 0 ? monto : monto / tasa;
  }

  bool puede(String moneda) => moneda == base || porUnidadBase.containsKey(moneda);

  Map<String, dynamic> toJson() => {
    'base': base,
    'tasas': porUnidadBase,
    'fecha': fecha.toIso8601String(),
  };

  static Tasas? fromJson(Map<String, dynamic> j) {
    final base = j['base'];
    final tasas = j['tasas'];
    if (base is! String || tasas is! Map) return null;
    return Tasas(
      base,
      tasas.map((k, v) => MapEntry('$k', (v as num).toDouble())),
      DateTime.tryParse('${j['fecha']}') ?? DateTime(2000),
    );
  }
}

class ExchangeRates {
  ExchangeRates._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'tasasCambio';
  static const _vigencia = Duration(hours: 12);

    /// Últimas tasas guardadas (sin red), para el widget y el modo sin conexión.
  static Future<Tasas?> enCache() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null ? null : Tasas.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Tasas para [base]: las guardadas si tienen menos de 12 h; si no, se
  /// descargan (API pública sin clave; solo se envía el código de moneda).
  /// Sin red se usan las últimas guardadas, aunque sean viejas.
  static Future<Tasas> obtener(String base) async {
    final cache = await enCache();
    if (cache != null &&
        cache.base == base &&
        DateTime.now().difference(cache.fecha) < _vigencia) {
      return cache;
    }
    try {
      final res = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      )).get('https://open.er-api.com/v6/latest/$base');
      final data = res.data as Map;
      if (data['result'] != 'success') throw Exception('${data['error-type']}');
      final tasas = Tasas(
        base,
        (data['rates'] as Map).map((k, v) => MapEntry('$k', (v as num).toDouble())),
        DateTime.now(),
      );
      await _storage.write(key: _key, value: jsonEncode(tasas.toJson()));
      return tasas;
    } catch (e) {
      debugPrint('Tasas de cambio no actualizadas: $e');
      return cache != null && cache.base == base ? cache : Tasas.sinDatos(base);
    }
  }
}

/// Moneda en la que se muestran los totales (la predeterminada del perfil).
final monedaBaseProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider)?.monedaPredeterminada ?? 'COP',
);

/// Tasas para la moneda base. Las pantallas lo leen solo cuando hay montos en
/// otra moneda, así que sin cuentas extranjeras nunca se descarga nada.
final tasasProvider = FutureProvider<Tasas>((ref) {
  return ExchangeRates.obtener(ref.watch(monedaBaseProvider));
});

/// Tasas para convertir [monedas] a la moneda base; si todas son la base no
/// pide nada (y mientras cargan, los montos quedan sin convertir).
Tasas tasasPara(WidgetRef ref, Iterable<String> monedas) {
  final base = ref.watch(monedaBaseProvider);
  if (monedas.every((m) => m == base)) return Tasas.sinDatos(base);
  return ref.watch(tasasProvider).valueOrNull ?? Tasas.sinDatos(base);
}
