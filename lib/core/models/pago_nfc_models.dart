class PagoNfc {
  final int id;
  final int usuarioId;
  final int tarjetaNfcId;
  final int transaccionId;
  final int dispositivoNfcId;
  final String? ubicacion;
  final double? latitud;
  final double? longitud;
  final DateTime fechaPago;
  final double monto;
  final String moneda;

  PagoNfc({
    required this.id,
    required this.usuarioId,
    required this.tarjetaNfcId,
    required this.transaccionId,
    required this.dispositivoNfcId,
    required this.ubicacion,
    required this.latitud,
    required this.longitud,
    required this.fechaPago,
    required this.monto,
    required this.moneda,
  });

  factory PagoNfc.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse('$v') ?? 0);
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }
    DateTime toDate(dynamic v) {
      try {
        return DateTime.parse('$v');
      } catch (_) {
        return DateTime.now();
      }
    }

    return PagoNfc(
      id: toInt(json['id'] ?? json['pago_nfc_id'] ?? json['pagoId']),
      usuarioId: toInt(json['usuario_id'] ?? json['usuarioId']),
      tarjetaNfcId: toInt(json['tarjeta_nfc_id'] ?? json['tarjetaNfcId']),
      transaccionId: toInt(json['transaccion_id'] ?? json['transaccionId']),
      dispositivoNfcId: toInt(json['dispositivo_nfc_id'] ?? json['dispositivoNfcId']),
      ubicacion: json['ubicacion']?.toString(),
      latitud: toDouble(json['latitud']),
      longitud: toDouble(json['longitud']),
      fechaPago: toDate(json['fecha_pago'] ?? json['fechaPago'] ?? json['fecha_transaccion']),
      monto: (toDouble(json['monto']) ?? 0),
      moneda: json['moneda']?.toString() ?? 'COP',
    );
  }
}


