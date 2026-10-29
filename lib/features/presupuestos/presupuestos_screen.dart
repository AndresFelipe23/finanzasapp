import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/presupuesto_models.dart';
import '../../core/theme/brand.dart';
import '../categories/categories_provider.dart';
import 'create_edit_presupuesto_screen.dart';
import 'presupuestos_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

// Ámbar del diseño para "cerca del límite" (≥ 85%)
const _warn = Color(0xFFA86A0C);

const _periodoLabels = {
  'SEMANAL': 'Semanal',
  'MENSUAL': 'Mensual',
  'ANUAL': 'Anual',
  'PERSONALIZADO': 'Personalizado',
};

// ─── Presupuestos ─────────────────────────────────────────────────────────────
class PresupuestosScreen extends ConsumerStatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  ConsumerState<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends ConsumerState<PresupuestosScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get _monthEnd => DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  /// Presupuestos cuyo periodo se cruza con el mes elegido.
  List<Presupuesto> _forMonth(List<Presupuesto> all) => all
      .where(
        (p) => !p.fechaInicio.isAfter(_monthEnd) && !p.fechaFin.isBefore(_month),
      )
      .toList();

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _openForm([Presupuesto? p]) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CreateEditPresupuestoScreen(presupuesto: p),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(presupuestosNotifierProvider);
    final categorias = <int, String>{
      for (final c in ref.watch(categoriesNotifierProvider).valueOrNull ?? const [])
        c.id: c.nombre,
    };

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () =>
              ref.read(presupuestosNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Presupuestos', style: Brand.title(size: 22)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MonthPicker(
                month: _month,
                onPrev: () => _shift(-1),
                onNext: () => _shift(1),
              ),
              const SizedBox(height: 18),
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
                  const _Message(
                    icon: Icons.wifi_off_rounded,
                    title: 'No se pudieron cargar tus presupuestos',
                    body: 'Revisa tu conexión y desliza hacia abajo para '
                        'reintentar.',
                  ),
                ],
                data: (all) => _content(_forMonth(all), categorias),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(List<Presupuesto> items, Map<int, String> categorias) {
    final activos = items.where((p) => p.activo).toList()
      ..sort((a, b) => b.porcentaje.compareTo(a.porcentaje));
    final pausados = items.where((p) => !p.activo).toList();

    final header = Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text('Por categoría', style: Brand.text(weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => _openForm(),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(
              '+ Agregar',
              style: Brand.text(
                size: 13,
                weight: FontWeight.w700,
                color: Brand.accent,
              ),
            ),
          ),
        ],
      ),
    );

    if (items.isEmpty) {
      return [
        _Message(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Sin presupuestos este mes',
          body: 'Ponle un límite a una categoría y te avisaremos antes de '
              'que te pases.',
          action: BrandButton(
            label: 'Crear presupuesto',
            onPressed: () => _openForm(),
          ),
        ),
      ];
    }

    Widget row(Presupuesto p) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _BudgetRow(
        p: p,
        categoria: p.categoriaId == null ? null : categorias[p.categoriaId],
        onTap: () => _showOptions(p),
      ),
    );

    return [
      _Summary(
        items: activos,
        month: _month,
        isCurrentMonth: _isCurrentMonth,
      ),
      header,
      if (activos.isEmpty)
        Text(
          'Todos los presupuestos de este mes están pausados.',
          style: Brand.text(size: 13, color: Brand.muted),
        ),
      ...activos.map(row),
      if (pausados.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Text(
            'PAUSADOS · ${pausados.length}',
            style: Brand.text(
              size: 12,
              weight: FontWeight.w700,
              color: Brand.muted,
              letterSpacing: 0.7,
            ),
          ),
        ),
        ...pausados.map(row),
      ],
    ];
  }

  void _showOptions(Presupuesto p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        Widget option(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) {
          final color = danger ? Brand.expense : Brand.ink;
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(label,
                style: Brand.text(weight: FontWeight.w600, color: color)),
            onTap: () {
              Navigator.pop(sheetCtx);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Brand.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Text(p.nombre,
                      style: Brand.text(size: 18, weight: FontWeight.w800)),
                ),
                option(Icons.edit_outlined, 'Editar presupuesto',
                    () => _openForm(p)),
                option(
                  p.activo
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  p.activo ? 'Pausar' : 'Reanudar',
                  () => _run(
                    () => ref
                        .read(presupuestosNotifierProvider.notifier)
                        .toggle(p.id, !p.activo),
                  ),
                ),
                option(Icons.delete_outline_rounded, 'Eliminar',
                    () => _confirmDelete(p), danger: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _confirmDelete(Presupuesto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Eliminar "${p.nombre}"?',
            style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'Tus movimientos no se borran; solo deja de existir el límite.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: Brand.text(weight: FontWeight.w700, color: Brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.expense),
            child: Text('Eliminar',
                style: Brand.text(weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(
        () => ref.read(presupuestosNotifierProvider.notifier).delete(p.id),
      );
    }
  }
}

// ─── Componentes ──────────────────────────────────────────────────────────────
class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', 'es_ES').format(month);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left_rounded, color: Brand.ink),
          ),
          Expanded(
            child: Text(
              label[0].toUpperCase() + label.substring(1),
              textAlign: TextAlign.center,
              style: Brand.text(weight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right_rounded, color: Brand.ink),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.items,
    required this.month,
    required this.isCurrentMonth,
  });

  final List<Presupuesto> items;
  final DateTime month;
  final bool isCurrentMonth;

  String _hint() {
    final now = DateTime.now();
    if (isCurrentMonth) {
      final left = DateTime(now.year, now.month + 1, 0).day - now.day;
      return switch (left) {
        0 => 'último día del mes',
        1 => 'queda 1 día',
        _ => 'quedan $left días',
      };
    }
    return month.isBefore(DateTime(now.year, now.month))
        ? 'mes cerrado'
        : 'aún no empieza';
  }

  @override
  Widget build(BuildContext context) {
    final limite = items.fold<double>(0, (s, p) => s + p.montoLimite);
    final gastado = items.fold<double>(0, (s, p) => s + p.montoGastado);
    final ratio = limite <= 0 ? 0.0 : gastado / limite;
    final over = ratio > 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _RingPainter(
                math.min(ratio, 1),
                over ? Brand.peach : Brand.mint,
              ),
              child: Center(
                child: Text(
                  '${(ratio * 100).round()}%',
                  style: Brand.text(
                    size: 18,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentMonth ? 'Gastado este mes' : 'Gastado',
                  style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _money.format(gastado),
                    style: Brand.text(
                      size: 24,
                      weight: FontWeight.w800,
                      color: over ? Brand.peach : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'de ${_money.format(limite)} · ${_hint()}',
                  style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFF22352E);
    canvas.drawCircle(center, radius, paint);
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.p, required this.categoria, required this.onTap});

  final Presupuesto p;
  final String? categoria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = p.porcentaje;
    final over = p.sobrepasado;
    final warn = !over && pct >= 85;
    final color = !p.activo
        ? Brand.muted
        : over
        ? Brand.expense
        : warn
        ? _warn
        : Brand.accent;
    final meta = [
      if (categoria != null && categoria != p.nombre) categoria!,
      if (p.periodo != 'MENSUAL') _periodoLabels[p.periodo] ?? p.periodo,
    ].join(' · ');

    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.text(
                            size: 14,
                            weight: FontWeight.w700,
                            color: p.activo ? Brand.ink : Brand.muted,
                          ),
                        ),
                        if (meta.isNotEmpty)
                          Text(meta,
                              style: Brand.text(size: 12, color: Brand.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _money.format(p.montoGastado),
                          style: Brand.text(
                            size: 14,
                            weight: FontWeight.w700,
                            color: over && p.activo ? Brand.expense : Brand.ink,
                          ),
                        ),
                        TextSpan(text: ' / ${_money.format(p.montoLimite)}'),
                      ],
                    ),
                    style: Brand.text(size: 14, color: Brand.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: math.min(pct / 100, 1),
                  minHeight: 8,
                  color: color,
                  backgroundColor: Brand.track,
                ),
              ),
              if (over && p.activo) ...[
                const SizedBox(height: 8),
                Text(
                  'Excedido por ${_money.format(p.montoGastado - p.montoLimite)}',
                  style: Brand.text(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Brand.expense,
                  ),
                ),
              ] else if (warn && p.activo) ...[
                const SizedBox(height: 8),
                Text(
                  'Quedan ${_money.format(p.montoLimite - p.montoGastado)}',
                  style: Brand.text(size: 12, weight: FontWeight.w700, color: _warn),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 44, color: Brand.inputBorder),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Brand.text(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Brand.text(size: 13, color: Brand.muted, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
