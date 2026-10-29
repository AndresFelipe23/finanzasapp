import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/currency/exchange_rates.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';

// Paleta para categorías sin color propio
const _fallbackPalette = [
  Brand.accent,
  Brand.blue,
  Brand.expense,
  Color(0xFF6B3FA0),
  Color(0xFF7FB8A0),
  Color(0xFFA86A0C),
];

Color? _parseHex(String? h) {
  if (h == null || h.isEmpty) return null;
  final s = h.replaceAll('#', '');
  try {
    return s.length == 6
        ? Color(int.parse('FF$s', radix: 16))
        : Color(int.parse(s, radix: 16));
  } catch (_) {
    return null;
  }
}

String _money(double v) => NumberFormat.compactCurrency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
).format(v);

// ─── Gasto por categoría (mes actual) ─────────────────────────────────────────
class GastoPorCategoriaChart extends ConsumerWidget {
  final AsyncValue<List<Transaccion>> transAsync;
  const GastoPorCategoriaChart({super.key, required this.transAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tk = _Tk();
    final items = transAsync.valueOrNull;
    if (items == null) return const SizedBox.shrink();
    // Montos en otra moneda se suman convertidos a la predeterminada
    final tasas = tasasPara(ref, items.map((t) => t.moneda));

    final now = DateTime.now();
    final porCategoria = <String, double>{};
    final colores = <String, Color?>{};
    for (final t in items) {
      if (t.tipoNombre != 'GASTO') continue;
      final f = t.fechaTransaccion;
      if (f.year != now.year || f.month != now.month) continue;
      final nombre = t.categoriaNombre ?? 'Sin categoría';
      porCategoria[nombre] = (porCategoria[nombre] ?? 0) + tasas.aBase(t.monto, t.moneda);
      colores[nombre] ??= _parseHex(t.categoriaColor);
    }

    if (porCategoria.isEmpty) {
      return _ChartCard(
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text(
              'Aún no tienes gastos este mes',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: tk.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    // Top 5 + "Otros" para que la dona siga siendo legible
    final ordenadas = porCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordenadas.take(5).toList();
    final resto = ordenadas.skip(5).fold<double>(0, (s, e) => s + e.value);
    final total = ordenadas.fold<double>(0, (s, e) => s + e.value);

    final segmentos = <({String nombre, double valor, Color color})>[
      for (var i = 0; i < top.length; i++)
        (
          nombre: top[i].key,
          valor: top[i].value,
          color:
              colores[top[i].key] ??
              _fallbackPalette[i % _fallbackPalette.length],
        ),
      if (resto > 0)
        (nombre: 'Otros', valor: resto, color: tk.textSecondary),
    ];

    return _ChartCard(
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    startDegreeOffset: -90,
                    sections: [
                      for (final s in segmentos)
                        PieChartSectionData(
                          value: s.valor,
                          color: s.color,
                          radius: 18,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: tk.textSecondary,
                      ),
                    ),
                    Text(
                      _money(total),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tk.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in segmentos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: tk.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(s.valor / total * 100).round()}%',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: tk.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ingresos vs gastos (últimos 6 meses) ────────────────────────────────────
class IngresosGastosChart extends ConsumerWidget {
  final AsyncValue<List<Transaccion>> transAsync;
  const IngresosGastosChart({super.key, required this.transAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tk = _Tk();
    final items = transAsync.valueOrNull;
    if (items == null) return const SizedBox.shrink();
    // Montos en otra moneda se suman convertidos a la predeterminada
    final tasas = tasasPara(ref, items.map((t) => t.moneda));

    final now = DateTime.now();
    final meses = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    final ingresos = List<double>.filled(6, 0);
    final gastos = List<double>.filled(6, 0);

    for (final t in items) {
      final f = t.fechaTransaccion;
      final idx = meses.indexWhere(
        (m) => m.year == f.year && m.month == f.month,
      );
      if (idx < 0) continue;
      if (t.tipoNombre == 'INGRESO') ingresos[idx] += tasas.aBase(t.monto, t.moneda);
      if (t.tipoNombre == 'GASTO') gastos[idx] += tasas.aBase(t.monto, t.moneda);
    }

    final maxY = [...ingresos, ...gastos].fold<double>(0, (a, b) => a > b ? a : b);
    final mesFmt = DateFormat('MMM', 'es_ES');

    return _ChartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Leyenda(color: tk.success, label: 'Ingresos'),
              const SizedBox(width: 16),
              _Leyenda(color: tk.danger, label: 'Gastos'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: maxY == 0
                ? Center(
                    child: Text(
                      'Sin movimientos en los últimos 6 meses',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: tk.textSecondary,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY * 1.15,
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: tk.divider, strokeWidth: 1),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => tk.surface,
                          getTooltipItem: (group, _, rod, rodIndex) =>
                              BarTooltipItem(
                                _money(rod.toY),
                                GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: rodIndex == 0
                                      ? tk.success
                                      : tk.danger,
                                ),
                              ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: maxY / 3,
                            getTitlesWidget: (value, meta) => Text(
                              _money(value),
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: tk.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                mesFmt.format(meses[value.toInt()]),
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: tk.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < 6; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: 4,
                            barRods: [
                              BarChartRodData(
                                toY: ingresos[i],
                                color: tk.success,
                                width: 9,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: gastos[i],
                                color: tk.danger,
                                width: 9,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Brand.muted,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.border),
      ),
      child: child,
    );
  }
}

/// Colores de las gráficas, tomados de la paleta del diseño.
class _Tk {
  const _Tk();

  Color get textPrimary => Brand.ink;
  Color get primary => Brand.ink;
  Color get textSecondary => Brand.muted;
  Color get success => Brand.accent;
  Color get danger => Brand.expense;
  Color get divider => Brand.track;
  Color get surface => Brand.surface;
}
