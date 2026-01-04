class Meta {
  final int id;
  final int usuarioId;
  final String nombre;
  final String? descripcion;
  final double montoObjetivo;
  final double montoActual;
  final DateTime fechaObjetivo;
  final String? icono;
  final String? color;
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Meta({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.descripcion,
    required this.montoObjetivo,
    required this.montoActual,
    required this.fechaObjetivo,
    this.icono,
    this.color,
    required this.activa,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  double get porcentajeCompletado {
    if (montoObjetivo <= 0) return 0;
    final porcentaje = (montoActual / montoObjetivo) * 100;
    return porcentaje > 100 ? 100 : porcentaje;
  }

  double get faltante {
    final faltante = montoObjetivo - montoActual;
    return faltante < 0 ? 0 : faltante;
  }

  bool get estaCompletada {
    if (montoObjetivo <= 0) return false;
    return montoActual >= montoObjetivo;
  }

  bool get estaVencida => DateTime.now().isAfter(fechaObjetivo);

  factory Meta.fromJson(Map<String, dynamic> json) {
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String && value.isNotEmpty) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double parseDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        // Remover comas y espacios, manejar punto decimal
        final cleaned = value.replaceAll(',', '').replaceAll(' ', '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }
      // Si es num (puede venir de JSON como número)
      if (value is num) return value.toDouble();
      return 0.0;
    }

    bool parseBoolSafe(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    DateTime parseDateTimeSafe(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Meta(
      id: parseIntSafe(json['id']),
      usuarioId: parseIntSafe(json['usuario_id'] ?? json['usuarioId']),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      montoObjetivo: parseDoubleSafe(
        json['monto_objetivo'] ?? json['montoObjetivo'],
      ),
      montoActual: parseDoubleSafe(json['monto_actual'] ?? json['montoActual']),
      fechaObjetivo: parseDateTimeSafe(
        json['fecha_objetivo'] ?? json['fechaObjetivo'],
      ),
      icono: json['icono']?.toString(),
      color: json['color']?.toString(),
      activa: parseBoolSafe(json['activa']),
      fechaCreacion: parseDateTimeSafe(
        json['fecha_creacion'] ?? json['fechaCreacion'],
      ),
      fechaActualizacion: parseDateTimeSafe(
        json['fecha_actualizacion'] ?? json['fechaActualizacion'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuarioId': usuarioId,
    'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    'montoObjetivo': montoObjetivo,
    'montoActual': montoActual,
    'fechaObjetivo': fechaObjetivo.toIso8601String(),
    if (icono != null) 'icono': icono,
    if (color != null) 'color': color,
    'activa': activa,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'fechaActualizacion': fechaActualizacion.toIso8601String(),
  };
}

class CreateMetaRequest {
  final String nombre;
  final String? descripcion;
  final double montoObjetivo;
  final DateTime fechaObjetivo;
  final String? icono;
  final String? color;

  CreateMetaRequest({
    required this.nombre,
    this.descripcion,
    required this.montoObjetivo,
    required this.fechaObjetivo,
    this.icono,
    this.color,
  });

  Map<String, dynamic> toJson() {
    String formatDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'nombre': nombre,
      if (descripcion != null && descripcion!.isNotEmpty)
        'descripcion': descripcion,
      'montoObjetivo': montoObjetivo,
      'fechaObjetivo': formatDate(fechaObjetivo),
      if (icono != null && icono!.isNotEmpty) 'icono': icono,
      if (color != null && color!.isNotEmpty) 'color': color,
    };
  }
}

class AporteMetaRequest {
  final int metaId;
  final int? cuentaId;
  final double montoAporte;
  final String? notas;

  AporteMetaRequest({
    required this.metaId,
    this.cuentaId,
    required this.montoAporte,
    this.notas,
  });

  Map<String, dynamic> toJson() => {
    'metaId': metaId,
    if (cuentaId != null) 'cuentaId': cuentaId,
    'montoAporte': montoAporte,
    if (notas != null && notas!.isNotEmpty) 'notas': notas,
  };
}
