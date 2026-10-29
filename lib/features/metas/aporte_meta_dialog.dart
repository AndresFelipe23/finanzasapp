import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/meta_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../transactions/transactions_provider.dart';
import 'metas_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Abonar dinero a una meta. Si se elige una cuenta, el dinero sale de ella.
class AporteMetaDialog extends ConsumerStatefulWidget {
  final Meta meta;
  const AporteMetaDialog({super.key, required this.meta});

  @override
  ConsumerState<AporteMetaDialog> createState() => _AporteMetaDialogState();
}

class _AporteMetaDialogState extends ConsumerState<AporteMetaDialog> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  Cuenta? _cuenta;
  bool _saving = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  double _saldo(Cuenta c) => c.saldoActual ?? c.saldoInicial;

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    final picked = await showBrandPicker<int>(
      context,
      title: '¿De dónde sale el dinero?',
      selected: _cuenta?.id ?? 0,
      options: [
        const BrandOption(0, 'Sin cuenta',
            subtitle: 'Solo suma a la meta, no mueve saldo'),
        for (final c in cuentas)
          BrandOption(
            c.id,
            c.nombre,
            subtitle: 'Saldo ${_money.format(_saldo(c))}',
            icon: accountStyle(c.tipo).icon,
            color: accountStyle(c.tipo).fg,
          ),
      ],
    );
    if (picked == null) return;
    setState(() => _cuenta = cuentas.where((c) => c.id == picked).firstOrNull);
  }

  Future<void> _save() async {
    final monto = parseAmount(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe cuánto vas a abonar');
      return;
    }
    final cuenta = _cuenta;
    if (cuenta != null && cuenta.tipo != 'TARJETA_CREDITO' && monto > _saldo(cuenta)) {
      showBrandSnack(
        context,
        'Saldo insuficiente en ${cuenta.nombre}: tienes ${_money.format(_saldo(cuenta))}',
      );
      return;
    }

    setState(() => _saving = true);
    final nota = _notaCtrl.text.trim();
    try {
      await ref.read(metasNotifierProvider.notifier).hacerAporte(
        AporteMetaRequest(
          metaId: widget.meta.id,
          cuentaId: cuenta?.id,
          montoAporte: monto,
          notas: nota.isEmpty ? null : nota,
        ),
      );
      // Con cuenta, el aporte crea un movimiento y cambia su saldo
      if (cuenta != null) {
        await Future.wait([
          ref.read(accountsNotifierProvider.notifier).refresh(),
          ref.read(transactionsNotifierProvider.notifier).refresh(),
        ]);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      showBrandSnack(context, 'Abonaste ${_money.format(monto)}', error: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meta;
    final cuentas = (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();

    return Dialog(
      backgroundColor: Brand.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Abonar a meta', style: Brand.text(size: 13, color: Brand.muted)),
            const SizedBox(height: 2),
            Text(
              m.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Brand.text(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Faltan ${_money.format(m.faltante)} de ${_money.format(m.montoObjetivo)}',
              style: Brand.text(size: 13, color: Brand.muted),
            ),
            const SizedBox(height: 20),
            BrandAmountInput(
              controller: _montoCtrl,
              label: 'Monto',
              color: Brand.accent,
              autofocus: true,
              decimals: true,
            ),
            if (m.faltante > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(
                    () => _montoCtrl.text = m.faltante.toStringAsFixed(0),
                  ),
                  child: Text(
                    'Completar la meta (${_money.format(m.faltante)})',
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Brand.accent,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            BrandGroup(
              children: [
                BrandGroupRow(
                  label: 'Desde',
                  value: _cuenta?.nombre ?? 'Sin cuenta',
                  placeholder: _cuenta == null,
                  onTap: () => _pickCuenta(cuentas),
                ),
                BrandGroupTextRow(
                  label: 'Nota',
                  controller: _notaCtrl,
                  hint: 'Opcional',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(minimumSize: const Size(0, 56)),
                    child: Text(
                      'Cancelar',
                      style: Brand.text(weight: FontWeight.w700, color: Brand.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: BrandButton(
                    label: 'Abonar',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
