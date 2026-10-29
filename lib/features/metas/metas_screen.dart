import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import '../../core/theme/brand.dart';
import 'aporte_meta_dialog.dart';
import 'create_meta_screen.dart';
import 'metas_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

// Colores de las metas, en el orden en que se asignan
const _palette = [
  (Brand.accent, Brand.accentSoft),
  (Brand.blue, Brand.blueSoft),
  (Color(0xFF6B3FA0), Color(0xFFEEE8F5)),
  (Brand.expense, Brand.expenseSoft),
];

/// Meses completos entre hoy y la fecha objetivo (mínimo 1).
int _monthsLeft(DateTime target) {
  final now = DateTime.now();
  final months = (target.year - now.year) * 12 + target.month - now.month;
  return months < 1 ? 1 : months;
}

/// Lo que hay que ahorrar cada mes para llegar a tiempo.
double _monthlyNeeded(Meta m) =>
    m.estaCompletada || m.estaVencida ? 0 : m.faltante / _monthsLeft(m.fechaObjetivo);

// ─── Metas ────────────────────────────────────────────────────────────────────
class MetasScreen extends ConsumerWidget {
  const MetasScreen({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metasAsync = ref.watch(metasNotifierProvider);

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () => ref.read(metasNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Metas', style: Brand.title(size: 26))),
                  _PillButton(
                    label: 'Nueva meta',
                    onTap: () => _push(context, const CreateMetaScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...metasAsync.when(
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
                    title: 'No se pudieron cargar tus metas',
                    body: 'Revisa tu conexión y desliza hacia abajo para '
                        'reintentar.',
                  ),
                ],
                data: (metas) => _content(context, ref, metas),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, List<Meta> metas) {
    if (metas.isEmpty) {
      return [
        const _Message(
          icon: Icons.track_changes_rounded,
          title: 'Aún no tienes metas',
          body: 'Ahorra para un viaje, un fondo de emergencia o lo que '
              'quieras. Toca "Nueva meta" para empezar.',
        ),
      ];
    }

    final enCurso = metas
        .where((m) => m.activa && !m.estaCompletada)
        .toList()
      ..sort((a, b) => a.fechaObjetivo.compareTo(b.fechaObjetivo));
    final cumplidas = metas.where((m) => m.estaCompletada).toList();
    final pausadas = metas
        .where((m) => !m.activa && !m.estaCompletada)
        .toList();

    final ahorrado = metas.fold<double>(0, (s, m) => s + m.montoActual);
    final mensual = enCurso.fold<double>(0, (s, m) => s + _monthlyNeeded(m));

    // El color se asigna por posición en la lista completa para que sea estable
    (Color, Color) colorOf(Meta m) =>
        _palette[metas.indexOf(m) % _palette.length];

    Widget section(String title, List<Meta> items) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        '${title.toUpperCase()} · ${items.length}',
        style: Brand.text(
          size: 12,
          weight: FontWeight.w700,
          color: Brand.muted,
          letterSpacing: 0.7,
        ),
      ),
    );

    Widget card(Meta m) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GoalCard(
        meta: m,
        colors: colorOf(m),
        onContribute: () => showDialog(
          context: context,
          useRootNavigator: true,
          builder: (_) => AporteMetaDialog(meta: m),
        ),
        onOptions: () => _showOptions(context, ref, m),
      ),
    );

    return [
      Row(
        children: [
          Expanded(
            child: _StatTile(label: 'Total ahorrado', value: _money.format(ahorrado)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              label: 'Aporte mensual',
              value: _money.format(mensual),
              hint: 'para llegar a tiempo',
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      ...enCurso.map(card),
      if (cumplidas.isNotEmpty) ...[
        section('Cumplidas', cumplidas),
        ...cumplidas.map(card),
      ],
      if (pausadas.isNotEmpty) ...[
        section('Pausadas', pausadas),
        ...pausadas.map(card),
      ],
    ];
  }

  void _showOptions(BuildContext context, WidgetRef ref, Meta m) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        Widget option(IconData icon, Color color, String label, VoidCallback onTap) =>
            ListTile(
              leading: Icon(icon, color: color),
              title: Text(
                label,
                style: Brand.text(
                  weight: FontWeight.w600,
                  color: color == Brand.expense ? Brand.expense : Brand.ink,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                onTap();
              },
            );

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
                  child: Text(
                    m.nombre,
                    style: Brand.text(size: 18, weight: FontWeight.w800),
                  ),
                ),
                option(Icons.edit_outlined, Brand.ink, 'Editar meta',
                    () => _push(context, CreateMetaScreen(metaToEdit: m))),
                if (!m.estaCompletada)
                  option(
                    m.activa
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    Brand.ink,
                    m.activa ? 'Pausar meta' : 'Reanudar meta',
                    () => ref
                        .read(metasNotifierProvider.notifier)
                        .toggleActiva(m.id, !m.activa),
                  ),
                option(Icons.delete_outline_rounded, Brand.expense,
                    'Eliminar meta', () => _confirmDelete(context, ref, m)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Meta m) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Eliminar "${m.nombre}"?',
          style: Brand.text(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          m.montoActual > 0
              ? 'Llevas ${_money.format(m.montoActual)} ahorrados en esta meta. '
                    'Esta acción no se puede deshacer.'
              : 'Esta acción no se puede deshacer.',
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
    if (ok != true) return;
    try {
      await ref.read(metasNotifierProvider.notifier).deleteMeta(m.id);
    } catch (e) {
      if (context.mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }
}

// ─── Componentes ──────────────────────────────────────────────────────────────
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.ink,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: Brand.text(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Brand.text(size: 12, color: Brand.muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Brand.text(size: 20, weight: FontWeight.w800),
            ),
          ),
          if (hint != null)
            Text(hint!, style: Brand.text(size: 11, color: Brand.muted)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.meta,
    required this.colors,
    required this.onContribute,
    required this.onOptions,
  });

  final Meta meta;
  final (Color, Color) colors;
  final VoidCallback onContribute;
  final VoidCallback onOptions;

  String _subtitle() {
    final m = meta;
    final fecha = DateFormat('MMM yyyy', 'es_ES').format(m.fechaObjetivo);
    if (m.estaCompletada) return '¡Meta cumplida! · $fecha';
    if (!m.activa) return 'En pausa · Meta: $fecha';
    if (m.estaVencida) return 'Venció en $fecha · faltan ${_money.format(m.faltante)}';
    return 'Meta: $fecha · ${_money.format(_monthlyNeeded(m))}/mes';
  }

  @override
  Widget build(BuildContext context) {
    final m = meta;
    final (fg, bg) = m.activa || m.estaCompletada
        ? colors
        : (Brand.muted, Brand.track);
    final pct = m.porcentajeCompletado.round();
    final late = m.estaVencida && !m.estaCompletada;

    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: onOptions,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: m.estaCompletada
                        ? Icon(Icons.check_rounded, color: fg, size: 24)
                        : Text(
                            '$pct%',
                            style: Brand.text(
                              size: 14,
                              weight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.text(size: 16, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(),
                          style: Brand.text(
                            size: 12,
                            color: late ? Brand.expense : Brand.muted,
                            weight: late ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, color: Brand.muted),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: m.porcentajeCompletado / 100,
                  minHeight: 10,
                  color: fg,
                  backgroundColor: Brand.track,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _money.format(m.montoActual),
                            style: Brand.text(size: 13, weight: FontWeight.w700),
                          ),
                          TextSpan(text: ' de ${_money.format(m.montoObjetivo)}'),
                        ],
                      ),
                      style: Brand.text(size: 13, color: Brand.muted),
                    ),
                  ),
                  if (m.activa && !m.estaCompletada)
                    OutlinedButton(
                      onPressed: onContribute,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Brand.bg,
                        foregroundColor: Brand.ink,
                        side: const BorderSide(color: Brand.border),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Abonar',
                        style: Brand.text(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 64, 12, 32),
      child: Column(
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
        ],
      ),
    );
  }
}
