class PagoRecurrente {
  final int id;
  final int categoriaId;
  final String? categoriaNombre;
  final int? cuentaId;
  final String? cuentaNombre;
  final double monto;
  final String descripcion;
  final String frecuencia; // DIARIO, SEMANAL, MENSUAL, BIMESTRAL, TRIMESTRAL, SEMESTRAL, ANUAL
  final int? diaVencimiento; // 1..31
  final int? diaSemana; // 1..7 (1=Lunes)
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool activo;

  PagoRecurrente({
    required this.id,
    required this.categoriaId,
    this.categoriaNombre,
    this.cuentaId,
    this.cuentaNombre,
    required this.monto,
    required this.descripcion,
    required this.frecuencia,
    this.diaVencimiento,
    this.diaSemana,
    required this.fechaInicio,
    this.fechaFin,
    required this.activo,
  });

  factory PagoRecurrente.fromJson(Map<String, dynamic> json) {
    // SQL Server devuelve BIGINT como string y BIT como bool o 0/1
    int toInt(dynamic v) =>
        v == null ? 0 : (v is int ? v : int.tryParse('$v') ?? 0);
    int? toIntOrNull(dynamic v) => v == null ? null : toInt(v);
    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    bool toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return '$v'.toLowerCase() == 'true';
    }

    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      final parsed = DateTime.tryParse('$v'.replaceFirst(' ', 'T'));
      if (parsed == null) return null;
      // Las fechas del servidor son locales aunque traigan Z
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    return PagoRecurrente(
      id: toInt(json['id']),
      categoriaId: toInt(json['categoria_id']),
      categoriaNombre: json['categoria_nombre']?.toString(),
      cuentaId: toIntOrNull(json['cuenta_id']),
      cuentaNombre: json['cuenta_nombre']?.toString(),
      monto: toDouble(json['monto']),
      descripcion: json['descripcion']?.toString() ?? '',
      frecuencia: json['frecuencia']?.toString() ?? 'MENSUAL',
      diaVencimiento: toIntOrNull(json['dia_vencimiento']),
      diaSemana: toIntOrNull(json['dia_semana']),
      fechaInicio: toDate(json['fecha_inicio']) ?? DateTime.now(),
      fechaFin: toDate(json['fecha_fin']),
      activo: toBool(json['activo']),
    );
  }

  static const frecuencias = {
    'DIARIO': 'Diario',
    'SEMANAL': 'Semanal',
    'MENSUAL': 'Mensual',
    'BIMESTRAL': 'Bimestral',
    'TRIMESTRAL': 'Trimestral',
    'SEMESTRAL': 'Semestral',
    'ANUAL': 'Anual',
  };

  String get frecuenciaLabel => frecuencias[frecuencia] ?? frecuencia;

  /// Próxima fecha de cobro a partir de [desde] (incluido), con las mismas
  /// reglas que usa el scheduler del servidor. Null si la regla ya terminó.
  DateTime? proximaFecha([DateTime? desde]) {
    final now = desde ?? DateTime.now();
    var hoy = DateTime(now.year, now.month, now.day);
    if (hoy.isBefore(fechaInicio)) hoy = fechaInicio;

    DateTime? candidata;
    switch (frecuencia) {
      case 'DIARIO':
        candidata = hoy;
      case 'SEMANAL':
        final objetivo = diaSemana ?? 1;
        final delta = (objetivo - hoy.weekday + 7) % 7;
        candidata = hoy.add(Duration(days: delta));
      default:
        final paso = switch (frecuencia) {
          'BIMESTRAL' => 2,
          'TRIMESTRAL' => 3,
          'SEMESTRAL' => 6,
          'ANUAL' => 12,
          _ => 1,
        };
        final dia = diaVencimiento ?? 1;
        var mes = DateTime(fechaInicio.year, fechaInicio.month, 1);
        // Límite de seguridad para no iterar indefinidamente
        for (var i = 0; i < 1200; i++) {
          final ultimo = DateTime(mes.year, mes.month + 1, 0).day;
          final ejec = DateTime(mes.year, mes.month, dia > ultimo ? ultimo : dia);
          if (!ejec.isBefore(hoy)) {
            candidata = ejec;
            break;
          }
          mes = DateTime(mes.year, mes.month + paso, 1);
        }
    }

    if (candidata == null) return null;
    if (fechaFin != null && candidata.isAfter(fechaFin!)) return null;
    return candidata;
  }
}
