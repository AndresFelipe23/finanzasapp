import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/prestamo_models.dart';
import 'prestamos_provider.dart';
import 'create_edit_prestamo_screen.dart';
import 'pago_prestamo_dialog.dart';

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

class PrestamosScreen extends ConsumerStatefulWidget {
  const PrestamosScreen({super.key});

  @override
  ConsumerState<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends ConsumerState<PrestamosScreen> {
  String _filtro = 'ACTIVOS'; // ACTIVOS, PAUSADOS, COMPLETADOS, TODOS

  @override
  Widget build(BuildContext context) {
    final prestamosAsync = ref.watch(prestamosNotifierProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── Cabecera + filtros (bloque superior unificado) ──────────
          Material(
            color: _C.surface,
            elevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _C.border.withValues(alpha: 0.6)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 8,
                      right: 20,
                      bottom: 18,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Volver',
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: _C.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _C.accent.withValues(alpha: 0.18),
                                _C.accent.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _C.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: _C.accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mis préstamos',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _C.primary,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Deudas, créditos y seguimiento en un solo lugar',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: _C.textSub,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 2,
                          shadowColor: _C.accent.withValues(alpha: 0.45),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CreateEditPrestamoScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(
                              width: 50,
                              height: 50,
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 0,
                      right: 0,
                      bottom: 14,
                    ),
                    child: _buildChipsFiltro(),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista + resumen contextual ─────────────────────────────
          Expanded(
            child: prestamosAsync.when(
              data: (items) {
                final filtrados = _aplicarFiltro(items);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _ResumenPrestamos(items: items),
                      ),
                    Expanded(
                      child: filtrados.isEmpty
                          ? _EmptyState(filtro: _filtro)
                          : RefreshIndicator(
                              onRefresh: () async => ref
                                  .read(prestamosNotifierProvider.notifier)
                                  .refresh(),
                              color: _C.accent,
                              edgeOffset: 8,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  items.isNotEmpty ? 16 : 20,
                                  20,
                                  100,
                                ),
                                itemCount: filtrados.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (_, i) =>
                                    TweenAnimationBuilder<double>(
                                  duration: Duration(
                                    milliseconds: 280 + i * 36,
                                  ),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, val, child) => Opacity(
                                    opacity: val,
                                    child: Transform.translate(
                                      offset: Offset(0, 12 * (1 - val)),
                                      child: child,
                                    ),
                                  ),
                                  child: _PrestamoCard(
                                    prestamo: filtrados[i],
                                    onPago: () =>
                                        _mostrarPago(context, filtrados[i]),
                                    onToggle: () => ref
                                        .read(
                                          prestamosNotifierProvider.notifier,
                                        )
                                        .toggle(
                                          filtrados[i].id,
                                          !filtrados[i].activa,
                                        ),
                                    onDelete: () => _confirmarEliminacion(
                                      context,
                                      filtrados[i],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const _LoadingPrestamosState(),
              error: (e, _) => _ErrorState(
                error: e.toString(),
                onRetry: () =>
                    ref.read(prestamosNotifierProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarPago(BuildContext context, Prestamo prestamo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      useRootNavigator: false,
      builder: (_) => PagoPrestamoDialog(prestamo: prestamo),
    );
  }

  void _confirmarEliminacion(BuildContext context, Prestamo prestamo) {
    final formato = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
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
                        'Eliminar préstamo',
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
                          color: prestamo.tipo == 'DEUDA'
                              ? _C.danger.withValues(alpha: 0.1)
                              : _C.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          prestamo.tipo == 'DEUDA'
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: prestamo.tipo == 'DEUDA'
                              ? _C.danger
                              : _C.success,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prestamo.nombre,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.primary,
                              ),
                            ),
                            Text(
                              formato.format(prestamo.montoTotal),
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
                          'Se eliminarán todos los pagos registrados. Esta acción no se puede deshacer.',
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
                                .read(prestamosNotifierProvider.notifier)
                                .delete(prestamo.id);
                            if (context.mounted) {
                              _showSnack(
                                context,
                                'Préstamo eliminado',
                                _C.success,
                              );
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

  List<Prestamo> _aplicarFiltro(List<Prestamo> items) {
    switch (_filtro) {
      case 'ACTIVOS':
        return items.where((p) => p.activa && !p.estaPagado).toList();
      case 'PAUSADOS':
        return items.where((p) => !p.activa && !p.estaPagado).toList();
      case 'COMPLETADOS':
        return items.where((p) => p.estaCompletado).toList();
      case 'PAGADOS':
        return items.where((p) => p.estaPagado).toList();
      default:
        return items;
    }
  }

  Widget _buildChipsFiltro() {
    const chips = <(String, String)>[
      ('ACTIVOS', 'Activos'),
      ('PAUSADOS', 'Pausados'),
      ('PAGADOS', 'Pagados'),
      ('COMPLETADOS', 'Completados'),
      ('TODOS', 'Todos'),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _FiltroChip(
                label: chips[i].$2,
                selected: _filtro == chips[i].$1,
                onSelected: () => setState(() => _filtro = chips[i].$1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _C.accent : _C.bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _C.accent : _C.border,
            width: selected ? 1.2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _C.accent.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _C.textSub,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

// ─── Resumen KPIs ────────────────────────────────────────────────────────────
class _ResumenPrestamos extends StatelessWidget {
  final List<Prestamo> items;
  const _ResumenPrestamos({required this.items});

  @override
  Widget build(BuildContext context) {
    final activos = items.where((p) => p.activa && !p.estaPagado).length;
    final noPagados = items.where((p) => !p.estaPagado);
    final pendiente =
        noPagados.fold<double>(0, (s, p) => s + p.saldoPendiente);
    final deudaPend = items
        .where((p) => p.tipo == 'DEUDA' && !p.estaPagado)
        .fold<double>(0, (s, p) => s + p.saldoPendiente);
    final creditoPend = items
        .where((p) => p.tipo == 'PRESTAMO' && !p.estaPagado)
        .fold<double>(0, (s, p) => s + p.saldoPendiente);
    final fmt = NumberFormat('#,###', 'es_CO');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _C.primary,
            Color.lerp(_C.primary, _C.accent, 0.12)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Resumen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _KpiPill(
                  label: 'Activos',
                  value: '$activos',
                  hint: 'en seguimiento',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _KpiPill(
                  label: 'Saldo pendiente',
                  value: '\$${fmt.format(pendiente.round())}',
                  hint: 'total por liquidar',
                ),
              ),
            ],
          ),
          if (deudaPend > 0.01 || creditoPend > 0.01) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniFlow(
                    label: 'Yo debo',
                    amount: '\$${fmt.format(deudaPend.round())}',
                    color: const Color(0xFFFFB4B4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniFlow(
                    label: 'Me deben',
                    amount: '\$${fmt.format(creditoPend.round())}',
                    color: const Color(0xFFB8F5C8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  const _KpiPill({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            hint,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFlow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  const _MiniFlow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

class _LoadingPrestamosState extends StatelessWidget {
  const _LoadingPrestamosState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: _C.accent,
              strokeWidth: 2.8,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Cargando préstamos…',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Un momento mientras sincronizamos tus datos',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _C.textSub,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Prestamo Card ───────────────────────────────────────────────────────────
class _PrestamoCard extends StatelessWidget {
  final Prestamo prestamo;
  final VoidCallback onPago;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PrestamoCard({
    required this.prestamo,
    required this.onPago,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = prestamo.estaCompletado
        ? _C.success
        : (prestamo.estaPausado ? _C.warning : _C.accent);
    final formato = NumberFormat('#,###', 'es_CO');
    final pct = prestamo.montoTotal > 0
        ? ((prestamo.montoTotal - prestamo.saldoPendiente) /
              prestamo.montoTotal *
              100)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja lateral
              Container(width: 4, color: color),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top: icon + name + status
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              prestamo.tipo == 'DEUDA'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
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
                                  prestamo.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _C.primary,
                                  ),
                                ),
                                if (prestamo.notas != null &&
                                    prestamo.notas!.isNotEmpty)
                                  Text(
                                    prestamo.notas!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: _C.textSub,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(prestamo: prestamo),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Tipo badge + fechas
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: prestamo.tipo == 'DEUDA'
                                  ? _C.danger.withValues(alpha: 0.1)
                                  : _C.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              prestamo.tipo == 'DEUDA' ? 'Yo debo' : 'Me deben',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: prestamo.tipo == 'DEUDA'
                                    ? _C.danger
                                    : _C.success,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 14,
                                color: _C.textSub,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Inicio ${DateFormat('dd/MM/yyyy').format(prestamo.fechaInicio)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _C.textSub,
                                ),
                              ),
                            ],
                          ),
                          if (prestamo.tasaInteres != null &&
                              prestamo.tasaInteres! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _C.divider,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _C.border),
                              ),
                              child: Text(
                                '${prestamo.tasaInteres!.toStringAsFixed(1)}% interés',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Barra de progreso
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progreso',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _C.textSub,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: _C.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Montos
                      Row(
                        children: [
                          Expanded(
                            child: _AmountStat(
                              label: 'Saldo pendiente',
                              value:
                                  '\$${formato.format(prestamo.saldoPendiente.toInt())}',
                              valueColor: color,
                            ),
                          ),
                          Container(width: 1, height: 32, color: _C.divider),
                          Expanded(
                            child: _AmountStat(
                              label: 'Monto total',
                              value:
                                  '\$${formato.format(prestamo.montoTotal.toInt())}',
                              valueColor: _C.primary,
                              align: CrossAxisAlignment.end,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Container(height: 1, color: _C.divider),
                      const SizedBox(height: 12),

                      // Footer: acciones
                      Row(
                        children: [
                          if (!prestamo.estaPagado) ...[
                            Expanded(
                              flex: 2,
                              child: Material(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: onPago,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.payments_rounded,
                                          size: 18,
                                          color: color,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Registrar pago',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: prestamo.activa
                                  ? _C.warning.withValues(alpha: 0.12)
                                  : _C.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: onToggle,
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: Icon(
                                    prestamo.activa
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 22,
                                    color: prestamo.activa
                                        ? _C.warning
                                        : _C.success,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Material(
                            color: _C.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(14),
                              child: const SizedBox(
                                width: 46,
                                height: 46,
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: _C.danger,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final Prestamo prestamo;
  const _StatusBadge({required this.prestamo});

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late Color color;
    late String label;

    if (prestamo.estaCompletado) {
      icon = Icons.check_circle_rounded;
      color = _C.success;
      label = 'Completado';
    } else if (!prestamo.activa) {
      icon = Icons.pause_circle_rounded;
      color = _C.warning;
      label = 'Pausado';
    } else {
      icon = Icons.play_circle_rounded;
      color = _C.accent;
      label = 'Activo';
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

// ─── Amount stat ──────────────────────────────────────────────────────────────
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
      left: align == CrossAxisAlignment.start ? 0 : 12,
      right: align == CrossAxisAlignment.end ? 0 : 12,
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

// ─── Empty / Error states ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filtro;
  const _EmptyState({required this.filtro});

  (String titulo, String subtitulo, IconData icono) _copy() {
    switch (filtro) {
      case 'ACTIVOS':
        return (
          'Nada en activos',
          'Los préstamos activos aparecerán aquí. Prueba otro filtro o crea uno nuevo.',
          Icons.bolt_rounded,
        );
      case 'PAUSADOS':
        return (
          'Sin préstamos pausados',
          'Puedes pausar un préstamo desde la tarjeta cuando quieras congelar pagos.',
          Icons.pause_circle_outline_rounded,
        );
      case 'PAGADOS':
        return (
          'Sin préstamos pagados',
          'Cuando marques uno como pagado, lo verás en esta vista.',
          Icons.receipt_long_rounded,
        );
      case 'COMPLETADOS':
        return (
          'Aún sin completados',
          'Al saldar el saldo al 100%, el préstamo pasará a completado automáticamente.',
          Icons.task_alt_rounded,
        );
      case 'TODOS':
        return (
          'Empieza por aquí',
          'Registra deudas o créditos para ver progreso, pagos y resúmenes en un solo lugar.',
          Icons.account_balance_wallet_outlined,
        );
      default:
        return (
          'Sin resultados',
          'Prueba con otro filtro o crea un préstamo nuevo.',
          Icons.search_off_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (titulo, subtitulo, icono) = _copy();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _C.accent.withValues(alpha: 0.14),
                    _C.accent.withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _C.accent.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.accent.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(icono, size: 42, color: _C.accent),
            ),
            const SizedBox(height: 22),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _C.primary,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _C.textSub,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Material(
              color: _C.accent,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              shadowColor: _C.accent.withValues(alpha: 0.4),
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateEditPrestamoScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Crear préstamo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
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
            'Error al cargar préstamos',
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
