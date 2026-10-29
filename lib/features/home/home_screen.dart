import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/models/presupuesto_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';
import '../accounts/accounts_provider.dart';
import '../accounts/accounts_screen.dart';
import '../accounts/account_transactions_screen.dart';
import '../prestamos/prestamos_screen.dart';
import '../presupuestos/presupuestos_provider.dart';
import '../presupuestos/presupuestos_screen.dart';
import '../recurring/recurring_provider.dart';
import '../transactions/create_transaction_screen.dart';
import '../transactions/create_transfer_screen.dart';
import '../transactions/transaction_detail_sheet.dart';
import '../transactions/transactions_provider.dart' as tprov;
import 'home_charts.dart';
import '../../core/currency/exchange_rates.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

bool _isThisMonth(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month;
}

/// Presupuestos activos cuyo periodo incluye hoy.
List<Presupuesto> _currentBudgets(List<Presupuesto> items) {
  final now = DateTime.now();
  return items
      .where(
        (p) =>
            p.activo &&
            p.montoLimite > 0 &&
            !now.isBefore(p.fechaInicio) &&
            !now.isAfter(p.fechaFin.add(const Duration(days: 1))),
      )
      .toList();
}

// ─── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  final UserResponse user;
  final VoidCallback? openDrawer;
  final VoidCallback? openProfile;
  final VoidCallback? openMovements;

  const HomeScreen({
    super.key,
    required this.user,
    this.openDrawer,
    this.openProfile,
    this.openMovements,
  });

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(accountsNotifierProvider);
    final transAsync = ref.watch(tprov.transactionsNotifierProvider);
    final presupAsync = ref.watch(presupuestosNotifierProvider);

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () async {
            await Future.wait([
              ref.read(accountsNotifierProvider.notifier).refresh(),
              ref.read(tprov.transactionsNotifierProvider.notifier).refresh(),
              ref.read(presupuestosNotifierProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _Header(
                user: user,
                onAvatar: openDrawer,
                onBell: () => _showAlerts(context),
              ),
              const SizedBox(height: 20),
              _BalanceCard(
                cuentasAsync: cuentasAsync,
                transAsync: transAsync,
                moneda: user.monedaPredeterminada ?? 'COP',
              ),
              const SizedBox(height: 20),
              _QuickActions(
                onIncome: () => _push(
                  context,
                  const CreateTransactionScreen(tipoTransaccion: 'INGRESO'),
                ),
                onExpense: () => _push(
                  context,
                  const CreateTransactionScreen(tipoTransaccion: 'GASTO'),
                ),
                onTransfer: () => _push(context, const CreateTransferScreen()),
                onLoan: () => _push(context, const PrestamosScreen()),
              ),
              const SizedBox(height: 20),
              _BudgetCard(
                presupAsync: presupAsync,
                onOpen: () => _push(context, const PresupuestosScreen()),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Mis cuentas',
                onSeeAll: () => _push(context, const AccountsScreen()),
              ),
              const SizedBox(height: 10),
              _AccountsStrip(
                cuentasAsync: cuentasAsync,
                onOpen: (c) =>
                    _push(context, AccountTransactionsScreen(cuenta: c)),
                onEmpty: () => _push(context, const AccountsScreen()),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Movimientos recientes',
                onSeeAll: openMovements,
              ),
              const SizedBox(height: 4),
              _RecentMovements(transAsync: transAsync),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Gastos por categoría'),
              const SizedBox(height: 10),
              GastoPorCategoriaChart(transAsync: transAsync),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'Últimos 6 meses'),
              const SizedBox(height: 10),
              IngresosGastosChart(transAsync: transAsync),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlerts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Brand.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AlertsSheet(),
    );
  }
}

// ─── Encabezado ───────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.user, this.onAvatar, this.onBell});

  final UserResponse user;
  final VoidCallback? onAvatar;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
        ? 'Buenas tardes'
        : 'Buenas noches';
    final initials = user.nombre
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();
    final firstName = user.nombre.trim().split(RegExp(r'\s+')).first;

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Abrir menú',
          excludeSemantics: true,
          child: InkWell(
            onTap: onAvatar,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Brand.ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                initials,
                style: Brand.text(
                  size: 15,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Brand.text(size: 13, color: Brand.muted)),
              const SizedBox(height: 2),
              Text(
                'Hola, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Brand.text(size: 17, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.notifications_none_rounded,
          label: 'Avisos',
          onTap: onBell,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.surface,
      shape: const CircleBorder(side: BorderSide(color: Brand.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: Brand.ink, semanticLabel: label),
        ),
      ),
    );
  }
}

