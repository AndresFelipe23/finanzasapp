import 'package:intl/intl.dart';
import '../currency/exchange_rates.dart';
import '../models/presupuesto_models.dart';
import '../models/transaccion_models.dart';

/// Resumen de la semana (lunes a domingo): cuánto se gastó, contra la semana
/// pasada, en qué, cuánto se ahorró y qué presupuestos van justos. Es pura (sin
/// red ni almacenamiento) para poder probarla y usarla en segundo plano.
class ResumenSemanal {
  const ResumenSemanal({
    required this.gastos,
    required this.ingresos,
    required this.ahorro,
    required this.gastosPrevios,
    this.topCategoria,
    this.topMonto = 0,
    this.presupuestos = const [],
  });

  final double gastos;
  final double ingresos;

  /// Aportes a metas (ahorro: bajan el saldo pero no son gasto).
  final double ahorro;

  /// Gastos de la semana pasada en el mismo tramo de tiempo, para comparar.
  final double gastosPrevios;
  final String? topCategoria;
  final double topMonto;

  /// Presupuestos vigentes que van en 80% o más ("Mercado 85%").
  final List<String> presupuestos;

  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

  /// Lunes a las 00:00 de la semana de [fecha].
  static DateTime inicioSemana(DateTime fecha) {
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// Próximo domingo a las 20:00 (hoy mismo si todavía no son las 20:00).
  static DateTime proximoDomingo(DateTime ahora) {
    final extra = (DateTime.sunday - ahora.weekday) % 7;
    final hoy = DateTime(ahora.year, ahora.month, ahora.day + extra, 20);
    return hoy.isAfter(ahora) ? hoy : DateTime(hoy.year, hoy.month, hoy.day + 7, 20);
  }

  /// Calcula el resumen de la semana de [ahora] con los movimientos de
  /// [trans]. Los montos en otra moneda se convierten con [tasas] si las hay.
  static ResumenSemanal calcular(
    List<Transaccion> trans,
    List<Presupuesto> presupuestos,
    DateTime ahora, {
    Tasas? tasas,
  }) {
    final inicio = inicioSemana(ahora);
    final inicioPrevia = DateTime(inicio.year, inicio.month, inicio.day - 7);
    // La semana pasada se mide hasta el mismo punto de la semana, así la
    // comparación es justa aunque el resumen se haya calculado a media semana
    final finPrevia = inicioPrevia.add(ahora.difference(inicio));
    double enBase(Transaccion t) => tasas?.aBase(t.monto, t.moneda) ?? t.monto;

    double gastos = 0, ingresos = 0, ahorro = 0, previos = 0;
    final porCategoria = <String, double>{};
    for (final t in trans) {
      final f = t.fechaTransaccion;
      if (!f.isBefore(inicio) && !f.isAfter(ahora)) {
        if (t.esGasto) {
          final m = enBase(t);
          gastos += m;
          final nombre = t.categoriaNombre ?? 'Sin categoría';
          porCategoria[nombre] = (porCategoria[nombre] ?? 0) + m;
        } else if (t.esIngreso) {
          ingresos += enBase(t);
        } else if (t.esAporteMeta) {
          ahorro += enBase(t);
        }
      } else if (t.esGasto && !f.isBefore(inicioPrevia) && !f.isAfter(finPrevia)) {
        previos += enBase(t);
      }
    }

    final top = (porCategoria.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .firstOrNull;

    final enRiesgo = presupuestos
        .where((p) =>
            p.activo &&
            p.montoLimite > 0 &&
            !ahora.isBefore(p.fechaInicio) &&
            !ahora.isAfter(DateTime(p.fechaFin.year, p.fechaFin.month, p.fechaFin.day, 23, 59, 59)) &&
            p.porcentaje >= 80)
        .toList()
      ..sort((a, b) => b.porcentaje.compareTo(a.porcentaje));

    return ResumenSemanal(
      gastos: gastos,
      ingresos: ingresos,
      ahorro: ahorro,
      gastosPrevios: previos,
      topCategoria: top?.key,
      topMonto: top?.value ?? 0,
      presupuestos: [for (final p in enRiesgo.take(2)) '${p.nombre} ${p.porcentaje.round()}%'],
    );
  }

  /// Sin gastos, ingresos ni ahorro: no hay nada que contar.
  bool get sinActividad => gastos == 0 && ingresos == 0 && ahorro == 0;

  String get titulo => gastos > 0
      ? 'Esta semana gastaste ${_money.format(gastos)}'
      : 'Esta semana no registraste gastos';

  String get cuerpo {
    final lineas = <String>[];
    if (gastos > 0 && gastosPrevios > 0) {
      final pct = ((gastos - gastosPrevios) / gastosPrevios * 100).round();
      lineas.add(
        pct.abs() <= 2
            ? 'Igual que la semana pasada.'
            : pct > 0
            ? '$pct% más que la semana pasada.'
            : '${-pct}% menos que la semana pasada.',
      );
    }
    if (topCategoria != null) {
      lineas.add('Lo que más pesó: $topCategoria (${_money.format(topMonto)}).');
    }
    if (ingresos > 0 || ahorro > 0) {
      final partes = [
        if (ingresos > 0) 'Ingresos ${_money.format(ingresos)}',
        if (ahorro > 0) 'ahorraste ${_money.format(ahorro)}',
      ];
      lineas.add('${partes.join(' · ')}.');
    }
    if (presupuestos.isNotEmpty) {
      lineas.add('Ojo con tus presupuestos: ${presupuestos.join(', ')}.');
    }
    return lineas.isEmpty ? 'Toca para ver tus movimientos.' : lineas.join('\n');
  }
}
