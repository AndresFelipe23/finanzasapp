class Cuenta {
  final int id;
  final int usuarioId;
  final String nombre;
  final String
  tipo; // 'BANCARIA', 'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'DIGITAL', 'AHORRO', 'INVERSION'
  final String moneda;
  final double saldoInicial;
  final String? color;
  final String? icono;
  final String? descripcion;
  final bool activa;
  final DateTime fechaCreacion;
  final double? saldoActual;

  // Solo tarjeta de crédito (opcionales)
  final double? cupo;
  final int? diaCorte;
  final int? diaPago;

  Cuenta({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.tipo,
    required this.moneda,
    required this.saldoInicial,
    this.color,
    this.icono,
    this.descripcion,
    required this.activa,
    required this.fechaCreacion,
    this.saldoActual,
    this.cupo,
    this.diaCorte,
    this.diaPago,
  });

  factory Cuenta.fromJson(Map<String, dynamic> json) => Cuenta(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    usuarioId: json['usuario_id'] is int
        ? json['usuario_id']
        : int.parse(json['usuario_id'].toString()),
    nombre: json['nombre'],
    tipo: json['tipo'],
    moneda: json['moneda'],
    saldoInicial: json['saldo_inicial']?.toDouble() ?? 0.0,
    color: json['color'],
    icono: json['icono'],
    descripcion: json['descripcion'],
    activa: json['activa'] ?? true,
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
    saldoActual: json['saldo_actual']?.toDouble(),
    cupo: (json['cupo'] as num?)?.toDouble(),
    diaCorte: (json['dia_corte'] as num?)?.toInt(),
    diaPago: (json['dia_pago'] as num?)?.toInt(),
  );

  double get saldo => saldoActual ?? saldoInicial;

  bool get esTarjetaCredito => tipo == 'TARJETA_CREDITO';

  /// Lo que se debe en una tarjeta de crédito (su saldo es negativo).
  double get deuda => saldo < 0 ? -saldo : 0;

  /// Cupo que queda para comprar (null si no se registró el cupo).
  double? get cupoDisponible => cupo == null ? null : cupo! - deuda;

  /// Próximo día de pago desde [desde] (incluido); null sin día de pago.
  DateTime? proximoPago([DateTime? desde]) => _proximoDia(diaPago, desde);

  /// Próximo día de corte desde [desde] (incluido).
  DateTime? proximoCorte([DateTime? desde]) => _proximoDia(diaCorte, desde);

  static DateTime? _proximoDia(int? dia, DateTime? desde) {
    if (dia == null) return null;
    final d = desde ?? DateTime.now();
    final hoy = DateTime(d.year, d.month, d.day);
    // Día 31 en un mes de 30 (o febrero): el último día del mes
    DateTime enMes(int y, int m) {
      final ultimo = DateTime(y, m + 1, 0).day;
      return DateTime(y, m, dia > ultimo ? ultimo : dia);
    }

    final este = enMes(hoy.year, hoy.month);
    return este.isBefore(hoy) ? enMes(hoy.year, hoy.month + 1) : este;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'nombre': nombre,
    'tipo': tipo,
    'moneda': moneda,
    'saldo_inicial': saldoInicial,
    'color': color,
    'icono': icono,
    'descripcion': descripcion,
    'activa': activa,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'saldo_actual': saldoActual,
  };
}

class CreateCuentaRequest {
  final String nombre;
  final String? tipo;
  final String? moneda;
  final double? saldoInicial;
  final String? color;
  final String? icono;
  final String? descripcion;
  final double? cupo;
  final int? diaCorte;
  final int? diaPago;

  CreateCuentaRequest({
    required this.nombre,
    this.tipo,
    this.moneda,
    this.saldoInicial,
    this.color,
    this.icono,
    this.descripcion,
    this.cupo,
    this.diaCorte,
    this.diaPago,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (tipo != null) 'tipo': tipo,
    if (moneda != null) 'moneda': moneda,
    if (saldoInicial != null) 'saldoInicial': saldoInicial,
    if (color != null) 'color': color,
    if (icono != null) 'icono': icono,
    if (descripcion != null) 'descripcion': descripcion,
    if (cupo != null) 'cupo': cupo,
    if (diaCorte != null) 'diaCorte': diaCorte,
    if (diaPago != null) 'diaPago': diaPago,
  };
}

class UpdateCuentaRequest {
  final String? nombre;
  final String? tipo;
  final String? moneda;
  final double? saldoInicial;
  final String? color;
  final String? icono;
  final String? descripcion;
  final bool? activa;

  /// Datos de tarjeta de crédito. Con [tarjeta] en true se envían siempre
  /// (null los borra); si no, no se tocan.
  final bool tarjeta;
  final double? cupo;
  final int? diaCorte;
  final int? diaPago;

  UpdateCuentaRequest({
    this.nombre,
    this.tipo,
    this.moneda,
    this.saldoInicial,
    this.color,
    this.icono,
    this.descripcion,
    this.activa,
    this.tarjeta = false,
    this.cupo,
    this.diaCorte,
    this.diaPago,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (tarjeta) {
      json['cupo'] = cupo;
      json['diaCorte'] = diaCorte;
      json['diaPago'] = diaPago;
    }
    if (nombre != null) json['nombre'] = nombre;
    if (tipo != null) json['tipo'] = tipo;
    if (moneda != null) json['moneda'] = moneda;
    if (saldoInicial != null) json['saldoInicial'] = saldoInicial;
    if (color != null) json['color'] = color;
    if (icono != null) json['icono'] = icono;
    if (descripcion != null) json['descripcion'] = descripcion;
    if (activa != null) json['activa'] = activa;
    return json;
  }
}

class CuentaSummary {
  final int id;
  final String nombre;
  final String tipo;
  final String moneda;
  final double saldoInicial;
  final String? color;
  final String? icono;
  final int totalTransacciones;
  final double saldoActual;
  final double totalIngresos;
  final double totalGastos;

  CuentaSummary({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.moneda,
    required this.saldoInicial,
    this.color,
    this.icono,
    required this.totalTransacciones,
    required this.saldoActual,
    required this.totalIngresos,
    required this.totalGastos,
  });

  factory CuentaSummary.fromJson(Map<String, dynamic> json) => CuentaSummary(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    nombre: json['nombre'],
    tipo: json['tipo'],
    moneda: json['moneda'],
    saldoInicial: json['saldo_inicial']?.toDouble() ?? 0.0,
    color: json['color'],
    icono: json['icono'],
    totalTransacciones: json['total_transacciones'] ?? 0,
    saldoActual: json['saldo_actual']?.toDouble() ?? 0.0,
    totalIngresos: json['total_ingresos']?.toDouble() ?? 0.0,
    totalGastos: json['total_gastos']?.toDouble() ?? 0.0,
  );
}
