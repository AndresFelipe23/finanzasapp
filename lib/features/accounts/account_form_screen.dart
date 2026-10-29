import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/utils/monedas_constants.dart';
import '../categories/category_style.dart';
import '../transactions/transactions_provider.dart';
import '../transactions/transactions_service.dart';
import 'account_style.dart';
import 'accounts_provider.dart';

const _tipos = [
  'BANCARIA',
  'EFECTIVO',
  'TARJETA_DEBITO',
  'TARJETA_CREDITO',
  'DIGITAL',
  'AHORRO',
  'INVERSION',
];

// Nombre del ícono guardado en cuentas.icono según el tipo
const _iconoPorTipo = {
  'BANCARIA': 'account_balance',
  'EFECTIVO': 'payments',
  'TARJETA_DEBITO': 'credit_card',
  'TARJETA_CREDITO': 'credit_card',
  'DIGITAL': 'wallet',
  'AHORRO': 'savings',
  'INVERSION': 'trending_up',
};

// USD aparece varias veces (Ecuador, El Salvador, Panamá): una por código
final _monedas = {
  for (final m in MonedasConstants.monedasHispanas) m.codigo: m,
}.values.toList();

/// Crear o editar una cuenta.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.cuenta});

  /// Null para crear una nueva.
  final Cuenta? cuenta;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final _editing = widget.cuenta != null;
  late final _nombreCtrl = TextEditingController(text: widget.cuenta?.nombre ?? '');
  late final _descCtrl = TextEditingController(text: widget.cuenta?.descripcion ?? '');
  late final _saldoCtrl = TextEditingController(
    text: _editing ? widget.cuenta!.saldoInicial.toStringAsFixed(0) : '',
  );
  late String _tipo = widget.cuenta?.tipo ?? 'BANCARIA';
  late String _moneda = widget.cuenta?.moneda ?? 'COP';
  late bool _activa = widget.cuenta?.activa ?? true;
  bool _nombreEditado = false;
  bool _saving = false;

  // Al crear una tarjeta de crédito se pide la deuda; la API no acepta saldo
  // inicial negativo, así que se registra como un gasto de apertura
  bool get _pideDeuda => !_editing && _tipo == 'TARJETA_CREDITO';

  @override
  void initState() {
    super.initState();
    if (!_editing) _nombreCtrl.text = accountStyle(_tipo).label;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTipo() async {
    final picked = await showBrandPicker<String>(
      context,
      title: 'Tipo de cuenta',
      selected: _tipo,
      options: [
        for (final t in _tipos)
          BrandOption(
            t,
            accountStyle(t).label,
            icon: accountStyle(t).icon,
            color: accountStyle(t).fg,
          ),
      ],
    );
    if (picked == null) return;
    setState(() {
      _tipo = picked;
      if (!_editing && !_nombreEditado) _nombreCtrl.text = accountStyle(picked).label;
    });
  }

  Future<void> _pickMoneda() async {
    final picked = await showBrandPicker<String>(
      context,
      title: 'Moneda',
      selected: _moneda,
      options: [
        for (final m in _monedas)
          BrandOption(m.codigo, '${m.nombreMoneda} (${m.codigo})', subtitle: m.pais),
      ],
    );
    if (picked != null) setState(() => _moneda = picked);
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre a la cuenta');
      return;
    }
    final monto = parseAmount(_saldoCtrl.text) ?? 0;
    if (monto < 0) {
      showBrandSnack(context, 'El monto no puede ser negativo');
      return;
    }
    final desc = _descCtrl.text.trim();
    final color = colorToHex(accountStyle(_tipo).fg);

    setState(() => _saving = true);
    final notifier = ref.read(accountsNotifierProvider.notifier);
    try {
      if (_editing) {
        await notifier.updateAccount(
          widget.cuenta!.id,
          UpdateCuentaRequest(
            nombre: nombre,
            tipo: _tipo,
            moneda: _moneda,
            saldoInicial: monto,
            color: color,
            icono: _iconoPorTipo[_tipo],
            descripcion: desc.isEmpty ? null : desc,
            activa: _activa,
          ),
        );
      } else {
        final cuenta = await ref.read(accountsServiceProvider).createAccount(
          CreateCuentaRequest(
            nombre: nombre,
            tipo: _tipo,
            moneda: _moneda,
            saldoInicial: _pideDeuda ? 0 : monto,
            color: color,
            icono: _iconoPorTipo[_tipo],
            descripcion: desc.isEmpty ? null : desc,
          ),
        );
        if (_pideDeuda && monto > 0) {
          await TransactionsService(ApiClient()).createTransaction(
            CreateTransaccionRequest(
              cuentaId: cuenta.id,
              tipoTransaccionId: 2, // GASTO
              monto: monto,
              moneda: _moneda,
              titulo: 'Deuda inicial de la tarjeta',
              fechaTransaccion: DateTime.now(),
            ),
          );
          await ref.read(transactionsNotifierProvider.notifier).refresh();
        }
        await notifier.refresh();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _editing ? 'Cuenta actualizada' : 'Cuenta creada',
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
    final style = accountStyle(_tipo);
    final moneda = MonedasConstants.getMonedaPorCodigo(_moneda);

    return BrandFormPage(
      title: _editing ? 'Editar cuenta' : 'Nueva cuenta',
      submitLabel: _editing ? 'Guardar cambios' : 'Crear cuenta',
      loading: _saving,
      onSubmit: _save,
      children: [
        // Vista previa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Brand.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Brand.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(style.icon, color: style.fg, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombreCtrl.text.trim().isEmpty
                          ? 'Tu cuenta'
                          : _nombreCtrl.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(size: 17, weight: FontWeight.w800),
                    ),
                    Text(
                      '${style.label} · $_moneda',
                      style: Brand.text(size: 12, color: Brand.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        BrandField(
          label: 'Nombre',
          controller: _nombreCtrl,
          onChanged: (_) => setState(() => _nombreEditado = true),
        ),
        const SizedBox(height: 18),
        BrandGroup(
          children: [
            BrandGroupRow(label: 'Tipo', value: style.label, onTap: _pickTipo),
            BrandGroupRow(
              label: 'Moneda',
              value: moneda == null ? _moneda : '${moneda.nombreMoneda} ($_moneda)',
              onTap: _pickMoneda,
            ),
          ],
        ),
        const SizedBox(height: 24),
        BrandAmountInput(
          controller: _saldoCtrl,
          label: _pideDeuda ? 'Deuda actual' : 'Saldo inicial',
          color: _pideDeuda ? Brand.expense : Brand.ink,
          decimals: true,
          badge: _moneda,
        ),
        const SizedBox(height: 6),
        Text(
          _pideDeuda
              ? 'Lo que debes hoy en la tarjeta. Usa 0 si está al corriente.'
              : _editing
              ? 'Cambiarlo ajusta el saldo actual en la misma diferencia.'
              : 'El dinero que tienes hoy en esta cuenta.',
          textAlign: TextAlign.center,
          style: Brand.text(size: 12, color: Brand.muted),
        ),
        const SizedBox(height: 24),
        const BrandLabel('Descripción (opcional)'),
        BrandTextArea(controller: _descCtrl, hint: 'Ej: cuenta de nómina'),
        if (_editing) ...[
          const SizedBox(height: 18),
          BrandGroup(
            children: [
              BrandSwitchRow(
                title: 'Cuenta activa',
                subtitle: 'Las inactivas no aparecen al registrar movimientos '
                    'ni suman al saldo total',
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
