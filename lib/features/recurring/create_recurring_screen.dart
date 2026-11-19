import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import '../transactions/form_panel.dart';
import '../transactions/transactions_provider.dart';
import 'recurring_provider.dart';
import 'recurring_service.dart';

/// Crear un pago recurrente sin registrar un movimiento (antes solo nacía de
/// "Se repite" en el formulario de gasto o ingreso). El primer cobro define
/// el día del mes o de la semana en que se repite. Tiene el diseño del
/// formulario de movimientos: panel con tipo, monto y categorías; botones de
/// cuenta, repetición y nota; y el teclado propio abajo.
class CreateRecurringScreen extends ConsumerStatefulWidget {
  const CreateRecurringScreen({super.key});

  @override
  ConsumerState<CreateRecurringScreen> createState() =>
      _CreateRecurringScreenState();
}

class _CreateRecurringScreenState extends ConsumerState<CreateRecurringScreen> {
  final _monto = AmountEntry();
  final _descCtrl = TextEditingController();
  String _tipo = 'GASTO';
  int? _categoriaId;
  int? _cuentaId;
  String _frecuencia = 'MENSUAL';
  DateTime _inicio = DateTime.now();
  DateTime? _fin;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _descCtrl.addListener(() => setState(() {})); // la nota en el botón
  }

  @override
  void dispose() {
    _monto.dispose();
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
    final monto = _monto.value;
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
    final tone = ingreso ? Brand.accent : Brand.expense;
    final moneda = cuenta?.moneda ?? 'COP';
    final desc = _descCtrl.text.trim();

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel: tipo, monto, repetición y categorías ────────────
              FormPanel(
                color: tone,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PanelCircleButton(
                        icon: Icons.close_rounded,
                        label: 'Cerrar',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      PanelTabs<String>(
                        options: const [('GASTO', 'Gasto'), ('INGRESO', 'Ingreso')],
                        value: _tipo,
                        tone: tone,
                        onChanged: (v) => setState(() {
                          _tipo = v;
                          _categoriaId = null; // las categorías cambian con el tipo
                        }),
                      ),
                      PanelBadge(moneda),
                    ],
                  ),
                  PanelAmount(
                    entry: _monto,
                    sign: ingreso ? '+' : '−',
                    label: categoria == null
                        ? (ingreso ? 'Ingreso que se repite' : 'Gasto que se repite')
                        : '${ingreso ? 'Ingreso' : 'Gasto'} en ${categoria.nombre}',
                  ),
                  Text(
                    '$_resumen'
                    '${_fin == null ? '' : ' · hasta el ${DateFormat('d MMM y', 'es_ES').format(_fin!)}'}',
                    textAlign: TextAlign.center,
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xD9FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (categorias.isEmpty)
                    Text(
                      'No tienes categorías de este tipo. Créalas en Perfil → Categorías.',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 13, color: Colors.white),
                    )
                  else
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: categorias.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = categorias[i];
                          return PanelPill(
                            label: c.nombre,
                            selected: c.id == _categoriaId,
                            tone: tone,
                            onTap: () => setState(() => _categoriaId = c.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Cuenta · Se repite · Nota ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: cuenta == null
                          ? Icons.account_balance_wallet_outlined
                          : accountStyle(cuenta.tipo).icon,
                      label: cuenta?.nombre ?? 'Cuenta',
                      onTap: cuentas.isEmpty ? null : () => _pickCuenta(cuentas),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.repeat_rounded,
                      label: PagoRecurrente.frecuencias[_frecuencia] ?? 'Se repite',
                      highlighted: true,
                      onTap: _abrirRepeticion,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: desc.isEmpty ? 'Nota' : desc,
                      highlighted: desc.isNotEmpty,
                      onTap: () => _abrirNota(ingreso),
                    ),
                  ),
                ],
              ),
              if (cuentas.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Primero crea una cuenta en Perfil → Mis cuentas.',
                  style: Brand.text(size: 12, color: Brand.expense),
                ),
              ],
              const SizedBox(height: 14),

              // ── Teclado (llena el espacio) y guardar ───────────────────
              Expanded(
                child: AmountKeypad(
                  entry: _monto,
                  decimals: monedaConCentavos(moneda),
                  expand: true,
                ),
              ),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: _monto,
                builder: (_, __) => BrandButton(
                  label: _monto.isEmpty ? 'Escribe un monto' : 'Crear pago recurrente',
                  background: Brand.ink,
                  loading: _saving,
                  onPressed: _monto.isEmpty ? null : () => _save(categoria, cuenta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hoja inferior con el título y el contenido, como "Detalles" en el
  /// formulario de movimientos.
  Future<void> _hoja(String titulo, Widget Function(void Function(VoidCallback)) contenido) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Brand.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          // Cambia el formulario y vuelve a pintar la hoja
          void update(VoidCallback f) {
            setState(f);
            setSheet(() {});
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
            child: SafeArea(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Text(titulo, style: Brand.text(size: 20, weight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    contenido(update),
                    const SizedBox(height: 16),
                    BrandButton(
                      label: 'Listo',
                      background: Brand.ink,
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirRepeticion() => _hoja(
    'Se repite',
    (update) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in PagoRecurrente.frecuencias.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _frecuencia == e.key,
                onSelected: (_) => update(() => _frecuencia = e.key),
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
                if (d != null) update(() => _inicio = d);
              },
            ),
            BrandGroupRow(
              label: 'Termina',
              value: _fin == null ? 'Nunca' : brandDateLabel(_fin!),
              placeholder: _fin == null,
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _fin ?? _inicio.add(const Duration(days: 365)),
                  first: _inicio,
                );
                update(() => _fin = d);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$_resumen. Se registra solo en cada fecha'
          '${_fin == null ? '' : ' hasta el ${brandDateLabel(_fin!)}'}.',
          style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
        ),
      ],
    ),
  );

  Future<void> _abrirNota(bool ingreso) => _hoja(
    'Descripción',
    (update) => BrandGroup(
      children: [
        BrandGroupTextRow(
          label: 'Descripción',
          controller: _descCtrl,
          hint: ingreso ? 'Ej: Salario' : 'Ej: Netflix, arriendo',
        ),
      ],
    ),
  );
}
