import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import 'accounts_provider.dart';
import 'create_account_screen.dart';
import 'edit_account_screen.dart';

// ─── Design tokens (mismo sistema que home_screen) ───────────────────────────
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
}

// ─── Filtros disponibles ──────────────────────────────────────────────────────
const _kFilters = [
  ('Todas', 'ALL'),
  ('Bancaria', 'BANCARIA'),
  ('Efectivo', 'EFECTIVO'),
  ('Digital', 'DIGITAL'),
  ('Ahorro', 'AHORRO'),
  ('Inversión', 'INVERSION'),
];

// ─── Accounts Screen ──────────────────────────────────────────────────────────
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'ALL';
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
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsNotifierProvider);

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
                    Icons.account_balance_wallet_rounded,
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
                        'Mis Cuentas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.primary,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Gestiona tus finanzas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _C.textSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón agregar
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
                left: 20, right: 20, bottom: 16, top: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kFilters.map((f) {
                  final isSelected = _selectedFilter == f.$2;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f.$2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _C.accent
                              : _C.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? _C.accent : _C.border,
                          ),
                        ),
                        child: Text(
                          f.$1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : _C.textSub,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Lista ────────────────────────────────────────────────────
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                final filtered = _filterAccounts(accounts, _selectedFilter);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    filter: _selectedFilter,
                    onAdd: () => _navigateToCreate(context),
                  );
                }
                final totalSaldo = filtered.fold<double>(
                  0,
                  (sum, c) => sum + (c.saldoActual ?? c.saldoInicial),
                );
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(accountsNotifierProvider.notifier).refresh(),
                  color: _C.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: filtered.length + 1, // +1 para el banner
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      // Banner de total
                      if (index == 0) {
                        return _TotalBanner(
                          total: totalSaldo,
                          count: filtered.length,
                        );
                      }
                      final cuenta = filtered[index - 1];
                      return TweenAnimationBuilder<double>(
                        duration:
                            Duration(milliseconds: 300 + (index * 40)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, child) => Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - val)),
                            child: child,
                          ),
                        ),
                        child: _AccountCard(
                          cuenta: cuenta,
                          onEdit: () =>
                              _navigateToEdit(context, cuenta),
                          onDelete: () =>
                              _showDeleteDialog(context, cuenta),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: _C.accent, strokeWidth: 2),
              ),
              error: (e, _) => _ErrorState(
                error: e.toString(),
                onRetry: () =>
                    ref.read(accountsNotifierProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Cuenta> _filterAccounts(List<Cuenta> accounts, String filter) {
    if (filter == 'ALL') return accounts;
    return accounts.where((a) => a.tipo == filter).toList();
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
    );
  }

  void _navigateToEdit(BuildContext context, Cuenta cuenta) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditAccountScreen(cuenta: cuenta)),
    );
  }

  void _showDeleteDialog(BuildContext context, Cuenta cuenta) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => _DeleteDialog(
        cuenta: cuenta,
        onConfirm: () async {
          try {
            await ref
                .read(accountsNotifierProvider.notifier)
                .deleteAccount(cuenta.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Cuenta eliminada',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  backgroundColor: _C.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: _C.danger,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ─── Total Banner ─────────────────────────────────────────────────────────────
class _TotalBanner extends StatelessWidget {
  final double total;
  final int count;
  const _TotalBanner({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'es_CO');
    final isPositive = total >= 0;
    final statusColor = isPositive ? _C.success : _C.danger;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2340), Color(0xFF2D3461)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2340).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patrimonio total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count ${count == 1 ? 'cuenta' : 'cuentas'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: total),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Text(
              '\$${fmt.format(val.toInt())}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 13,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPositive
                    ? 'Balance positivo'
                    : 'Balance negativo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final Cuenta cuenta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.cuenta,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(cuenta.color);
    final saldo = cuenta.saldoActual ?? cuenta.saldoInicial;
    final isPositive = saldo >= 0;
    final fmt = NumberFormat('#,###', 'es_CO');
    final typeColor = _typeColor(cuenta.tipo);

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
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
          children: [
            // ── Cabecera tintada ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _iconData(cuenta.icono),
                      color: accentColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cuenta.nombre,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _C.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _Badge(
                              label: _typeLabel(cuenta.tipo),
                              color: typeColor,
                            ),
                            const SizedBox(width: 6),
                            _Badge(
                              label: cuenta.moneda,
                              color: _C.textSub,
                              subtle: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: _C.surface,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.12),
                    offset: const Offset(0, 8),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 16, color: _C.textSub),
                            const SizedBox(width: 10),
                            Text(
                              'Editar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 16, color: _C.danger),
                            const SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _C.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.border),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: _C.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Saldo ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo actual',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _C.textSub,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: saldo.abs()),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, __) => Text(
                            '${isPositive ? '' : '-'}\$${fmt.format(val.toInt())}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isPositive ? _C.primary : _C.danger,
                              letterSpacing: -1,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isPositive ? _C.success : _C.danger)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 18,
                      color: isPositive ? _C.success : _C.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? h) {
    if (h == null || h.isEmpty) return _C.accent;
    try {
      return Color(int.parse(h.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _C.accent;
    }
  }

  IconData _iconData(String? name) {
    switch (name) {
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'wallet':
        return Icons.wallet_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'attach_money':
        return Icons.attach_money_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  String _typeLabel(String tipo) {
    switch (tipo) {
      case 'BANCARIA':
        return 'Bancaria';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'TARJETA_CREDITO':
        return 'T. Crédito';
      case 'TARJETA_DEBITO':
        return 'T. Débito';
      case 'DIGITAL':
        return 'Digital';
      case 'AHORRO':
        return 'Ahorro';
      case 'INVERSION':
        return 'Inversión';
      default:
        return tipo;
    }
  }

  Color _typeColor(String tipo) {
    switch (tipo) {
      case 'BANCARIA':
        return const Color(0xFF3B82F6);
      case 'EFECTIVO':
        return const Color(0xFF22C55E);
      case 'TARJETA_CREDITO':
      case 'TARJETA_DEBITO':
        return const Color(0xFFF59E0B);
      case 'DIGITAL':
        return const Color(0xFFA855F7);
      case 'AHORRO':
        return const Color(0xFF14B8A6);
      case 'INVERSION':
        return const Color(0xFF5B5FEE);
      default:
        return _C.textSub;
    }
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;
  const _Badge({required this.label, required this.color, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: subtle
            ? _C.bg
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: subtle ? _C.border : color.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: subtle ? _C.textSub : color,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onAdd;
  const _EmptyState({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final msg = filter == 'ALL'
        ? 'No tienes cuentas aún'
        : 'Sin cuentas de este tipo';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (_, val, child) =>
              Opacity(opacity: val, child: child),
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
                  Icons.account_balance_wallet_outlined,
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
                'Agrega una cuenta para comenzar\na gestionar tus finanzas',
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
                      horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: _C.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Agregar Cuenta',
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
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              'Error al cargar cuentas',
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
}

// ─── Delete Dialog ────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final Cuenta cuenta;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.cuenta, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(cuenta.color);
    final saldo = cuenta.saldoActual ?? cuenta.saldoInicial;
    final fmt = NumberFormat('#,###', 'es_CO');

    return Dialog(
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
            // Header
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
                      'Eliminar cuenta',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _C.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _C.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _C.border),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _C.textSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info de la cuenta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cuenta.nombre,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                          ),
                          Text(
                            '\$${fmt.format(saldo.toInt())} ${cuenta.moneda}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
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
            ),

            const SizedBox(height: 14),

            // Advertencia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _C.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16,
                        color: _C.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer. No se puede eliminar si tiene transacciones asociadas o saldo diferente de cero.',
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

            // Botones
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
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
                      onTap: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _C.danger,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 16),
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
    );
  }

  Color _parseColor(String? h) {
    if (h == null || h.isEmpty) return _C.accent;
    try {
      return Color(int.parse(h.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _C.accent;
    }
  }
}
