import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/theme/brand.dart';
import '../transactions/transaction_list.dart';
import '../transactions/transactions_provider.dart';
import 'account_style.dart';
import 'accounts_provider.dart';
import 'edit_account_screen.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Detalle de una cuenta: saldo, resumen del mes y sus movimientos.
class AccountTransactionsScreen extends ConsumerWidget {
  final Cuenta cuenta;
  const AccountTransactionsScreen({super.key, required this.cuenta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La lista de cuentas tiene la versión más reciente (tras editar)
    final cuentas = ref.watch(accountsNotifierProvider).valueOrNull;
    final c = cuentas?.where((x) => x.id == cuenta.id).firstOrNull ?? cuenta;
    final transAsync = ref.watch(transactionsNotifierProvider);
    final style = accountStyle(c.tipo);
    final saldo = c.saldoActual ?? c.saldoInicial;

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () async {
            await Future.wait([
              ref.read(transactionsNotifierProvider.notifier).refresh(),
              ref.read(accountsNotifierProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const Spacer(),
                  _MenuButton(
                    onEdit: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditAccountScreen(cuenta: c),
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, ref, c),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(style.icon, color: style.fg, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.title(size: 24),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${style.label} · ${c.moneda}'
                          '${c.activa ? '' : ' · Inactiva'}',
                          style: Brand.text(size: 13, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...transAsync.when(
                loading: () => [
                  _Summary(saldo: saldo, ingresos: null, gastos: null),
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Brand.accent,
                      ),
                    ),
                  ),
                ],
                error: (_, __) => [
                  _Summary(saldo: saldo, ingresos: null, gastos: null),
                  const SizedBox(height: 24),
                  Text(
                    'No se pudieron cargar los movimientos. Desliza hacia '
                    'abajo para reintentar.',
                    style: Brand.text(size: 13, color: Brand.expense),
                  ),
                ],
                data: (all) {
                  final propias =
                      all.where((t) => t.cuentaId == c.id).toList();
                  final now = DateTime.now();
                  double ingresos = 0, gastos = 0;
                  for (final t in propias) {
                    final f = t.fechaTransaccion;
                    if (f.year != now.year || f.month != now.month) continue;
                    if (t.tipoNombre == 'INGRESO') ingresos += t.monto;
                    if (t.tipoNombre == 'GASTO') gastos += t.monto;
                  }
                  final groups = groupTransactionsByDay(propias);
                  return [
                    _Summary(saldo: saldo, ingresos: ingresos, gastos: gastos),
                    const SizedBox(height: 24),
                    Text(
                      'Movimientos',
                      style: Brand.text(weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 40, color: Brand.inputBorder),
                            const SizedBox(height: 10),
                            Text(
                              'Esta cuenta aún no tiene movimientos',
                              textAlign: TextAlign.center,
                              style: Brand.text(size: 14, color: Brand.muted),
                            ),
                          ],
                        ),
                      ),
                    for (final (i, g) in groups.indexed) ...[
                      if (i > 0) const SizedBox(height: 14),
                      TransactionDayGroup(day: g.key, items: g.value),
                    ],
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Cuenta c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Eliminar "${c.nombre}"?',
          style: Brand.text(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          'Solo se puede eliminar una cuenta sin movimientos y con saldo en '
          'cero. Si no, puedes marcarla como inactiva al editarla.',
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
      await ref.read(accountsNotifierProvider.notifier).deleteAccount(c.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones de la cuenta',
      color: Brand.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20, color: Brand.ink),
              const SizedBox(width: 12),
              Text('Editar cuenta', style: Brand.text(weight: FontWeight.w600)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Brand.expense),
              const SizedBox(width: 12),
              Text(
                'Eliminar cuenta',
                style: Brand.text(weight: FontWeight.w600, color: Brand.expense),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Brand.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Brand.border),
        ),
        child: const Icon(Icons.more_horiz_rounded, color: Brand.ink),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.saldo,
    required this.ingresos,
    required this.gastos,
  });

  final double saldo;
  final double? ingresos;
  final double? gastos;

  @override
  Widget build(BuildContext context) {
    String fmt(double? v) => v == null ? '—' : _money.format(v);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo actual',
            style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money.format(saldo),
              style: Brand.title(
                size: 32,
                color: saldo < 0 ? Brand.peach : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  label: 'Entró este mes',
                  value: fmt(ingresos),
                  icon: Icons.south_west_rounded,
                  color: Brand.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  label: 'Salió este mes',
                  value: fmt(gastos),
                  icon: Icons.north_east_rounded,
                  color: Brand.peach,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
              Icon(icon, size: 14, color: color),
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
                size: 16,
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
