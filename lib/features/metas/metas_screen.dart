import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import 'metas_provider.dart';
import 'create_meta_screen.dart';
import 'aporte_meta_dialog.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color primary = Color(0xFF1E2340);
  static const Color accent = Color(0xFF5B5FEE);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textSub = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
IconData _iconData(String? name) {
  const map = {
    'flag': Icons.flag_rounded,
    'home': Icons.home_rounded,
    'directions_car': Icons.directions_car_rounded,
    'flight': Icons.flight_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'school': Icons.school_rounded,
    'favorite': Icons.favorite_rounded,
    'savings': Icons.savings_rounded,
    'work': Icons.work_rounded,
    'celebration': Icons.celebration_rounded,
    'star': Icons.star_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'beach_access': Icons.beach_access_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'restaurant': Icons.restaurant_rounded,
    'music_note': Icons.music_note_rounded,
  };
  return map[name] ?? Icons.flag_rounded;
}

Color _parseColor(String? h) {
  if (h == null || h.isEmpty) return _C.accent;
  try {
    return Color(int.parse(h.replaceFirst('#', '0xFF')));
  } catch (_) {
    return _C.accent;
  }
}

// ─── Metas Screen ─────────────────────────────────────────────────────────────
class MetasScreen extends ConsumerStatefulWidget {
  const MetasScreen({super.key});

