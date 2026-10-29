import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category_models.dart';
import '../../core/theme/brand.dart';
import '../transactions/transactions_provider.dart';
import 'categories_provider.dart';
import 'category_form_screen.dart';
import 'category_style.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

// ─── Categorías ───────────────────────────────────────────────────────────────
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  // GASTO o INGRESO; las de tipo AMBOS aparecen en las dos pestañas
  String _tipo = 'GASTO';

  void _openForm([Categoria? c]) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryFormScreen(categoria: c, tipoInicial: _tipo),
    ),
  );

  void _onTap(Categoria c) {
    if (c.usuarioId != null) {
      _openForm(c);
      return;
    }
    showBrandSnack(
      context,
      'Las categorías predeterminadas no se pueden editar. Crea una propia '
      'si necesitas otra.',
      error: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categoriesNotifierProvider);
    final trans = ref.watch(transactionsNotifierProvider).valueOrNull ?? const [];
    final mes = DateFormat('MMMM', 'es_ES').format(DateTime.now());

    // Movimientos y total del mes por categoría, solo del tipo de la pestaña
    // (una categoría AMBOS muestra sus gastos en una y sus ingresos en otra)
    final now = DateTime.now();
    final count = <int, int>{};
    final total = <int, double>{};
    for (final t in trans) {
      final id = t.categoriaId;
      final f = t.fechaTransaccion;
      if (id == null || t.tipoNombre != _tipo) continue;
      if (f.year != now.year || f.month != now.month) continue;
      count[id] = (count[id] ?? 0) + 1;
      total[id] = (total[id] ?? 0) + t.monto;
    }

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () async {
            await Future.wait([
              ref.read(categoriesNotifierProvider.notifier).refresh(),
              ref.read(transactionsNotifierProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Categorías', style: Brand.title(size: 22)),
                  ),
                  Material(
                    color: Brand.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _openForm(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          semanticLabel: 'Nueva categoría',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...async.when(
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Brand.accent,
                      ),
                    ),
                  ),
                ],
                error: (_, __) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(
                      'No se pudieron cargar las categorías. Desliza hacia '
                      'abajo para reintentar.',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 14, color: Brand.muted),
                    ),
                  ),
                ],
                data: (all) {
                  final activas = all.where((c) => c.activo).toList();
                  bool of(Categoria c, String tipo) =>
                      c.tipo == tipo || c.tipo == 'AMBOS';
                  final gastos = activas.where((c) => of(c, 'GASTO')).length;
                  final ingresos = activas.where((c) => of(c, 'INGRESO')).length;

                  // Primero las que más se usaron este mes
                  final list = activas.where((c) => of(c, _tipo)).toList()
                    ..sort((a, b) {
                      final byTotal = (total[b.id] ?? 0).compareTo(total[a.id] ?? 0);
                      return byTotal != 0
                          ? byTotal
                          : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
                    });

                  return [
                    _Segmented(
                      value: _tipo,
                      gastos: gastos,
                      ingresos: ingresos,
                      onChanged: (t) => setState(() => _tipo = t),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _ColumnLabel('Categoría')),
                        _ColumnLabel(mes),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Aún no hay categorías de este tipo.',
                          textAlign: TextAlign.center,
                          style: Brand.text(size: 14, color: Brand.muted),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: Brand.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Brand.border),
                        ),
                        child: Column(
                          children: [
                            for (final (i, c) in list.indexed) ...[
                              if (i > 0) const Divider(height: 1, color: Brand.border),
                              _CategoryRow(
                                c: c,
                                count: count[c.id] ?? 0,
                                total: total[c.id] ?? 0,
                                onTap: () => _onTap(c),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _DashedButton(
                      label: 'Crear categoría personalizada',
                      onTap: () => _openForm(),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Componentes ──────────────────────────────────────────────────────────────
class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Brand.text(
        size: 12,
        weight: FontWeight.w700,
        color: Brand.muted,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.gastos,
    required this.ingresos,
    required this.onChanged,
  });

  final String value;
  final int gastos;
  final int ingresos;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String v, String label) {
      final on = v == value;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Brand.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: on
                    ? const [
                        BoxShadow(
                          color: Color(0x1410201B),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: Brand.text(
                  size: 14,
                  weight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? Brand.ink : Brand.muted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Brand.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          seg('GASTO', 'Gastos · $gastos'),
          const SizedBox(width: 4),
          seg('INGRESO', 'Ingresos · $ingresos'),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.c,
    required this.count,
    required this.total,
    required this.onTap,
  });

  final Categoria c;
  final int count;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = categoryColors(c.color, c.tipo);
    final propia = c.usuarioId != null;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon(c.icono), size: 18, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.text(size: 14, weight: FontWeight.w700),
                        ),
                      ),
                      if (propia) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE8F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PROPIA',
                            style: Brand.text(
                              size: 10,
                              weight: FontWeight.w800,
                              color: const Color(0xFF6B3FA0),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 1 ? '1 movimiento' : '$count movimientos',
                    style: Brand.text(size: 12, color: Brand.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _money.format(total),
              style: Brand.text(
                size: 14,
                weight: FontWeight.w700,
                color: total == 0 ? Brand.muted : Brand.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Brand.ink),
              const SizedBox(width: 8),
              Text(label, style: Brand.text(size: 14, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = const Color(0xFFC9CFC6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
