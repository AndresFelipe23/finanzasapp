import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/presupuesto_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import '../categories/category_style.dart';
import 'presupuestos_provider.dart';

const _periodos = {
  'SEMANAL': 'Semanal',
  'MENSUAL': 'Mensual',
  'ANUAL': 'Anual',
  'PERSONALIZADO': 'Personalizado',
};

/// Crear o editar un presupuesto.
class CreateEditPresupuestoScreen extends ConsumerStatefulWidget {
  final Presupuesto? presupuesto;
  const CreateEditPresupuestoScreen({super.key, this.presupuesto});

  @override
  ConsumerState<CreateEditPresupuestoScreen> createState() =>
      _CreateEditPresupuestoScreenState();
}

class _CreateEditPresupuestoScreenState
    extends ConsumerState<CreateEditPresupuestoScreen> {
  late final _p = widget.presupuesto;
  late final _nombreCtrl = TextEditingController(text: _p?.nombre ?? '');
  late final _montoCtrl = TextEditingController(
    text: _p == null ? '' : _p.montoLimite.toStringAsFixed(0),
  );
  late final _notasCtrl = TextEditingController(text: _p?.notas ?? '');
  late String _periodo = _p?.periodo ?? 'MENSUAL';
  late DateTime _inicio = _p?.fechaInicio ?? DateTime.now();
  late DateTime _fin = _p?.fechaFin ?? DateTime.now();
  late int? _categoriaId = _p?.categoriaId;
  late int? _cuentaId = _p?.cuentaId;
  late bool _nombreEditado = _p != null;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_p == null) _ajustarFechas(DateTime.now());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  /// Fija inicio y fin según el periodo, a partir de [base].
  void _ajustarFechas(DateTime base) {
    switch (_periodo) {
      case 'SEMANAL':
        _inicio = DateTime(base.year, base.month, base.day);
        _fin = _inicio.add(const Duration(days: 6));
      case 'MENSUAL':
        _inicio = DateTime(base.year, base.month, 1);
        _fin = DateTime(base.year, base.month + 1, 0);
      case 'ANUAL':
        _inicio = DateTime(base.year, 1, 1);
        _fin = DateTime(base.year, 12, 31);
      default:
        _inicio = DateTime(base.year, base.month, base.day);
        if (_fin.isBefore(_inicio)) _fin = _inicio.add(const Duration(days: 30));
    }
  }

  Future<void> _pickCategoria(List<Categoria> categorias) async {
    final picked = await showBrandPicker<int>(
      context,
      title: 'Categoría',
      selected: _categoriaId ?? 0,
      options: [
        const BrandOption(0, 'Todos los gastos', subtitle: 'Sin filtrar por categoría'),
        for (final c in categorias)
          BrandOption(
            c.id,
            c.nombre,
            icon: categoryIcon(c.icono),
            color: categoryColors(c.color, c.tipo).$1,
          ),
      ],
    );
    if (picked == null) return;
    setState(() {
      _categoriaId = picked == 0 ? null : picked;
      // Si el usuario no escribió un nombre, usar el de la categoría
      if (!_nombreEditado) {
        _nombreCtrl.text =
            categorias.where((c) => c.id == _categoriaId).firstOrNull?.nombre ?? '';
      }
    });
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    final picked = await showBrandPicker<int>(
      context,
      title: 'Cuenta',
      selected: _cuentaId ?? 0,
      options: [
        const BrandOption(0, 'Todas las cuentas'),
        for (final c in cuentas)
          BrandOption(
            c.id,
            c.nombre,
            icon: accountStyle(c.tipo).icon,
            color: accountStyle(c.tipo).fg,
          ),
      ],
    );
    if (picked != null) setState(() => _cuentaId = picked == 0 ? null : picked);
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    final monto = parseAmount(_montoCtrl.text);
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre al presupuesto');
      return;
    }
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe el límite');
      return;
    }
    if (_fin.isBefore(_inicio)) {
      showBrandSnack(context, 'La fecha final debe ser después de la inicial');
      return;
    }
    final notas = _notasCtrl.text.trim();

    setState(() => _saving = true);
    final req = CreatePresupuestoRequest(
      nombre: nombre,
      periodo: _periodo,
      montoLimite: monto,
      fechaInicio: _inicio,
      // El servidor calcula el fin de los periodos fijos
      fechaFin: _periodo == 'PERSONALIZADO' ? _fin : null,
      categoriaId: _categoriaId,
      cuentaId: _cuentaId,
      notas: notas.isEmpty ? null : notas,
    );
    try {
      final notifier = ref.read(presupuestosNotifierProvider.notifier);
      if (_p == null) {
        await notifier.create(req);
      } else {
        await notifier.update(_p.id, req.toJson());
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _p == null ? 'Presupuesto creado' : 'Presupuesto actualizado',
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
    final categorias = (ref.watch(categoriesNotifierProvider).valueOrNull ?? const <Categoria>[])
        .where((c) => c.activo && c.tipo != 'INGRESO')
        .toList();
    final cuentas = (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    final categoria = categorias.where((c) => c.id == _categoriaId).firstOrNull;
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;

    return BrandFormPage(
      title: _p == null ? 'Nuevo presupuesto' : 'Editar presupuesto',
      submitLabel: _p == null ? 'Crear presupuesto' : 'Guardar cambios',
      loading: _saving,
      onSubmit: _save,
      children: [
        BrandAmountInput(
          controller: _montoCtrl,
          label: 'Límite',
          color: Brand.ink,
          autofocus: _p == null,
          decimals: true,
        ),
        const SizedBox(height: 24),
        BrandGroup(
          children: [
            BrandGroupRow(
              label: 'Categoría',
              value: categoria?.nombre ?? 'Todos los gastos',
              onTap: () => _pickCategoria(categorias),
            ),
            BrandGroupRow(
              label: 'Cuenta',
              value: cuenta?.nombre ?? 'Todas las cuentas',
              onTap: () => _pickCuenta(cuentas),
            ),
          ],
        ),
        const SizedBox(height: 18),
        BrandField(
          label: 'Nombre',
          hint: 'Ej: Comida del mes',
          controller: _nombreCtrl,
          onChanged: (_) => _nombreEditado = true,
        ),
        const SizedBox(height: 18),
        const BrandLabel('Periodo'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _periodos.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _periodo == e.key,
                onSelected: (_) => setState(() {
                  _periodo = e.key;
                  _ajustarFechas(_inicio);
                }),
                showCheckmark: false,
                selectedColor: Brand.ink,
                backgroundColor: Brand.surface,
                side: BorderSide(color: _periodo == e.key ? Brand.ink : Brand.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                labelStyle: Brand.text(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _periodo == e.key ? Colors.white : Brand.ink,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        BrandGroup(
          children: [
            BrandGroupRow(
              label: _periodo == 'PERSONALIZADO' ? 'Desde' : 'Empieza',
              value: brandDateLabel(_inicio),
              onTap: () async {
                final d = await pickBrandDate(context, initial: _inicio);
                if (d != null) setState(() => _ajustarFechas(d));
              },
            ),
            BrandGroupRow(
              label: _periodo == 'PERSONALIZADO' ? 'Hasta' : 'Termina',
              value: brandDateLabel(_fin),
              // Solo el personalizado deja elegir el final
              onTap: _periodo != 'PERSONALIZADO'
                  ? null
                  : () async {
                      final d = await pickBrandDate(
                        context,
                        initial: _fin,
                        first: _inicio,
                      );
                      if (d != null) setState(() => _fin = d);
                    },
            ),
          ],
        ),
        const SizedBox(height: 18),
        const BrandLabel('Notas (opcional)'),
        BrandTextArea(controller: _notasCtrl),
      ],
    );
  }
}
