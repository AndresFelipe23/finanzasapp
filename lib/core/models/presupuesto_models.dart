class Presupuesto {
  final int id;
  final int usuarioId;
  final String nombre;
  final int? categoriaId;
  final int? cuentaId;
  final String periodo; // SEMANAL | MENSUAL | ANUAL | PERSONALIZADO
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double montoLimite;
  final double montoGastado;
  final bool activo;
  final String? notas;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Presupuesto({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.categoriaId,
    required this.cuentaId,
    required this.periodo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.montoLimite,
    required this.montoGastado,
    required this.activo,
    required this.notas,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  double get porcentaje =>
      montoLimite <= 0 ? 0 : (montoGastado / montoLimite) * 100;
  bool get sobrepasado => montoGastado > montoLimite && montoLimite > 0;

  factory Presupuesto.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v == null ? 0 : (v is int ? v : int.tryParse('$v') ?? 0);
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse('$v'.replaceAll(',', '').trim()) ?? 0.0;
    }

    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse('$v');
      } catch (_) {
        return DateTime.now();
      }
    }

    return Presupuesto(
      id: toInt(json['id']),
      usuarioId: toInt(json['usuario_id'] ?? json['usuarioId']),
      nombre: json['nombre']?.toString() ?? '',
      categoriaId: json['categoria_id'] != null
          ? toInt(json['categoria_id'])
          : (json['categoriaId'] != null ? toInt(json['categoriaId']) : null),
      cuentaId: json['cuenta_id'] != null
          ? toInt(json['cuenta_id'])
          : (json['cuentaId'] != null ? toInt(json['cuentaId']) : null),
      periodo: json['periodo']?.toString() ?? 'MENSUAL',
      fechaInicio: toDate(json['fecha_inicio'] ?? json['fechaInicio']),
      fechaFin: toDate(json['fecha_fin'] ?? json['fechaFin']),
      montoLimite: toDouble(json['monto_limite'] ?? json['montoLimite']),
      montoGastado: toDouble(json['monto_gastado'] ?? json['montoGastado']),
      activo: (json['activo'] is bool)
          ? json['activo'] as bool
          : (json['activo'] is num)
          ? (json['activo'] as num) == 1
          : json['activo']?.toString().toLowerCase() == 'true',
      notas: json['notas']?.toString(),
      fechaCreacion: toDate(json['fecha_creacion'] ?? json['fechaCreacion']),
      fechaActualizacion: toDate(
        json['fecha_actualizacion'] ?? json['fechaActualizacion'],
      ),
    );
  }
}

class CreatePresupuestoRequest {
  final String nombre;
  final String periodo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final double montoLimite;
  final int? categoriaId;
  final int? cuentaId;
  final String? notas;

  CreatePresupuestoRequest({
    required this.nombre,
    required this.periodo,
    required this.montoLimite,
    this.fechaInicio,
    this.fechaFin,
    this.categoriaId,
    this.cuentaId,
    this.notas,
  });

  Map<String, dynamic> toJson() {
    String? fmt(DateTime? d) {
      if (d == null) return null;
      // Formato ISO8601 simple: YYYY-MM-DDTHH:MM:SS (sin Z)
      // showDatePicker devuelve solo la fecha, así que usamos hora 00:00:00
      final dateStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
      return '${dateStr}T$timeStr';
    }

    return {
      'nombre': nombre,
      'periodo': periodo,
      if (fechaInicio != null) 'fechaInicio': fmt(fechaInicio),
      if (fechaFin != null) 'fechaFin': fmt(fechaFin),
      'montoLimite': montoLimite,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (cuentaId != null) 'cuentaId': cuentaId,
      if (notas != null && notas!.isNotEmpty) 'notas': notas,
    };
  }
}