// ─── Saldo total ──────────────────────────────────────────────────────────────
class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({
    required this.cuentasAsync,
    required this.transAsync,
    required this.moneda,
  });

  final AsyncValue<List<Cuenta>> cuentasAsync;
  final AsyncValue<List<Transaccion>> transAsync;
  final String moneda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = cuentasAsync.valueOrNull ?? const <Cuenta>[];
    final activas = cuentas.where((c) => c.activa).toList();
    final delMes = (transAsync.valueOrNull ?? const <Transaccion>[])
        .where((t) => _isThisMonth(t.fechaTransaccion))
        .toList();

    // Cuentas o movimientos en otra moneda: se suman convertidos a la
    // predeterminada (antes se sumaban COP y USD como si fueran lo mismo)
    final otras = {
      ...activas.map((c) => c.moneda),
      ...delMes.map((t) => t.moneda),
    }.where((m) => m != moneda).toSet();
    final tasas = otras.isEmpty
        ? Tasas.sinDatos(moneda)
        : ref.watch(tasasProvider).valueOrNull ?? Tasas.sinDatos(moneda);
    final sinTasa = otras.where((m) => !tasas.puede(m)).toList();

    final total = activas.fold<double>(
      0,
      (s, c) => s + tasas.aBase(c.saldoActual ?? c.saldoInicial, c.moneda),
    );
    double ingresos = 0, gastos = 0;
    for (final t in delMes) {
      if (t.tipoNombre == 'INGRESO') ingresos += tasas.aBase(t.monto, t.moneda);
      if (t.tipoNombre == 'GASTO') gastos += tasas.aBase(t.monto, t.moneda);
    }
    final loading = cuentasAsync.isLoading && cuentas.isEmpty;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo total',
                style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22352E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  moneda,
                  style: Brand.text(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFFD6E4DD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (loading)
            const SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Brand.mint,
                  ),
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _money.format(total),
                style: Brand.title(size: 36, color: Colors.white),
              ),
            ),
          if (otras.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sinTasa.isEmpty
                  ? 'Incluye ${otras.join(', ')} convertido a $moneda con la tasa del día'
                  : 'Sin tasa de cambio para ${sinTasa.join(', ')}: se suma sin convertir',
              style: Brand.text(size: 11, color: const Color(0xFFB9C6C0)),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MonthTile(
                  label: 'Ingresos del mes',
                  value: _money.format(ingresos),
                  icon: Icons.south_west_rounded,
                  iconColor: Brand.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MonthTile(
                  label: 'Gastos del mes',
                  value: _money.format(gastos),
                  icon: Icons.north_east_rounded,
                  iconColor: Brand.peach,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(size: 12, color: const Color(0xFFB9C6C0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Brand.text(
                size: 17,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Acciones rápidas ─────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onIncome,
    required this.onExpense,
    required this.onTransfer,
    required this.onLoan,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onTransfer;
  final VoidCallback onLoan;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, Color color, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Brand.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Brand.border),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Brand.text(size: 12, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        action(Icons.add_rounded, Brand.accent, 'Ingreso', onIncome),
        const SizedBox(width: 8),
        action(Icons.remove_rounded, Brand.expense, 'Gasto', onExpense),
        const SizedBox(width: 8),
        action(Icons.swap_horiz_rounded, Brand.ink, 'Transferir', onTransfer),
        const SizedBox(width: 8),
        action(Icons.credit_card_rounded, Brand.ink, 'Préstamo', onLoan),
      ],
    );
  }
}

// ─── Presupuesto del mes ──────────────────────────────────────────────────────
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.presupAsync, required this.onOpen});

  final AsyncValue<List<Presupuesto>> presupAsync;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final items = presupAsync.valueOrNull;
    if (items == null) return const SizedBox.shrink();

    final current = _currentBudgets(items);
    final mes = _capitalize(DateFormat('MMMM', 'es_ES').format(DateTime.now()));

    if (current.isEmpty) {
      return _Card(
        onTap: onOpen,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Brand.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.pie_chart_outline_rounded,
                  color: Brand.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crea tu presupuesto de $mes',
                    style: Brand.text(weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ponle un límite a tus gastos y te avisamos antes de pasarte.',
                    style: Brand.text(size: 12, color: Brand.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Brand.muted),
          ],
        ),
      );
    }

    final limite = current.fold<double>(0, (s, p) => s + p.montoLimite);
    final gastado = current.fold<double>(0, (s, p) => s + p.montoGastado);
    final pct = (gastado / limite).clamp(0.0, 1.0);
    final over = gastado > limite;
    final restante = limite - gastado;

    return _Card(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  current.length == 1
                      ? current.first.nombre
                      : 'Presupuesto de $mes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(weight: FontWeight.w700),
                ),
              ),
              Text(
                'Ver todo',
                style: Brand.text(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Brand.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              color: over ? Brand.expense : Brand.accent,
              backgroundColor: Brand.track,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _money.format(gastado),
                        style: Brand.text(size: 13, weight: FontWeight.w700),
                      ),
                      TextSpan(text: ' de ${_money.format(limite)}'),
                    ],
                  ),
                  style: Brand.text(size: 13, color: Brand.muted),
                ),
              ),
              Text(
                over
                    ? 'Te pasaste ${_money.format(-restante)}'
                    : 'Quedan ${_money.format(restante)}',
                style: Brand.text(
                  size: 13,
                  weight: over ? FontWeight.w700 : FontWeight.w500,
                  color: over ? Brand.expense : Brand.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Brand.text(weight: FontWeight.w700)),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: Brand.accent,
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(
              'Ver todo',
              style: Brand.text(
                size: 13,
                weight: FontWeight.w600,
                color: Brand.accent,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Cuentas ──────────────────────────────────────────────────────────────────
class _AccountsStrip extends StatelessWidget {
  const _AccountsStrip({
    required this.cuentasAsync,
    required this.onOpen,
    required this.onEmpty,
  });

  final AsyncValue<List<Cuenta>> cuentasAsync;
  final ValueChanged<Cuenta> onOpen;
  final VoidCallback onEmpty;

  static (IconData, Color, Color) _style(String tipo) => switch (tipo) {
    'EFECTIVO' => (Icons.payments_outlined, Brand.accent, Brand.accentSoft),
    'TARJETA_DEBITO' => (Icons.credit_card_outlined, Brand.blue, Brand.blueSoft),
    'TARJETA_CREDITO' => (
      Icons.credit_card_outlined,
      Brand.expense,
      Brand.expenseSoft,
    ),
    'AHORRO' => (Icons.savings_outlined, Brand.accent, Brand.accentSoft),
    'INVERSION' => (Icons.trending_up_rounded, Brand.blue, Brand.blueSoft),
    _ => (Icons.account_balance_outlined, Brand.accent, Brand.accentSoft),
  };

  @override
  Widget build(BuildContext context) {
    return cuentasAsync.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Brand.accent),
        ),
      ),
      error: (_, __) => _Card(
        child: Text(
          'No se pudieron cargar tus cuentas. Desliza hacia abajo para reintentar.',
          style: Brand.text(size: 13, color: Brand.expense),
        ),
      ),
      data: (all) {
        final cuentas = all.where((c) => c.activa).toList();
        if (cuentas.isEmpty) {
          return _Card(
            onTap: onEmpty,
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    color: Brand.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Agrega tu primera cuenta',
                    style: Brand.text(weight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Brand.muted),
              ],
            ),
          );
        }
        return SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: cuentas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final c = cuentas[i];
              final (icon, fg, bg) = _style(c.tipo);
              final saldo = c.saldoActual ?? c.saldoInicial;
              return SizedBox(
                width: 168,
                child: _Card(
                  onTap: () => onOpen(c),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 18, color: fg),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Brand.text(
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money.format(saldo),
                          style: Brand.text(
                            size: 17,
                            weight: FontWeight.w800,
                            color: saldo < 0 ? Brand.expense : Brand.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Movimientos recientes ────────────────────────────────────────────────────
class _RecentMovements extends StatelessWidget {
  const _RecentMovements({required this.transAsync});

  final AsyncValue<List<Transaccion>> transAsync;

  static String _when(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return DateFormat("d 'de' MMM", 'es_ES').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return transAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Brand.accent),
        ),
      ),
      error: (_, __) => _Card(
        child: Text(
          'No se pudieron cargar tus movimientos.',
          style: Brand.text(size: 13, color: Brand.expense),
        ),
      ),
      data: (items) {
        final list = [...items]
          ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aún no tienes movimientos. Toca + para registrar el primero.',
              style: Brand.text(size: 13, color: Brand.muted),
            ),
          );
        }
        return Column(
          children: [
            for (final t in list.take(5))
              _MovementRow(t: t, when: _when(t.fechaTransaccion)),
          ],
        );
      },
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.t, required this.when});

  final Transaccion t;
  final String when;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon, sign) = switch (t.tipoNombre) {
      'INGRESO' => (Brand.accent, Brand.accentSoft, Icons.south_west_rounded, '+'),
      'GASTO' => (Brand.expense, Brand.expenseSoft, Icons.north_east_rounded, '−'),
      _ => (Brand.blue, Brand.blueSoft, Icons.swap_horiz_rounded, ''),
    };
    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? 'Movimiento');
    final meta = [
      if (t.cuentaNombre != null) t.cuentaNombre!,
      when,
    ].join(' · ');

    return InkWell(
      onTap: () => showTransactionDetail(context, t),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.text(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.text(size: 12, color: Brand.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${_money.format(t.monto)}',
              style: Brand.text(size: 14, weight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avisos (campana) ─────────────────────────────────────────────────────────
class _AlertsSheet extends ConsumerWidget {
  const _AlertsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = _currentBudgets(
      ref.watch(presupuestosNotifierProvider).valueOrNull ?? const [],
    ).where((p) => p.porcentaje >= 80).toList();

    final now = DateTime.now();
    final limit = DateTime(now.year, now.month, now.day + 7);
    final upcoming = <(PagoRecurrente, DateTime)>[
      for (final p in ref.watch(recurringProvider).valueOrNull ?? const [])
        if (p.activo)
          if (p.proximaFecha() case final f? when !f.isAfter(limit)) (p, f),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final empty = budgets.isEmpty && upcoming.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
            const SizedBox(height: 20),
            Text('Avisos', style: Brand.text(size: 20, weight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (empty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Brand.accent, size: 40),
                    const SizedBox(height: 10),
                    Text('Todo en orden',
                        style: Brand.text(weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Ningún presupuesto cerca del límite ni pagos esta semana.',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 13, color: Brand.muted),
                    ),
                  ],
                ),
              ),
            for (final b in budgets)
              _AlertRow(
                icon: Icons.pie_chart_outline_rounded,
                fg: Brand.expense,
                bg: Brand.expenseSoft,
                title: b.sobrepasado
                    ? 'Superaste "${b.nombre}"'
                    : 'Casi llegas al límite de "${b.nombre}"',
                subtitle:
                    '${b.porcentaje.round()}% usado · ${_money.format(b.montoGastado)} de ${_money.format(b.montoLimite)}',
              ),
            for (final (p, f) in upcoming)
              _AlertRow(
                icon: Icons.autorenew_rounded,
                fg: Brand.blue,
                bg: Brand.blueSoft,
                title: p.descripcion.isEmpty
                    ? (p.categoriaNombre ?? 'Pago recurrente')
                    : p.descripcion,
                subtitle:
                    '${_money.format(p.monto)} · ${_upcomingLabel(f)}',
              ),
          ],
        ),
      ),
    );
  }

  static String _upcomingLabel(DateTime f) {
    final now = DateTime.now();
    final diff = DateTime(f.year, f.month, f.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    return DateFormat("EEEE d", 'es_ES').format(f);
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Brand.text(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: Brand.text(size: 12, color: Brand.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

