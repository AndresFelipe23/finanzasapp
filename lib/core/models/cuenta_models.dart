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
  );

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

  CreateCuentaRequest({
    required this.nombre,
    this.tipo,
    this.moneda,
    this.saldoInicial,
    this.color,
    this.icono,
    this.descripcion,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (tipo != null) 'tipo': tipo,
    if (moneda != null) 'moneda': moneda,
    if (saldoInicial != null) 'saldoInicial': saldoInicial,
    if (color != null) 'color': color,
    if (icono != null) 'icono': icono,
    if (descripcion != null) 'descripcion': descripcion,
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

  UpdateCuentaRequest({
    this.nombre,
    this.tipo,
    this.moneda,
    this.saldoInicial,
    this.color,
    this.icono,
    this.descripcion,
    this.activa,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
