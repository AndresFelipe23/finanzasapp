class TarjetaNfc {
  final int id;
  final int usuarioId;
  final int? cuentaId;
  final String nombrePortador;
  final String numeroTarjetaHash;
  final String tipo; // DEBITO | CREDITO
  final String? banco;
  final String? color;
  final bool activa;
  final DateTime fechaCreacion;

  TarjetaNfc({
    required this.id,
    required this.usuarioId,
    required this.cuentaId,
    required this.nombrePortador,
    required this.numeroTarjetaHash,
    required this.tipo,
    required this.banco,
    required this.color,
    required this.activa,
    required this.fechaCreacion,
  });

  factory TarjetaNfc.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v == null ? 0 : (v is int ? v : int.tryParse('$v') ?? 0);
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = '${v ?? ''}'.toLowerCase();
      return s == 'true' || s == '1';
    }
    DateTime toDate(dynamic v) {
      try {
        return DateTime.parse('$v');
      } catch (_) {
        return DateTime.now();
      }
    }

    return TarjetaNfc(
      id: toInt(json['id']),
      usuarioId: toInt(json['usuario_id'] ?? json['usuarioId']),
      cuentaId: json['cuenta_id'] != null ? toInt(json['cuenta_id']) : (json['cuentaId'] != null ? toInt(json['cuentaId']) : null),
      nombrePortador: json['nombre_portador']?.toString() ?? json['nombrePortador']?.toString() ?? '',
      numeroTarjetaHash: json['numero_tarjeta_hash']?.toString() ?? json['numeroTarjetaHash']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      banco: json['banco']?.toString(),
      color: json['color']?.toString(),
      activa: toBool(json['activa']),
      fechaCreacion: toDate(json['fecha_creacion'] ?? json['fechaCreacion']),
    );
  }
}

class CreateTarjetaNfcRequest {
  final int? cuentaId;
  final String nombrePortador;
  final String numeroTarjetaHash;
  final String tipo; // DEBITO | CREDITO
  final String? banco;
  final String? color;

  CreateTarjetaNfcRequest({
    this.cuentaId,
    required this.nombrePortador,
    required this.numeroTarjetaHash,
    required this.tipo,
    this.banco,
    this.color,
  });

  Map<String, dynamic> toJson() => {
        if (cuentaId != null) 'cuentaId': cuentaId,
        'nombrePortador': nombrePortador,
        'numeroTarjetaHash': numeroTarjetaHash,
        'tipo': tipo,
        if (banco != null && banco!.isNotEmpty) 'banco': banco,
        if (color != null && color!.isNotEmpty) 'color': color,
      };
}