  @override
  ConsumerState<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends ConsumerState<MetasScreen>
    with SingleTickerProviderStateMixin {
  String _filter = 'ACTIVAS';
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reinitialize if needed during hot reload
    if (_fabAnim.isDismissed) {
      _fabAnim = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      )..forward();
    }
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metasAsync = ref.watch(metasNotifierProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            color: _C.surface,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _C.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: _C.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Metas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Alcanza tus objetivos',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _C.textSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _fabAnim,
                    curve: Curves.elasticOut,
                  ),
                  child: GestureDetector(
                    onTap: () => _navigateToCreate(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _C.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filtros ──────────────────────────────────────────────────
          Container(
            color: _C.surface,
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 16,
              top: 4,
            ),
            child: Row(
              children: [
                _FilterPill(
                  label: 'Activas',
                  selected: _filter == 'ACTIVAS',
                  onTap: () => setState(() => _filter = 'ACTIVAS'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Completadas',
                  selected: _filter == 'COMPLETADAS',
                  onTap: () => setState(() => _filter = 'COMPLETADAS'),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Todas',
                  selected: _filter == 'TODAS',
                  onTap: () => setState(() => _filter = 'TODAS'),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────────────────
          Expanded(
            child: metasAsync.when(
              data: (metas) {
                final filtered = _filtrar(metas, _filter);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    filter: _filter,
                    onAdd: () => _navigateToCreate(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(metasNotifierProvider.notifier).refresh(),
                  color: _C.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + i * 40),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, child) => Opacity(
                        opacity: val,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - val)),
                          child: child,
                        ),
                      ),
                      child: _MetaCard(
                        meta: filtered[i],
                        onTap: () => _showOptions(context, filtered[i]),
                        onAporte: () => _mostrarAporte(context, filtered[i]),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: _C.accent,
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => _ErrorState(
                error: e.toString(),
                onRetry: () =>
                    ref.read(metasNotifierProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Meta> _filtrar(List<Meta> metas, String f) {
    switch (f) {
      case 'ACTIVAS':
        return metas.where((m) => m.activa && !m.estaCompletada).toList();
      case 'COMPLETADAS':
        return metas.where((m) => m.estaCompletada).toList();
      default:
        return metas;
    }
  }

  void _navigateToCreate(BuildContext context, [Meta? meta]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateMetaScreen(metaToEdit: meta)),
    );
  }

  void _mostrarAporte(BuildContext context, Meta meta) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      useRootNavigator: true,
      builder: (_) => AporteMetaDialog(meta: meta),
    );
  }

  void _showOptions(BuildContext context, Meta meta) {
    final color = _parseColor(meta.color);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Meta header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconData(meta.icono),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                          ),
                          Text(
                            'Opciones',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _C.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(meta: meta),
                  ],
                ),
              ),
              Container(height: 1, color: _C.divider),
              const SizedBox(height: 8),
              // Opciones
              _SheetOption(
                icon: Icons.south_rounded,
                iconColor: _C.accent,
                title: 'Hacer Aporte',
                subtitle: 'Agregar fondos a esta meta',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _mostrarAporte(context, meta);
                  });
                },
              ),
              _SheetOption(
                icon: Icons.edit_rounded,
                iconColor: _C.success,
                title: 'Editar Meta',
                subtitle: 'Modificar detalles',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _navigateToCreate(context, meta);
                  });
                },
              ),
              _SheetOption(
                icon: meta.activa
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                iconColor: _C.warning,
                title: meta.activa ? 'Pausar Meta' : 'Activar Meta',
                subtitle: meta.activa
                    ? 'Pausar temporalmente'
                    : 'Reactivar la meta',
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(metasNotifierProvider.notifier)
                      .toggleActiva(meta.id, !meta.activa);
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 1,
                color: _C.divider,
              ),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                iconColor: _C.danger,
                title: 'Eliminar Meta',
                subtitle: 'Eliminar permanentemente',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminacion(context, meta);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, Meta meta) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final color = _parseColor(meta.color);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _C.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: _C.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Eliminar meta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconData(meta.icono),
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.nombre,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.primary,
                              ),
                            ),
                            Text(
                              '${fmt.format(meta.montoActual)} / ${fmt.format(meta.montoObjetivo)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: _C.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _C.warning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _C.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se eliminarán todos los aportes registrados. Esta acción no se puede deshacer.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF92400E),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.border),
                          ),
                          child: Center(
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.textSub,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          try {
                            await ref
                                .read(metasNotifierProvider.notifier)
                                .deleteMeta(meta.id);
                            if (context.mounted) {
                              _showSnack(context, 'Meta eliminada', _C.success);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showSnack(
                                context,
                                e.toString().replaceFirst('Exception: ', ''),
                                _C.danger,
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: _C.danger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Eliminar',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── Filter pill ──────────────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _C.accent : _C.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? _C.accent : _C.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _C.textSub,
        ),
      ),
    ),
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final Meta meta;
  const _StatusBadge({required this.meta});

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late Color color;
    late String label;

    if (meta.estaCompletada) {
      icon = Icons.check_circle_rounded;
      color = _C.success;
      label = 'Completada';
    } else if (!meta.activa) {
      icon = Icons.pause_circle_rounded;
      color = _C.warning;
      label = 'Pausada';
    } else if (meta.estaVencida) {
      icon = Icons.error_rounded;
      color = _C.danger;
      label = 'Vencida';
    } else {
      icon = Icons.play_circle_rounded;
      color = _C.accent;
      label = 'Activa';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta Card ────────────────────────────────────────────────────────────────
class _MetaCard extends StatelessWidget {
  final Meta meta;
  final VoidCallback onTap;
  final VoidCallback onAporte;

  const _MetaCard({
    required this.meta,
    required this.onTap,
    required this.onAporte,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(meta.color);
    final barColor = meta.estaCompletada ? _C.success : color;
    final fmt = NumberFormat('#,###', 'es_CO');
    final pct = meta.porcentajeCompletado.clamp(0.0, 100.0);
    final diasRestantes = meta.fechaObjetivo.difference(DateTime.now()).inDays;
    final canAporte = !meta.estaCompletada && !meta.estaVencida && meta.activa;
    final faltante = meta.montoObjetivo - meta.montoActual;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera tintada ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_iconData(meta.icono), color: color, size: 21),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                          ),
                          if (meta.descripcion != null &&
                              meta.descripcion!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              meta.descripcion!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: _C.textSub,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(meta: meta),
                  ],
                ),
              ),

              // ── Progreso ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _C.textSub,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Barra animada
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: pct / 100),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              color: barColor.withValues(alpha: 0.1),
                            ),
                            FractionallySizedBox(
                              widthFactor: val,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Montos ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _AmountStat(
                        label: 'Ahorrado',
                        value: '\$${fmt.format(meta.montoActual.toInt())}',
                        valueColor: barColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: _C.border.withValues(alpha: 0.6),
                    ),
                    Expanded(
                      child: _AmountStat(
                        label: 'Objetivo',
                        value: '\$${fmt.format(meta.montoObjetivo.toInt())}',
                        valueColor: _C.primary,
                        align: CrossAxisAlignment.center,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: _C.border.withValues(alpha: 0.6),
                    ),
                    Expanded(
                      child: _AmountStat(
                        label: 'Faltante',
                        value: faltante > 0
                            ? '\$${fmt.format(faltante.toInt())}'
                            : '¡Listo!',
                        valueColor:
                            faltante > 0 ? _C.textSub : _C.success,
                        align: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Footer ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: (meta.estaCompletada
                                ? _C.success
                                : meta.estaVencida
                                ? _C.danger
                                : _C.textSub)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            meta.estaCompletada
                                ? Icons.check_circle_outline_rounded
                                : Icons.calendar_today_rounded,
                            size: 12,
                            color: meta.estaCompletada
                                ? _C.success
                                : meta.estaVencida
                                ? _C.danger
                                : _C.textSub,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            meta.estaCompletada
                                ? '¡Meta alcanzada!'
                                : meta.estaVencida
                                ? 'Vencida'
                                : diasRestantes == 0
                                ? 'Hoy vence'
                                : '$diasRestantes días',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: meta.estaCompletada
                                  ? _C.success
                                  : meta.estaVencida
                                  ? _C.danger
                                  : _C.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (canAporte)
                      GestureDetector(
                        onTap: onAporte,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'Aportar',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;
  const _AmountStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: align == CrossAxisAlignment.end ? 12 : 0,
      right: align == CrossAxisAlignment.start ? 12 : 0,
    ),
    child: Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: _C.textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    ),
  );
}

// ─── Sheet option ─────────────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive ? _C.danger : iconColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: effectiveColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? _C.danger : _C.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _C.textSub,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: _C.border),
          ],
        ),
      ),
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onAdd;
  const _EmptyState({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final msg = filter == 'COMPLETADAS'
        ? 'Sin metas completadas'
        : 'No tienes metas aún';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _C.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                size: 38,
                color: _C.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              msg,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera meta y comienza\na alcanzar tus objetivos',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _C.textSub,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _C.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Crear Meta',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.danger.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 38,
              color: _C.danger,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Error al cargar metas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _C.textSub,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reintentar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
