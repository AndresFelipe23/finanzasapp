import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/glass.dart';
import '../../core/theme/neo_bank_theme.dart';
import '../transactions/create_transaction_screen.dart';
import '../transactions/create_transfer_screen.dart';
import '../transactions/transactions_provider.dart' as tprov;
import '../accounts/accounts_provider.dart';
import '../accounts/account_transactions_screen.dart';

// ─── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  final UserResponse user;
  final VoidCallback? openDrawer;

  const HomeScreen({super.key, required this.user, this.openDrawer});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showAppInfoDialog(BuildContext context) {
    final tk = context.tokens;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          strong: true,
          blurSigma: tk.blurChrome,
          borderRadius: BorderRadius.circular(tk.radiusLg),
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: tk.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: tk.accent,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Financially',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tk.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión 1.0.0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: tk.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                _infoBlock(
                  context: context,
                  icon: Icons.description_outlined,
                  title: 'Sobre la App',
                  body:
                      'Aplicación de gestión financiera personal diseñada para ayudarte a controlar tus ingresos, gastos y metas de manera sencilla y eficiente.',
                ),
                const SizedBox(height: 12),
                _infoBlock(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'Desarrollador',
                  body: 'AFESDEV\nafesdev2025@gmail.com',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tk.primary,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _AddTransactionSheet(),
    );
  }

  Widget _infoBlock({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String body,
  }) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tk.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tk.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tk.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tk.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: tk.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final cuentasAsync = ref.watch(accountsNotifierProvider);
    final transAsync = ref.watch(tprov.transactionsNotifierProvider);

    final firstName = widget.user.nombre.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
        ? 'Buenas tardes'
        : 'Buenas noches';
    final initials = widget.user.nombre
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: tk.accent,
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
          // ── Header ─────────────────────────────────────────────────────
          GlassContainer(
            blurSigma: tk.blurChrome,
            shadow: false,
            borderRadius: BorderRadius.zero,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.openDrawer,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: tk.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: tk.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: tk.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        firstName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: tk.primary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAppInfoDialog(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: tk.glassFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tk.border),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: tk.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ──────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(accountsNotifierProvider.notifier).refresh();
                await ref
                    .read(tprov.transactionsNotifierProvider.notifier)
                    .refresh();
              },
              color: tk.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _ResumenMes(transAsync: transAsync),
                    ),

                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SectionHeader(title: 'Mis Cuentas'),
                    ),
                    const SizedBox(height: 14),
                    cuentasAsync.when(
                      data: (cuentas) {
                        if (cuentas.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _EmptyCard(
                              message: 'No tienes cuentas registradas',
                            ),
                          );
                        }
                        return SizedBox(
                          height: 144,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, i) => _CuentaCard(
                              nombre: cuentas[i].nombre,
                              saldo:
                                  cuentas[i].saldoActual ??
                                  cuentas[i].saldoInicial,
                              moneda: cuentas[i].moneda,
                              colorHex: cuentas[i].color,
                              index: i,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AccountTransactionsScreen(
                                    cuenta: cuentas[i],
                                  ),
                                ),
                              ),
                            ),
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemCount: cuentas.length,
                          ),
                        );
                      },
                      loading: () => SizedBox(
                        height: 144,
                        child: Center(
                          child: CircularProgressIndicator(color: tk.accent),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ErrorCard(message: 'Error al cargar cuentas'),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SectionHeader(title: 'Movimientos Recientes'),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _UltimosMovimientos(transAsync: transAsync),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: tk.primary,
      ),
    );
  }
}

// ─── Empty / Error cards ──────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return GlassContainer(
      blur: false,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      borderRadius: BorderRadius.circular(tk.radiusSm),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: tk.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tk.danger.withValues(alpha: tk.isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(tk.radiusSm),
        border: Border.all(color: tk.danger.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: tk.danger),
      ),
    );
  }
}

class _AddTransactionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tk.surface.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: tk.glassStrokeStart)),
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
                  color: tk.border,
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
                    color: tk.primary,
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
                    color: tk.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SheetOption(
                icon: Icons.south_rounded,
                color: tk.success,
                title: 'Ingreso',
                subtitle: 'Dinero recibido',
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateTransactionScreen(
                          tipoTransaccion: 'INGRESO',
                        ),
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.north_rounded,
                color: tk.danger,
                title: 'Gasto',
                subtitle: 'Dinero gastado',
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateTransactionScreen(
                          tipoTransaccion: 'GASTO',
                        ),
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.swap_horiz_rounded,
                color: tk.transfer,
                title: 'Transferencia',
                subtitle: 'Mover entre cuentas',
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateTransferScreen(),
                      ),
                    );
                  });
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
                      color: tk.textSecondary,
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
    final tk = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tk.bg,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tk.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: tk.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: tk.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Resumen del Mes ──────────────────────────────────────────────────────────
