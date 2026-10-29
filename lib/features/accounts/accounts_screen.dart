import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/theme/brand.dart';
import 'account_style.dart';
import 'account_transactions_screen.dart';
import 'accounts_provider.dart';
import 'create_account_screen.dart';
import '../../core/currency/exchange_rates.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

double _saldo(Cuenta c) => c.saldoActual ?? c.saldoInicial;

// ─── Cuentas ──────────────────────────────────────────────────────────────────
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(accountsNotifierProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () => ref.read(accountsNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  if (canPop) ...[
                    const BrandBackButton(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Text('Cuentas', style: Brand.title(size: 26))),
                  _PillButton(
                    label: 'Nueva',
                    onTap: () => _push(context, const CreateAccountScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...cuentasAsync.when(
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
                    title: 'No se pudieron cargar tus cuentas',
                    body: 'Revisa tu conexión y desliza hacia abajo para '
                        'reintentar.',
                  ),
                ],
                data: (all) => _content(context, ref, all),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, List<Cuenta> all) {
    if (all.isEmpty) {
      return [
        const _Message(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Aún no tienes cuentas',
          body: 'Agrega tu cuenta bancaria, efectivo o tarjetas para llevar '
              'el saldo de cada una.',
        ),
      ];
    }

    final activas = all.where((c) => c.activa).toList()
      ..sort((a, b) => _saldo(b).compareTo(_saldo(a)));
    final inactivas = all.where((c) => !c.activa).toList();
    final monedas = activas.map((c) => c.moneda).toSet().length;
    // Con cuentas en otras monedas el total se convierte a la predeterminada
    final base = ref.watch(monedaBaseProvider);
    final otras = activas.map((c) => c.moneda).where((m) => m != base).toSet();
    final tasas = otras.isEmpty
        ? Tasas.sinDatos(base)
        : ref.watch(tasasProvider).valueOrNull ?? Tasas.sinDatos(base);
    final sinTasa = otras.where((m) => !tasas.puede(m)).toList();
    final total = activas.fold<double>(0, (s, c) => s + tasas.aBase(_saldo(c), c.moneda));

    // La de mayor saldo se destaca arriba, como la cuenta principal del diseño
    final destacada = activas.isNotEmpty && _saldo(activas.first) > 0
        ? activas.first
        : null;
    final resto = activas.where((c) => c != destacada).toList();

    void open(Cuenta c) => _push(context, AccountTransactionsScreen(cuenta: c));

    return [
      Text('Patrimonio neto', style: Brand.text(size: 13, color: Brand.muted)),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          _money.format(total),
          style: Brand.title(
            size: 32,
            color: total < 0 ? Brand.expense : Brand.ink,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${activas.length} ${activas.length == 1 ? 'cuenta' : 'cuentas'}'
        '${monedas > 1 ? ' · $monedas monedas' : ''}',
        style: Brand.text(size: 13, color: Brand.muted),
      ),
      if (otras.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          sinTasa.isEmpty
              ? 'En $base: ${otras.join(', ')} convertido con la tasa del día.'
              : 'Sin tasa de cambio para ${sinTasa.join(', ')}: se suma sin convertir.',
          style: Brand.text(size: 12, color: Brand.muted),
        ),
      ],
      const SizedBox(height: 18),
      if (destacada != null) ...[
        _FeaturedCard(cuenta: destacada, onTap: () => open(destacada)),
        const SizedBox(height: 12),
      ],
      for (final c in resto)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AccountRow(cuenta: c, onTap: () => open(c)),
        ),
      if (inactivas.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          child: Text(
            'INACTIVAS · ${inactivas.length}',
            style: Brand.text(
              size: 12,
              weight: FontWeight.w700,
              color: Brand.muted,
              letterSpacing: 0.7,
            ),
          ),
        ),
        for (final c in inactivas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AccountRow(cuenta: c, onTap: () => open(c)),
          ),
      ],
    ];
  }
}

// ─── Componentes ──────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.cuenta, required this.onTap});

  final Cuenta cuenta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = accountStyle(cuenta.tipo);
    return Material(
      color: Brand.accent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cuenta.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A5C42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Mayor saldo',
                      style: Brand.text(
                        size: 12,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money.format(_saldo(cuenta)),
                  style: Brand.title(size: 28, color: Colors.white),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${style.label} · ${cuenta.moneda}',
                style: Brand.text(
                  size: 13,
                  color: const Color(0xFFCBE7DA),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.cuenta, required this.onTap});

  final Cuenta cuenta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = accountStyle(cuenta.tipo);
    final saldo = _saldo(cuenta);
    final inactive = !cuenta.activa;
    final fg = inactive ? Brand.muted : style.fg;
    final bg = inactive ? Brand.track : style.bg;

    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(style.icon, size: 22, color: fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cuenta.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(
                        weight: FontWeight.w700,
                        color: inactive ? Brand.muted : Brand.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${style.label} · ${cuenta.moneda}'
                      '${inactive ? ' · Inactiva' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(size: 12, color: Brand.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money.format(saldo),
                style: Brand.text(
                  weight: FontWeight.w700,
                  color: saldo < 0 ? Brand.expense : Brand.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
