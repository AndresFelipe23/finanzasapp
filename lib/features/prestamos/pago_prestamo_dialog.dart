import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../transactions/transactions_provider.dart';
import 'prestamos_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Registrar un pago (si debo) o un cobro (si me deben).
class PagoPrestamoDialog extends ConsumerStatefulWidget {
  final Prestamo prestamo;
  const PagoPrestamoDialog({super.key, required this.prestamo});

  @override
  ConsumerState<PagoPrestamoDialog> createState() => _PagoPrestamoDialogState();
}

class _PagoPrestamoDialogState extends ConsumerState<PagoPrestamoDialog> {
  final _montoCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  late int? _cuentaId = widget.prestamo.cuentaId;
  DateTime _fecha = DateTime.now();
  bool _saving = false;

  bool get _debo => widget.prestamo.tipo == 'DEUDA';

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    final picked = await showBrandPicker<int>(
      context,
      title: _debo ? '¿De dónde sale el pago?' : '¿A dónde entra el dinero?',
      selected: _cuentaId ?? 0,
      options: [
        const BrandOption(0, 'Sin cuenta', subtitle: 'Solo baja el saldo pendiente'),
        for (final c in cuentas)
          BrandOption(
            c.id,
            c.nombre,
            subtitle: 'Saldo ${_money.format(c.saldoActual ?? c.saldoInicial)}',
            icon: accountStyle(c.tipo).icon,
            color: accountStyle(c.tipo).fg,
          ),
      ],
    );
    if (picked != null) setState(() => _cuentaId = picked == 0 ? null : picked);
  }

  Future<void> _save() async {
    final p = widget.prestamo;
    final monto = parseAmount(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe el monto');
      return;
    }
    if (monto > p.saldoPendiente + 0.01) {
      showBrandSnack(
        context,
        'El monto supera lo pendiente (${_money.format(p.saldoPendiente)})',
      );
      return;
    }

    setState(() => _saving = true);
    final nota = _notaCtrl.text.trim();
    try {
      await ref.read(prestamosNotifierProvider.notifier).crearPago(
        CreatePagoPrestamoRequest(
          prestamoId: p.id,
          monto: monto,
          fechaPago: _fecha,
          cuentaId: _cuentaId,
          notas: nota.isEmpty ? null : nota,
        ),
      );
      // Con cuenta, el pago crea un movimiento y cambia su saldo
      if (_cuentaId != null) {
        await Future.wait([
          ref.read(accountsNotifierProvider.notifier).refresh(),
          ref.read(transactionsNotifierProvider.notifier).refresh(),
        ]);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _debo ? 'Pago registrado' : 'Cobro registrado',
        error: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    final cuentas = (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;

    Widget quick(String label, double fraction) => Expanded(
      child: OutlinedButton(
        onPressed: () => setState(
          () => _montoCtrl.text = (p.saldoPendiente * fraction).toStringAsFixed(0),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Brand.ink,
          backgroundColor: Brand.surface,
          side: const BorderSide(color: Brand.border),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: Brand.text(size: 13, weight: FontWeight.w700)),
      ),
    );

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
            Text(
              _debo ? 'Registrar pago' : 'Registrar cobro',
              style: Brand.text(size: 13, color: Brand.muted),
            ),
            const SizedBox(height: 2),
            Text(
              p.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Brand.text(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Pendiente: ${_money.format(p.saldoPendiente)}',
              style: Brand.text(size: 13, color: Brand.muted),
            ),
            const SizedBox(height: 20),
            BrandAmountInput(
              controller: _montoCtrl,
              color: _debo ? Brand.expense : Brand.accent,
              autofocus: true,
              decimals: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                quick('25%', 0.25),
                const SizedBox(width: 8),
                quick('50%', 0.5),
                const SizedBox(width: 8),
                quick('Todo', 1),
              ],
            ),
            const SizedBox(height: 16),
            BrandGroup(
              children: [
                BrandGroupRow(
                  label: _debo ? 'Desde' : 'Hacia',
                  value: cuenta?.nombre ?? 'Sin cuenta',
                  placeholder: cuenta == null,
                  onTap: () => _pickCuenta(cuentas),
                ),
                BrandGroupRow(
                  label: 'Fecha',
                  value: brandDateLabel(_fecha),
                  onTap: () async {
                    final d = await pickBrandDate(
                      context,
                      initial: _fecha,
                      last: DateTime.now(),
                    );
                    if (d != null) setState(() => _fecha = d);
                  },
                ),
                BrandGroupTextRow(label: 'Nota', controller: _notaCtrl, hint: 'Opcional'),
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
                    label: _debo ? 'Pagar' : 'Registrar',
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