class _ResumenMes extends StatelessWidget {
  final AsyncValue<List<dynamic>> transAsync;
  const _ResumenMes({required this.transAsync});

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return transAsync.when(
      data: (items) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        double ingresos = 0, gastos = 0;

        for (final t in items) {
          final ft = (t as dynamic).fechaTransaccion as DateTime;
          if (ft.isAfter(start.subtract(const Duration(seconds: 1))) &&
              ft.isBefore(end.add(const Duration(days: 1)))) {
            if (t.tipoNombre == 'INGRESO') ingresos += t.monto;
            if (t.tipoNombre == 'GASTO') gastos += t.monto;
          }
        }

        final balance = ingresos - gastos;
        final monthLabel = _capitalize(
          DateFormat('MMMM yyyy', 'es_ES').format(now),
        );

        String fmt(double v) => NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
          locale: 'es_CO',
        ).format(v);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tk.heroStart, tk.heroEnd],
            ),
            borderRadius: BorderRadius.circular(tk.radiusLg),
            border: Border.all(color: tk.glassStrokeEnd),
            boxShadow: [
              BoxShadow(
                color: tk.heroStart.withValues(alpha: 0.3),
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
                    'Balance del mes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      monthLabel,
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
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => Text(
                  fmt(val),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.5,
                    height: 1.15,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      iconBg: tk.success.withValues(alpha: 0.15),
                      iconColor: tk.success,
                      icon: Icons.south_rounded,
                      label: 'Ingresos',
                      value: fmt(ingresos),
                      align: CrossAxisAlignment.start,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: _StatItem(
                      iconBg: tk.danger.withValues(alpha: 0.15),
                      iconColor: tk.danger,
                      icon: Icons.north_rounded,
                      label: 'Gastos',
                      value: fmt(gastos),
                      align: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 210,
        decoration: BoxDecoration(
          color: tk.heroStart,
          borderRadius: BorderRadius.circular(tk.radiusLg),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white38,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => _ErrorCard(message: 'Error al cargar resumen'),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _StatItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    final isEnd = align == CrossAxisAlignment.end;
    return Padding(
      padding: EdgeInsets.only(left: isEnd ? 16 : 0, right: isEnd ? 0 : 16),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isEnd
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cuenta Card ─────────────────────────────────────────────────────────────
class _CuentaCard extends StatelessWidget {
  final String nombre;
  final double saldo;
  final String moneda;
  final String? colorHex;
  final int index;
  final VoidCallback? onTap;

  const _CuentaCard({
    required this.nombre,
    required this.saldo,
    required this.moneda,
    required this.index,
    this.colorHex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final color = _parseColor(colorHex) ?? tk.accent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GlassContainer(
        blur: false,
        onTap: onTap,
        width: 200,
        borderRadius: BorderRadius.circular(tk.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: tk.isDark ? 0.22 : 0.12),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(tk.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: color,
                      size: 17,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tk.glassFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: tk.border),
                    ),
                    child: Text(
                      moneda,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tk.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: tk.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: saldo),
                duration: Duration(milliseconds: 700 + index * 80),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) {
                  final fmt = NumberFormat('#,###', 'es_CO');
                  return Text(
                    '\$${fmt.format(val.toInt())}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: tk.primary,
                      letterSpacing: -0.8,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? h) {
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
}

// ─── Últimos Movimientos ──────────────────────────────────────────────────────
class _UltimosMovimientos extends StatefulWidget {
  final AsyncValue<List<dynamic>> transAsync;
  const _UltimosMovimientos({required this.transAsync});

  @override
  State<_UltimosMovimientos> createState() => _UltimosMovimientosState();
}

class _UltimosMovimientosState extends State<_UltimosMovimientos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final money = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );

    return widget.transAsync.when(
      data: (items) {
        final sorted = [...items]
          ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));
        final list = sorted.take(5).toList();

        if (list.isEmpty) {
          return GlassContainer(
            blur: false,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            borderRadius: BorderRadius.circular(tk.radiusMd),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 40,
                    color: tk.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No hay movimientos recientes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: tk.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GlassContainer(
          blur: false,
          borderRadius: BorderRadius.circular(tk.radiusMd),
          child: Column(
            children: list.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value as Transaccion;
              final isLast = i == list.length - 1;

              final delay = i * 0.12;
              final itemAnim = CurvedAnimation(
                parent: _ctrl,
                curve: Interval(
                  delay.clamp(0.0, 0.8),
                  (delay + 0.5).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              );

              return AnimatedBuilder(
                animation: itemAnim,
                builder: (_, child) => Opacity(
                  opacity: itemAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - itemAnim.value)),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    _TransactionTile(
                      transaccion: t,
                      money: money,
                      onTap: () => _showDetail(context, t, money),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                        color: tk.divider,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => GlassContainer(
        blur: false,
        height: 220,
        borderRadius: BorderRadius.circular(tk.radiusMd),
        child: Center(
          child: CircularProgressIndicator(color: tk.accent, strokeWidth: 2),
        ),
      ),
      error: (e, _) => _ErrorCard(message: 'Error al cargar movimientos'),
    );
  }

  void _showDetail(BuildContext context, Transaccion t, NumberFormat money) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _TransactionDetailSheet(transaccion: t, money: money),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Transaccion transaccion;
  final NumberFormat money;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaccion,
    required this.money,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tk = context.tokens;
    final t = transaccion;
    final isIngreso = t.tipoNombre == 'INGRESO';
    final color = isIngreso ? tk.success : tk.danger;
    final df = DateFormat('d MMM', 'es_ES');
    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? 'Transacción');
    final dateStr = df.format(t.fechaTransaccion);
    final amountStr = (isIngreso ? '+' : '-') + money.format(t.monto);

    final catColor = _parseCatColor(t.categoriaColor) ?? color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.06),
        highlightColor: color.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icono con color de categoría
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isIngreso ? Icons.south_rounded : Icons.north_rounded,
                  color: catColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
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
                        color: tk.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: tk.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (t.categoriaNombre != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: tk.textSecondary.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.categoriaNombre!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: tk.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: tk.textSecondary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _parseCatColor(String? h) {
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
}

// ─── Transaction Detail Sheet ─────────────────────────────────────────────────
class _TransactionDetailSheet extends StatefulWidget {
  final Transaccion transaccion;
  final NumberFormat money;

  const _TransactionDetailSheet({
    required this.transaccion,
    required this.money,
  });

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
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
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
    final tk = context.tokens;
    final t = widget.transaccion;
    final isIngreso = t.tipoNombre == 'INGRESO';
    final color = isIngreso ? tk.success : tk.danger;
    final amountStr = (isIngreso ? '+' : '-') + widget.money.format(t.monto);
    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? 'Transacción');
    final fullDate = DateFormat(
      'EEEE, d \'de\' MMMM yyyy',
      'es_ES',
    ).format(t.fechaTransaccion);
    final timeStr = DateFormat('h:mm a', 'es_ES').format(t.fechaTransaccion);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          decoration: BoxDecoration(
            color: tk.surface.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: tk.glassStrokeStart)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tk.border,
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
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIngreso ? Icons.south_rounded : Icons.north_rounded,
                        color: color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      amountStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: color,
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
                        color: tk.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isIngreso ? 'Ingreso' : 'Gasto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Divider(height: 1, color: tk.divider),
              const SizedBox(height: 8),

              // Detalles
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Fecha',
                        value: _capitalize(fullDate),
                      ),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Hora',
                        value: timeStr,
                      ),
                      if (t.cuentaNombre != null)
                        _DetailRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Cuenta',
                          value: t.cuentaNombre!,
                        ),
                      if (t.categoriaNombre != null)
                        _DetailRow(
                          icon: Icons.label_rounded,
                          label: 'Categoría',
                          value: t.categoriaNombre!,
                        ),
                      if (t.metodoPagoNombre != null)
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
                      if (t.descripcion != null && t.descripcion!.isNotEmpty)
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: 'Descripción',
                          value: t.descripcion!,
                          multiline: true,
                        ),
                      if (t.notas != null && t.notas!.isNotEmpty)
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

              // Botón cerrar
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tk.primary,
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
  Widget build(BuildContext context) {
    final tk = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tk.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: tk.textSecondary),
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
                    color: tk.textSecondary,
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
                    color: tk.primary,
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
}

// ─── Widgets deshabilitados (NFC / Presupuestos) ──────────────────────────────
// Mantenidos comentados para futura reactivación
/*
class _Accesos extends StatelessWidget { ... }
class _AccesoCard extends StatelessWidget { ... }
*/
