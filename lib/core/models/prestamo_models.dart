// No UI imports here

class Prestamo {
  final int id;
  final int usuarioId;
  final int? cuentaId;
  final String nombre;
  final String tipo; // 'PRESTAMO' | 'DEUDA'
  final double montoTotal;
  final double saldoPendiente;
  final double? tasaInteres;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? notas;
  final bool activa;
  final String? estado; // 'PENDIENTE', 'PAGADO', 'CANCELADO'
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Prestamo({
    required this.id,
    required this.usuarioId,
    required this.cuentaId,
    required this.nombre,
    required this.tipo,
    required this.montoTotal,
    required this.saldoPendiente,
    required this.tasaInteres,
    required this.fechaInicio,
    required this.fechaFin,
    required this.notas,
    required this.activa,
    this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  bool get estaCompletado => saldoPendiente <= 0.0001;
  bool get estaPausado => !activa;
  bool get estaPagado => estado == 'PAGADO' || estaCompletado;

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        v == null ? 0 : (v is int ? v : int.tryParse('$v') ?? 0);
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      final s = ('$v').replaceAll(',', '').trim();
      return double.tryParse(s) ?? 0.0;
    }

    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse('$v');
      } catch (_) {
        return DateTime.now();
      }
    }

    return Prestamo(
      id: toInt(json['id']),
      usuarioId: toInt(json['usuario_id'] ?? json['usuarioId']),
      cuentaId: json['cuenta_id'] == null && json['cuentaId'] == null
          ? null
          : toInt(json['cuenta_id'] ?? json['cuentaId']),
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'DEUDA',
      montoTotal: toDouble(json['monto_total'] ?? json['montoTotal']),
      saldoPendiente: toDouble(
        json['saldo_pendiente'] ?? json['saldoPendiente'],
      ),
      tasaInteres: json['tasa_interes'] == null && json['tasaInteres'] == null
          ? null
          : toDouble(json['tasa_interes'] ?? json['tasaInteres']),
      fechaInicio: toDate(json['fecha_inicio'] ?? json['fechaInicio']),
      fechaFin: json['fecha_fin'] == null && json['fechaFin'] == null
          ? null
          : toDate(json['fecha_fin'] ?? json['fechaFin']),
      notas: json['notas']?.toString(),
      activa: (json['activa'] is bool)
          ? json['activa'] as bool
          : (json['activa'] is num)
          ? (json['activa'] as num) == 1
          : json['activa']?.toString().toLowerCase() == 'true',
      estado: json['estado']?.toString(),
      fechaCreacion: toDate(json['fecha_creacion'] ?? json['fechaCreacion']),
      fechaActualizacion: toDate(
        json['fecha_actualizacion'] ?? json['fechaActualizacion'],
      ),
    );
  }
}

class CreatePrestamoRequest {
  final String nombre;
  final String tipo; // 'PRESTAMO' | 'DEUDA'
  final double montoTotal;
  final double? tasaInteres;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? cuentaId;
  final String? notas;
  // Solo al crear: con cuentaId, genera el ingreso (DEUDA) o gasto (PRESTAMO)
  final bool? registrarMovimiento;

  CreatePrestamoRequest({
    required this.nombre,
    required this.tipo,
    required this.montoTotal,
    this.tasaInteres,
    this.fechaInicio,
    this.fechaFin,
    this.cuentaId,
    this.notas,
    this.registrarMovimiento,
  });

  Map<String, dynamic> toJson() {
    String? fmt(DateTime? d) => d == null
        ? null
        : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    return {
      'nombre': nombre,
      'tipo': tipo,
      'montoTotal': montoTotal,
      if (tasaInteres != null) 'tasaInteres': tasaInteres,
      if (fechaInicio != null) 'fechaInicio': fmt(fechaInicio),
      if (fechaFin != null) 'fechaFin': fmt(fechaFin),
      if (cuentaId != null) 'cuentaId': cuentaId,
      if (notas != null && notas!.isNotEmpty) 'notas': notas,
      if (registrarMovimiento != null) 'registrarMovimiento': registrarMovimiento,
    };
  }
}

class CreatePagoPrestamoRequest {
  final int prestamoId;
  final double monto;
  final DateTime? fechaPago;
  final int? cuentaId;
  final String? notas;

  CreatePagoPrestamoRequest({
    required this.prestamoId,
    required this.monto,
    this.fechaPago,
    this.cuentaId,
    this.notas,
  });

  Map<String, dynamic> toJson() {
    String? fmt(DateTime? d) => d == null
        ? null
        : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
    return {
      'monto': monto,
      if (fechaPago != null) 'fechaPago': fmt(fechaPago),
      if (cuentaId != null) 'cuentaId': cuentaId,
      if (notas != null && notas!.isNotEmpty) 'notas': notas,
    };
  }
}
