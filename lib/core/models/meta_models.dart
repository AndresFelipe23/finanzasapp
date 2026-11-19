/// Cómo va una meta frente a un ahorro parejo hasta su fecha.
enum RitmoMeta { adelantada, alDia, atrasada }

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

  /// Aporte automático: % de cada ingreso que se aparta para esta meta (null
  /// si no aparta nada) y, opcional, el ingreso mínimo para que aplique.
  final double? aporteAutoPorcentaje;
  final double? aporteAutoMinimo;

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
    this.aporteAutoPorcentaje,
    this.aporteAutoMinimo,
  });

  bool get tieneAporteAuto => (aporteAutoPorcentaje ?? 0) > 0;

  /// Lo que se apartaría de un ingreso de [ingreso] (0 si no aplica: sin
  /// regla, meta pausada o cumplida, o ingreso menor al mínimo). Nunca más
  /// de lo que falta para la meta; lo mismo que hace el servidor.
  double aporteAutoDe(double ingreso) {
    if (!tieneAporteAuto || !activa || estaCompletada) return 0;
    if (ingreso < (aporteAutoMinimo ?? 0)) return 0;
    final aporte = (ingreso * aporteAutoPorcentaje! / 100 * 100).round() / 100;
    return aporte > faltante ? faltante : aporte;
  }

  // ── Ritmo: ¿se va a llegar a tiempo? ────────────────────────────────────

  /// Meses que quedan hasta la fecha objetivo (mínimo 1; 0 si ya venció).
  int get mesesRestantes {
    if (estaVencida) return 0;
    final now = DateTime.now();
    final meses = (fechaObjetivo.year - now.year) * 12 + fechaObjetivo.month - now.month;
    return meses < 1 ? 1 : meses;
  }

  /// Lo que hay que ahorrar cada mes para llegar a tiempo.
  double get ahorroMensualNecesario =>
      estaCompletada || estaVencida ? 0 : faltante / mesesRestantes;

  /// Lo que llevaría hoy si ahorrara a ritmo parejo desde que creó la meta.
  double get ahorroEsperadoHoy {
    final total = fechaObjetivo.difference(fechaCreacion).inSeconds;
    if (total <= 0) return montoObjetivo;
    final pasado = DateTime.now().difference(fechaCreacion).inSeconds.clamp(0, total);
    return montoObjetivo * pasado / total;
  }

  /// Positivo: va por delante del ritmo; negativo: por detrás.
  double get diferenciaRitmo => montoActual - ahorroEsperadoHoy;

  /// Estado del ritmo; null si no aplica (cumplida, vencida o pausada). Hay
  /// una tolerancia del 3% de la meta para llamarlo "al día".
  RitmoMeta? get ritmo {
    if (estaCompletada || estaVencida || !activa) return null;
    final tolerancia = montoObjetivo * 0.03;
    final d = diferenciaRitmo;
    if (d > tolerancia) return RitmoMeta.adelantada;
    if (d < -tolerancia) return RitmoMeta.atrasada;
    return RitmoMeta.alDia;
  }

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
      aporteAutoPorcentaje: json['aporte_auto_porcentaje'] == null
          ? null
          : parseDoubleSafe(json['aporte_auto_porcentaje']),
      aporteAutoMinimo: json['aporte_auto_minimo'] == null
          ? null
          : parseDoubleSafe(json['aporte_auto_minimo']),
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

  /// true: se envía la regla de aporte automático (null la desactiva); false:
  /// no se toca.
  final bool aporteAuto;
  final double? aporteAutoPorcentaje;
  final double? aporteAutoMinimo;

  CreateMetaRequest({
    required this.nombre,
    this.descripcion,
    required this.montoObjetivo,
    required this.fechaObjetivo,
    this.icono,
    this.color,
    this.aporteAuto = false,
    this.aporteAutoPorcentaje,
    this.aporteAutoMinimo,
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
      if (aporteAuto) ...{
        'aporteAutoPorcentaje': aporteAutoPorcentaje,
        'aporteAutoMinimo': aporteAutoMinimo,
      },
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
