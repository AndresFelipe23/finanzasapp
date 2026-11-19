// No UI imports here
import 'dart:math' as math;

/// Una fila de la tabla de amortización de un crédito en cuotas.
class CuotaCredito {
  const CuotaCredito({
    required this.numero,
    required this.fecha,
    required this.valor,
    required this.cargoAdicional,
    this.interes,
    this.capital,
    this.saldoCapital,
    required this.pagada,
  });

  final int numero;
  final DateTime? fecha;
  final double valor;
  final double cargoAdicional;

  /// Interés y abono a capital de la cuota (null si no se conoce el capital
  /// prestado o la tasa).
  final double? interes;
  final double? capital;

  /// Capital que queda después de pagar esta cuota.
  final double? saldoCapital;
  final bool pagada;
}

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

  // ── Crédito en cuotas (opcional, migration-prestamos-cuotas.sql). Con
  // cuotas previas, montoPrestado es el capital vigente al registrarlo.
  final double? montoPrestado;
  final String? cargoAdicionalNombre;
  final double? cargoAdicionalTotal;
  final String? tipoTasa; // 'EA' efectiva anual | 'MV' mes vencido
  final int? numeroCuotas;
  final double? valorCuota;
  final int? diaPago;
  final DateTime? fechaPrimeraCuota;
  final int? cuotasPrevias;

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
    this.montoPrestado,
    this.cargoAdicionalNombre,
    this.cargoAdicionalTotal,
    this.tipoTasa,
    this.numeroCuotas,
    this.valorCuota,
    this.diaPago,
    this.fechaPrimeraCuota,
    this.cuotasPrevias,
  });

  bool get estaCompletado => saldoPendiente <= 0.0001;
  bool get estaPausado => !activa;
  bool get estaPagado => estado == 'PAGADO' || estaCompletado;

  // ── Cálculos del crédito en cuotas ──────────────────────────────────────

  bool get enCuotas =>
      numeroCuotas != null && numeroCuotas! > 0 && (valorCuota ?? 0) > 0;

  /// Tasa mensual como fracción (0.0181 = 1,81%). La E.A. se convierte con
  /// (1 + EA)^(1/12) − 1, como hacen los bancos.
  double? get tasaMensual => tasaMensualDe(tasaInteres, tipoTasa);
  double get cargoAdicionalPorCuota =>
      enCuotas ? (cargoAdicionalTotal ?? 0) / numeroCuotas! : 0;
  double? get cuotaTotal =>
      enCuotas ? valorCuota! + cargoAdicionalPorCuota : null;

  static double? tasaMensualDe(double? tasa, String? tipo) {
    if (tasa == null || tasa <= 0) return null;
    return tipo == 'MV' ? tasa / 100 : math.pow(1 + tasa / 100, 1 / 12) - 1;
  }

  /// Cuota fija del sistema francés para [capital] a [cuotas] meses.
  static double cuotaFija(double capital, double? tasaMensual, int cuotas) {
    if (cuotas <= 0) return 0;
    final i = tasaMensual ?? 0;
    if (i <= 0) return capital / cuotas;
    return capital * i / (1 - math.pow(1 + i, -cuotas));
  }

  /// Cuotas pagadas: las de antes de registrarlo más las cubiertas por los
  /// pagos hechos en la app (un abono parcial no completa una cuota).
  int get cuotasPagadas {
    if (!enCuotas) return 0;
    final pagado = montoTotal - saldoPendiente;
    final enApp = ((pagado + 1) / cuotaTotal!).floor();
    return ((cuotasPrevias ?? 0) + enApp).clamp(0, numeroCuotas!);
  }

  /// Capital vigente al registrar, menos el abono a capital de las cuotas
  /// posteriores que ya se pagaron desde la app.
  double? get capitalPendiente {
    if (!enCuotas || montoPrestado == null) return null;
    var saldo = montoPrestado!;
    final primeraCuotaControlada = (cuotasPrevias ?? 0).clamp(0, numeroCuotas!);
    final cuotasEnApp = (cuotasPagadas - primeraCuotaControlada).clamp(
      0,
      numeroCuotas! - primeraCuotaControlada,
    );
    final tasa = tasaMensual ?? 0;
    for (var k = 0; k < cuotasEnApp; k++) {
      final interes = saldo * tasa;
      final capital = tasa > 0
          ? math.min(valorCuota! - interes, saldo)
          : math.min(valorCuota!, saldo);
      saldo -= capital;
    }
    return math.max(0, saldo);
  }

  /// Número de la próxima cuota a pagar (null si ya se pagaron todas).
  int? get proximaCuota =>
      enCuotas && cuotasPagadas < numeroCuotas! ? cuotasPagadas + 1 : null;

  /// Vencimiento de la cuota [n] (1 = la primera): un mes después de la
  /// anterior, el día de pago (o el último día si el mes es más corto).
  DateTime? fechaCuota(int n) {
    final base = fechaPrimeraCuota;
    if (base == null) return null;
    final dia = diaPago ?? base.day;
    final mes = DateTime(base.year, base.month + n - 1, 1);
    final ultimo = DateTime(mes.year, mes.month + 1, 0).day;
    return DateTime(mes.year, mes.month, dia > ultimo ? ultimo : dia);
  }

  DateTime? get proximoVencimiento =>
      proximaCuota == null ? null : fechaCuota(proximaCuota!);

  DateTime? get fechaUltimaCuota => enCuotas ? fechaCuota(numeroCuotas!) : null;

  /// Lo que se paga en total en todo el crédito y cuánto de eso es interés.
  double? get totalAPagar => enCuotas ? saldoPendiente : null;
  double? get totalIntereses {
    if (!enCuotas || montoPrestado == null) return null;
    final cuotasFuturas = numeroCuotas! - cuotasPagadas;
    final capitalActual = capitalPendiente ?? montoPrestado!;
    return math.max(0, valorCuota! * cuotasFuturas - capitalActual);
  }

  /// Tabla de amortización. Con capital y tasa reparte cada cuota en
  /// interés y abono a capital; sin ellos, solo fechas y valor.
  List<CuotaCredito> tabla() {
    if (!enCuotas) return const [];
    final n = numeroCuotas!;
    final i = tasaMensual;
    final pagadas = cuotasPagadas;
    final previas = (cuotasPrevias ?? 0).clamp(0, n);
    var saldo = montoPrestado;
    return [
      for (var k = 1; k <= n; k++)
        () {
          double? interes, capital;
          if (k > previas && saldo != null && i != null) {
            interes = saldo! * i;
            // La última cuota cierra el saldo aunque la cuota real del banco
            // difiera un poco del cálculo
            capital = k == n ? saldo : math.min(valorCuota! - interes, saldo!);
            saldo = saldo! - capital!;
          } else if (k > previas && saldo != null && i == null) {
            capital = math.min(valorCuota!, saldo!);
            interes = 0;
            saldo = saldo! - capital;
          }
          return CuotaCredito(
            numero: k,
            fecha: fechaCuota(k),
            valor: valorCuota! + cargoAdicionalPorCuota,
            cargoAdicional: cargoAdicionalPorCuota,
            interes: interes,
            capital: capital,
            saldoCapital: k <= previas || saldo == null
                ? null
                : math.max(0, saldo!),
            pagada: k <= pagadas,
          );
        }(),
    ];
  }

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
      montoPrestado: json['monto_prestado'] == null
          ? null
          : toDouble(json['monto_prestado']),
      cargoAdicionalNombre:
          json['cargo_adicional_nombre']?.toString() ??
          json['cargoAdicionalNombre']?.toString(),
      cargoAdicionalTotal:
          json['cargo_adicional_total'] == null &&
              json['cargoAdicionalTotal'] == null
          ? null
          : toDouble(
              json['cargo_adicional_total'] ?? json['cargoAdicionalTotal'],
            ),
      tipoTasa: json['tipo_tasa']?.toString(),
      numeroCuotas: json['numero_cuotas'] == null
          ? null
          : toInt(json['numero_cuotas']),
      valorCuota: json['valor_cuota'] == null
          ? null
          : toDouble(json['valor_cuota']),
      diaPago: json['dia_pago'] == null ? null : toInt(json['dia_pago']),
      fechaPrimeraCuota: json['fecha_primera_cuota'] == null
          ? null
          : toDate(json['fecha_primera_cuota']),
      cuotasPrevias: json['cuotas_previas'] == null
          ? null
          : toInt(json['cuotas_previas']),
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

  /// true: se envían los datos de cuotas (null los borra, p. ej. al pasar
  /// un crédito a "sin cuotas"); false: no se tocan.
  final bool cuotas;
  final double? montoPrestado;
  final String? cargoAdicionalNombre;
  final double? cargoAdicionalTotal;
  final String? tipoTasa;
  final int? numeroCuotas;
  final double? valorCuota;
  final int? diaPago;
  final DateTime? fechaPrimeraCuota;
  final int? cuotasPrevias;

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
    this.cuotas = false,
    this.montoPrestado,
    this.cargoAdicionalNombre,
    this.cargoAdicionalTotal,
    this.tipoTasa,
    this.numeroCuotas,
    this.valorCuota,
    this.diaPago,
    this.fechaPrimeraCuota,
    this.cuotasPrevias,
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
      if (registrarMovimiento != null)
        'registrarMovimiento': registrarMovimiento,
      if (cuotas) ...{
        'montoPrestado': montoPrestado,
        'cargoAdicionalNombre': cargoAdicionalNombre,
        'cargoAdicionalTotal': cargoAdicionalTotal,
        'tipoTasa': tipoTasa,
        'numeroCuotas': numeroCuotas,
        'valorCuota': valorCuota,
        'diaPago': diaPago,
        'fechaPrimeraCuota': fechaPrimeraCuota == null
            ? null
            : fmt(
                DateTime(
                  fechaPrimeraCuota!.year,
                  fechaPrimeraCuota!.month,
                  fechaPrimeraCuota!.day,
                ),
              ),
        'cuotasPrevias': cuotasPrevias,
      },
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
