import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../transactions/transactions_provider.dart';
import 'prestamos_provider.dart';

/// Crear o editar un préstamo. DEUDA = yo debo · PRESTAMO = me deben.
class CreateEditPrestamoScreen extends ConsumerStatefulWidget {
  final Prestamo? prestamo;
  const CreateEditPrestamoScreen({super.key, this.prestamo});

  @override
  ConsumerState<CreateEditPrestamoScreen> createState() =>
      _CreateEditPrestamoScreenState();
}

class _CreateEditPrestamoScreenState
    extends ConsumerState<CreateEditPrestamoScreen> {
  late final _p = widget.prestamo;
  late final _nombreCtrl = TextEditingController(text: _p?.nombre ?? '');
  late final _montoCtrl = TextEditingController(
    text: _p == null ? '' : _p.montoTotal.toStringAsFixed(0),
  );
  late final _tasaCtrl = TextEditingController(
    text: (_p?.tasaInteres ?? 0) > 0 ? _p!.tasaInteres!.toString() : '',
  );
  late final _notasCtrl = TextEditingController(text: _p?.notas ?? '');
  late String _tipo = _p?.tipo ?? 'DEUDA';
  late DateTime _inicio = _p?.fechaInicio ?? DateTime.now();
  late DateTime? _fin = _p?.fechaFin;
  late int? _cuentaId = _p?.cuentaId;
  bool _registrar = false;
  bool _saving = false;

  bool get _debo => _tipo == 'DEUDA';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    final picked = await showBrandPicker<int>(
      context,
      title: 'Cuenta',
      selected: _cuentaId ?? 0,
      options: [
        const BrandOption(0, 'Ninguna'),
        for (final c in cuentas)
          BrandOption(
            c.id,
            c.nombre,
            icon: accountStyle(c.tipo).icon,
            color: accountStyle(c.tipo).fg,
          ),
      ],
    );
    if (picked == null) return;
    setState(() {
      _cuentaId = picked == 0 ? null : picked;
      if (_cuentaId == null) _registrar = false;
    });
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    final monto = parseAmount(_montoCtrl.text);
    final tasaText = _tasaCtrl.text.trim();
    final tasa = tasaText.isEmpty ? null : parseAmount(tasaText);
    if (nombre.isEmpty) {
      showBrandSnack(
        context,
        _debo ? '¿A quién le debes? Escribe un nombre' : '¿Quién te debe? Escribe un nombre',
      );
      return;
    }
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe el monto');
      return;
    }
    if (tasaText.isNotEmpty && (tasa == null || tasa < 0)) {
      showBrandSnack(context, 'La tasa de interés no es válida');
      return;
    }
    if (_fin != null && _fin!.isBefore(_inicio)) {
      showBrandSnack(context, 'La fecha de vencimiento debe ser después del inicio');
      return;
    }
    final notas = _notasCtrl.text.trim();

    setState(() => _saving = true);
    final req = CreatePrestamoRequest(
      nombre: nombre,
      tipo: _tipo,
      montoTotal: monto,
      tasaInteres: tasa,
      fechaInicio: _inicio,
      fechaFin: _fin,
      cuentaId: _cuentaId,
      notas: notas.isEmpty ? null : notas,
      registrarMovimiento: _p == null ? _registrar : null,
    );
    try {
      final notifier = ref.read(prestamosNotifierProvider.notifier);
      if (_p == null) {
        await notifier.create(req);
      } else {
        await notifier.update(_p.id, req);
      }
      if (_p == null && _registrar) {
        await Future.wait([
          ref.read(accountsNotifierProvider.notifier).refresh(),
          ref.read(transactionsNotifierProvider.notifier).refresh(),
        ]);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _p == null ? 'Préstamo registrado' : 'Préstamo actualizado',
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
    final cuentas = (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;

    return BrandFormPage(
      title: _p == null ? 'Nuevo préstamo' : 'Editar préstamo',
      submitLabel: _p == null ? 'Guardar préstamo' : 'Guardar cambios',
      loading: _saving,
      onSubmit: _save,
      children: [
        BrandSegmented<String>(
          options: const [('DEUDA', 'Debo'), ('PRESTAMO', 'Me deben')],
          value: _tipo,
          onChanged: (v) => setState(() => _tipo = v),
        ),
        const SizedBox(height: 20),
        BrandAmountInput(
          controller: _montoCtrl,
          label: _debo ? 'Cuánto debes' : 'Cuánto prestaste',
          color: _debo ? Brand.expense : Brand.accent,
          autofocus: _p == null,
          decimals: true,
        ),
        const SizedBox(height: 24),
        BrandField(
          label: _debo ? '¿A quién le debes?' : '¿Quién te debe?',
          hint: _debo ? 'Ej: Banco, crédito del carro' : 'Ej: Carlos',
          controller: _nombreCtrl,
        ),
        const SizedBox(height: 18),
        BrandGroup(
          children: [
            BrandGroupTextRow(
              label: 'Interés anual',
              controller: _tasaCtrl,
              hint: 'Sin intereses',
              suffix: _tasaCtrl.text.isEmpty ? null : '%',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              ],
            ),
            BrandGroupRow(
              label: 'Inicio',
              value: brandDateLabel(_inicio),
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _inicio,
                  last: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _inicio = d);
              },
            ),
            BrandGroupRow(
              label: 'Vence',
              value: _fin == null ? 'Sin fecha' : brandDateLabel(_fin!),
              placeholder: _fin == null,
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _fin ?? _inicio.add(const Duration(days: 30)),
                  first: _inicio,
                );
                setState(() => _fin = d);
              },
            ),
            BrandGroupRow(
              label: 'Cuenta',
              value: cuenta?.nombre ?? 'Ninguna',
              placeholder: cuenta == null,
              onTap: () => _pickCuenta(cuentas),
            ),
          ],
        ),
        if (_p == null && _cuentaId != null) ...[
          const SizedBox(height: 14),
          BrandGroup(
            children: [
              BrandSwitchRow(
                title: _debo
                    ? 'Registrar el dinero recibido'
                    : 'Registrar el dinero entregado',
                subtitle: _debo
                    ? 'Crea un ingreso en ${cuenta?.nombre ?? 'la cuenta'}. '
                          'Apágalo si es un préstamo antiguo.'
                    : 'Crea un gasto en ${cuenta?.nombre ?? 'la cuenta'}. '
                          'Apágalo si es un préstamo antiguo.',
                value: _registrar,
                onChanged: (v) => setState(() => _registrar = v),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        const BrandLabel('Notas (opcional)'),
        BrandTextArea(controller: _notasCtrl, hint: 'Ej: cuotas de \$200.000 cada mes'),
      ],
    );
  }
}
