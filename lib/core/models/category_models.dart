class Categoria {
  final int id;
  final int? usuarioId;
  final String nombre;
  final String? icono;
  final String? color;
  final String tipo; // 'INGRESO', 'GASTO', 'AMBOS'
  final bool activo;
  final DateTime fechaCreacion;

  Categoria({
    required this.id,
    this.usuarioId,
    required this.nombre,
    this.icono,
    this.color,
    required this.tipo,
    required this.activo,
    required this.fechaCreacion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    usuarioId: json['usuario_id'],
    nombre: json['nombre'],
    icono: json['icono'],
    color: json['color'],
    tipo: json['tipo'],
    activo: json['activo'] ?? true,
    fechaCreacion: DateTime.parse(json['fecha_creacion']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'nombre': nombre,
    'icono': icono,
    'color': color,
    'tipo': tipo,
    'activo': activo,
    'fecha_creacion': fechaCreacion.toIso8601String(),
  };
}

class CreateCategoriaRequest {
  final String nombre;
  final String? icono;
  final String? color;
  final String? tipo; // 'INGRESO', 'GASTO', 'AMBOS'

  CreateCategoriaRequest({
    required this.nombre,
    this.icono,
    this.color,
    this.tipo,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (icono != null) 'icono': icono,
    if (color != null) 'color': color,
    if (tipo != null) 'tipo': tipo,
  };
}

class UpdateCategoriaRequest {
  final String? nombre;
  final String? icono;
  final String? color;
  final String? tipo;
  final bool? activo;

  UpdateCategoriaRequest({
    this.nombre,
    this.icono,
    this.color,
    this.tipo,
    this.activo,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (nombre != null) json['nombre'] = nombre;
    if (icono != null) json['icono'] = icono;
    if (color != null) json['color'] = color;
    if (tipo != null) json['tipo'] = tipo;
    if (activo != null) json['activo'] = activo;
    return json;
  }
}

class CategoriaSummary {
  final int id;
  final String nombre;
  final String tipo;
  final String? color;
  final String? icono;
  final int totalTransacciones;
  final double totalIngresos;
  final double totalGastos;

  CategoriaSummary({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.color,
    this.icono,
    required this.totalTransacciones,
    required this.totalIngresos,
    required this.totalGastos,
  });

  factory CategoriaSummary.fromJson(Map<String, dynamic> json) =>
      CategoriaSummary(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        nombre: json['nombre'],
        tipo: json['tipo'],
        color: json['color'],
        icono: json['icono'],
        totalTransacciones: json['total_transacciones'] ?? 0,
        totalIngresos: json['total_ingresos']?.toDouble() ?? 0.0,
        totalGastos: json['total_gastos']?.toDouble() ?? 0.0,
      );
}
