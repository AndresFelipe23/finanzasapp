import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import '../categories/category_style.dart';
import '../transactions/transactions_provider.dart';
import 'recurring_provider.dart';
import 'recurring_service.dart';

/// Crear un pago recurrente sin registrar un movimiento (antes solo nacía de
/// "Se repite" en el formulario de gasto o ingreso). El primer cobro define
/// el día del mes o de la semana en que se repite.
class CreateRecurringScreen extends ConsumerStatefulWidget {
  const CreateRecurringScreen({super.key});

  @override
  ConsumerState<CreateRecurringScreen> createState() =>
      _CreateRecurringScreenState();
}

class _CreateRecurringScreenState extends ConsumerState<CreateRecurringScreen> {
  final _montoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _tipo = 'GASTO';
  int? _categoriaId;
  int? _cuentaId;
  String _frecuencia = 'MENSUAL';
  DateTime _inicio = DateTime.now();
  DateTime? _fin;
  bool _saving = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// "Cada mes el día 5", "Cada semana el martes"… a partir del primer cobro.
  String get _resumen {
    final dia = _inicio.day;
    final semana = DateFormat('EEEE', 'es_ES').format(_inicio);
    return switch (_frecuencia) {
      'DIARIO' => 'Todos los días',
      'SEMANAL' => 'Cada semana, el $semana',
      'BIMESTRAL' => 'Cada 2 meses, el día $dia',
      'TRIMESTRAL' => 'Cada 3 meses, el día $dia',
      'SEMESTRAL' => 'Cada 6 meses, el día $dia',
      'ANUAL' => 'Cada año, el ${DateFormat("d 'de' MMMM", 'es_ES').format(_inicio)}',
      _ => 'Cada mes, el día $dia',
    };
  }

  Future<void> _pickCategoria(List<Categoria> categorias) async {
    final id = await showBrandPicker<int>(
      context,
      title: 'Categoría',
      selected: _categoriaId,
      options: [
        for (final c in categorias)
          BrandOption(
            c.id,
            c.nombre,
            icon: categoryIcon(c.icono),
            color: categoryColors(c.color, c.tipo).$1,
          ),
      ],
    );
    if (id != null) setState(() => _categoriaId = id);
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    final id = await showBrandPicker<int>(
      context,
      title: 'Cuenta',
      selected: _cuentaId,
      options: [
        for (final c in cuentas)
          BrandOption(
            c.id,
            c.nombre,
            subtitle: c.moneda,
            icon: accountStyle(c.tipo).icon,
            color: accountStyle(c.tipo).fg,
          ),
      ],
    );
    if (id != null) setState(() => _cuentaId = id);
  }

  Future<void> _save(Categoria? categoria, Cuenta? cuenta) async {
    final monto = parseAmount(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe el monto');
      return;
    }
    if (categoria == null) {
      showBrandSnack(context, 'Elige una categoría');
      return;
    }
    if (cuenta == null) {
      showBrandSnack(context, 'Elige la cuenta donde se registra');
      return;
    }

    setState(() => _saving = true);
    String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    final desc = _descCtrl.text.trim();
    try {
      final service = ref.read(recurringServiceProvider);
      final id = await service.createRule(
        CreatePagoRecurrenteRequest(
          categoriaId: categoria.id,
          cuentaId: cuenta.id,
          monto: monto,
          descripcion: desc.isEmpty ? categoria.nombre : desc,
          frecuencia: _frecuencia,
          diaVencimiento: _frecuencia == 'SEMANAL' || _frecuencia == 'DIARIO'
              ? null
              : _inicio.day,
          diaSemana: _frecuencia == 'SEMANAL' ? _inicio.weekday : null,
          fechaInicio: fmt(_inicio),
          fechaFin: _fin == null ? null : fmt(_fin!),
        ),
      );
      // El Cron corre de madrugada: si el primer cobro es hoy, ya pasó y no
      // se registraría; se registra ahora
      final hoy = DateUtils.isSameDay(_inicio, DateTime.now());
      var registrado = false;
      if (hoy && id != null) {
        try {
          await service.executeNow(id);
          registrado = true;
          ref.read(transactionsNotifierProvider.notifier).refresh();
          ref.read(accountsNotifierProvider.notifier).refresh();
        } catch (_) {
          // El pago quedó creado; el cobro de hoy se puede registrar desde la lista
        }
      }
      ref.invalidate(recurringProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        registrado ? 'Pago recurrente creado y registrado hoy' : 'Pago recurrente creado',
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
        .where((c) => c.activo && (c.tipo == _tipo || c.tipo == 'AMBOS'))
        .toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final cuentas = (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    final categoria = categorias.where((c) => c.id == _categoriaId).firstOrNull;
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull ??
        (cuentas.length == 1 ? cuentas.first : null);
    final ingreso = _tipo == 'INGRESO';

    return BrandFormPage(
      title: 'Nuevo pago recurrente',
      submitLabel: 'Crear pago recurrente',
      loading: _saving,
      onSubmit: () => _save(categoria, cuenta),
      children: [
        BrandSegmented<String>(
          options: const [('GASTO', 'Gasto'), ('INGRESO', 'Ingreso')],
          value: _tipo,
          onChanged: (v) => setState(() {
            _tipo = v;
            _categoriaId = null; // las categorías cambian con el tipo
          }),
        ),
        const SizedBox(height: 20),
        BrandAmountInput(
          controller: _montoCtrl,
          color: ingreso ? Brand.accent : Brand.expense,
          badge: cuenta?.moneda,
          autofocus: true,
          decimals: true,
        ),
        const SizedBox(height: 24),
        BrandGroup(
          children: [
            BrandGroupRow(
              label: 'Categoría',
              value: categoria?.nombre ?? 'Elegir',
              placeholder: categoria == null,
              onTap: () => _pickCategoria(categorias),
            ),
            BrandGroupRow(
              label: 'Cuenta',
              value: cuenta?.nombre ?? 'Elegir',
              placeholder: cuenta == null,
              onTap: cuentas.isEmpty ? null : () => _pickCuenta(cuentas),
            ),
            BrandGroupTextRow(
              label: 'Descripción',
              controller: _descCtrl,
              hint: ingreso ? 'Ej: Salario' : 'Ej: Netflix, arriendo',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const BrandLabel('Se repite'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in PagoRecurrente.frecuencias.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _frecuencia == e.key,
                onSelected: (_) => setState(() => _frecuencia = e.key),
                showCheckmark: false,
                selectedColor: Brand.ink,
                backgroundColor: Brand.surface,
                side: BorderSide(color: _frecuencia == e.key ? Brand.ink : Brand.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                labelStyle: Brand.text(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _frecuencia == e.key ? Colors.white : Brand.ink,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        BrandGroup(
          children: [
            BrandGroupRow(
              label: 'Primer cobro',
              value: brandDateLabel(_inicio),
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _inicio,
                  first: DateTime.now().subtract(const Duration(days: 365)),
                  last: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d != null) setState(() => _inicio = d);
              },
            ),
            BrandGroupRow(
              label: 'Termina',
              value: _fin == null ? 'Nunca' : brandDateLabel(_fin!),
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _fin ?? _inicio.add(const Duration(days: 365)),
                  first: _inicio,
                );
                setState(() => _fin = d);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$_resumen. Se registra solo en cada fecha'
          '${_fin == null ? '' : ' hasta el ${brandDateLabel(_fin!)}'}.',
          style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
        ),
      ],
    );
  }
}
