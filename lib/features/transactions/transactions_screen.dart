import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaccion_models.dart';
import 'transactions_provider.dart';
import 'create_transaction_screen.dart';
import 'create_transfer_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color primary = Color(0xFF1E2340);
  static const Color accent = Color(0xFF5B5FEE);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color transfer = Color(0xFF8B5CF6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textSub = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}

// ─── Transactions Screen ──────────────────────────────────────────────────────
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: _C.accent,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: Text(
          'Nueva',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
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
                    Icons.receipt_long_rounded,
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
                        'Movimientos',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Historial completo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _C.textSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              data: (transacciones) {
                if (transacciones.isEmpty) return _buildEmpty();
                final grouped = _groupByDate(transacciones);
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(transactionsNotifierProvider.notifier).refresh(),
                  color: _C.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, i) {
                      final entry = grouped[i];
                      final date = entry.key;
                      final items = entry.value;
                      return _DayGroup(
                        date: date,
                        transactions: items,
                        onTap: (t) => _showDetail(context, t),
                        isFirst: i == 0,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: _C.accent, strokeWidth: 2),
              ),
              error: (e, _) => _buildError(e.toString(), () {
                ref.read(transactionsNotifierProvider.notifier).refresh();
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add sheet ──────────────────────────────────────────────────────────────
  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  // ── Detail sheet ───────────────────────────────────────────────────────────
  void _showDetail(BuildContext context, Transaccion t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _TransactionDetailSheet(transaccion: t),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<MapEntry<DateTime, List<Transaccion>>> _groupByDate(
      List<Transaccion> list) {
    final map = <DateTime, List<Transaccion>>{};
    for (final t in list) {
      final ft = t.fechaTransaccion;
      final d = DateTime(ft.year, ft.month, ft.day);
      (map[d] ??= []).add(t);
    }
    final sorted = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sorted.map((k) => MapEntry(k, map[k]!)).toList();
  }

  Widget _buildEmpty() => Center(
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
                child: const Icon(Icons.receipt_long_rounded,
                    size: 38, color: _C.accent),
              ),
              const SizedBox(height: 20),
              Text(
                'Sin movimientos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registra tu primer ingreso o gasto\npara empezar a llevar el control',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _C.textSub,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(String error, VoidCallback onRetry) => Center(
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
                child: const Icon(Icons.error_outline_rounded,
                    size: 38, color: _C.danger),
              ),
              const SizedBox(height: 20),
              Text(
                'Error al cargar',
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
                    fontSize: 13, color: _C.textSub, height: 1.5),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
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

// ─── Day Group ────────────────────────────────────────────────────────────────
class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<Transaccion> transactions;
  final void Function(Transaccion) onTap;
  final bool isFirst;

  const _DayGroup({
    required this.date,
    required this.transactions,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'Hoy';
    } else if (dateOnly == yesterday) {
      label = 'Ayer';
    } else {
      label = _capitalize(
          DateFormat('EEEE, d MMMM', 'es_ES').format(date));
    }

    final sorted = [...transactions]
      ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));

    final dayTotal = sorted.fold<double>(0, (sum, t) {
      if (t.tipoNombre == 'INGRESO') return sum + t.monto;
      if (t.tipoNombre == 'GASTO') return sum - t.monto;
      return sum;
    });
    final fmt =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

    return Padding(
      padding: EdgeInsets.only(bottom: 20, top: isFirst ? 0 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del día
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  (dayTotal >= 0 ? '+' : '') + fmt.format(dayTotal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dayTotal >= 0 ? _C.success : _C.danger,
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta del día
          Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  final isLast = i == sorted.length - 1;
                  return Column(
                    children: [
                      _TransactionRow(
                        transaccion: t,
                        onTap: () => onTap(t),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          indent: 72,
                          endIndent: 16,
                          color: _C.divider,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Transaction Row ──────────────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final Transaccion transaccion;
  final VoidCallback onTap;

  const _TransactionRow({required this.transaccion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = transaccion;
    final isTransfer = t.titulo?.toLowerCase().contains('transferencia') == true;
    final isIngreso = t.tipoNombre == 'INGRESO';

    final Color typeColor;
    if (isTransfer) {
      typeColor = _C.transfer;
    } else if (isIngreso) {
      typeColor = _C.success;
    } else {
      typeColor = _C.danger;
    }

    final catColor = _parseColor(t.categoriaColor) ?? typeColor;
    final iconColor = isTransfer ? _C.transfer : catColor;

    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? 'Transacción');
    final timeStr = DateFormat('h:mm a').format(t.fechaTransaccion);
    final fmt =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');
    final amountStr = (isIngreso ? '+' : '-') + fmt.format(t.monto);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Ícono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isTransfer
                      ? Icons.swap_horiz_rounded
                      : _iconFromName(t.categoriaIcono),
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _C.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isTransfer
                                ? 'Transferencia'
                                : (isIngreso ? 'Ingreso' : 'Gasto'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _C.textSub.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _C.textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (t.categoriaNombre != null && !isTransfer) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _C.textSub.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              t.categoriaNombre!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: _C.textSub,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Monto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _C.textSub.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color? _parseColor(String? h) {
    if (h == null || h.isEmpty) return null;
    try {
      return Color(int.parse(h.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  static IconData _iconFromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'restaurant':
      case 'restaurant_menu':
        return Icons.restaurant_rounded;
      case 'local_gas_station':
        return Icons.local_gas_station_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'health':
      case 'medical':
        return Icons.medical_services_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}

// ─── Transaction Detail Sheet ─────────────────────────────────────────────────
class _TransactionDetailSheet extends StatefulWidget {
  final Transaccion transaccion;
  const _TransactionDetailSheet({required this.transaccion});

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaccion;
    final isTransfer =
        t.titulo?.toLowerCase().contains('transferencia') == true;
    final isIngreso = t.tipoNombre == 'INGRESO';
    final Color typeColor = isTransfer
        ? _C.transfer
        : (isIngreso ? _C.success : _C.danger);

    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? 'Transacción');
    final fmt =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');
    final amountStr = (isIngreso ? '+' : '-') + fmt.format(t.monto);
    final fullDate = _capitalize(
        DateFormat('EEEE, d \'de\' MMMM yyyy', 'es_ES')
            .format(t.fechaTransaccion));
    final timeStr = DateFormat('HH:mm').format(t.fechaTransaccion);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: const BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Monto + tipo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTransfer
                            ? Icons.swap_horiz_rounded
                            : (isIngreso
                                ? Icons.south_rounded
                                : Icons.north_rounded),
                        color: typeColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      amountStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _C.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTransfer
                            ? 'Transferencia'
                            : (isIngreso ? 'Ingreso' : 'Gasto'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Divider(height: 1, color: _C.divider),
              const SizedBox(height: 8),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Fecha',
                        value: fullDate,
                      ),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Hora',
                        value: timeStr,
                      ),
                      if (t.cuentaNombre != null)
                        _DetailRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: isTransfer
                              ? (isIngreso ? 'Cuenta destino' : 'Cuenta origen')
                              : 'Cuenta',
                          value: t.cuentaNombre!,
                        ),
                      if (t.categoriaNombre != null && !isTransfer)
                        _DetailRow(
                          icon: Icons.label_rounded,
                          label: 'Categoría',
                          value: t.categoriaNombre!,
                        ),
                      if (t.metodoPagoNombre != null && !isTransfer)
                        _DetailRow(
                          icon: Icons.credit_card_rounded,
                          label: 'Método de pago',
                          value: t.metodoPagoNombre!,
                        ),
                      _DetailRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Moneda',
                        value: t.moneda,
                      ),
                      if (t.descripcion?.isNotEmpty == true)
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: 'Descripción',
                          value: t.descripcion!,
                          multiline: true,
                        ),
                      if (t.notas?.isNotEmpty == true)
                        _DetailRow(
                          icon: Icons.sticky_note_2_outlined,
                          label: 'Notas',
                          value: t.notas!,
                          multiline: true,
                        ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cerrar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment:
              multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: _C.textSub),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.textSub,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.primary,
                      height: multiline ? 1.5 : 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Add Transaction Sheet ────────────────────────────────────────────────────
class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nueva transacción',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _C.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona el tipo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _C.textSub,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SheetOption(
                icon: Icons.south_rounded,
                color: _C.success,
                title: 'Ingreso',
                subtitle: 'Dinero recibido',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CreateTransactionScreen(
                        tipoTransaccion: 'INGRESO'),
                  ));
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.north_rounded,
                color: _C.danger,
                title: 'Gasto',
                subtitle: 'Dinero gastado',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CreateTransactionScreen(
                        tipoTransaccion: 'GASTO'),
                  ));
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.swap_horiz_rounded,
                color: _C.transfer,
                title: 'Transferencia',
                subtitle: 'Mover entre cuentas',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CreateTransferScreen(),
                  ));
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _C.textSub.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
