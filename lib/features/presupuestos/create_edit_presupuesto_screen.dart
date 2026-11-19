import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/presupuesto_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import '../transactions/form_panel.dart';
import 'presupuestos_provider.dart';

const _periodos = [
  ('SEMANAL', 'Semana'),
  ('MENSUAL', 'Mes'),
  ('ANUAL', 'Año'),
  ('PERSONALIZADO', 'Otro'),
];

/// Verde oscuro de la marca: el de las tarjetas de resumen del inicio.
const _tone = Brand.deep;

/// Crear o editar un presupuesto, con el diseño del formulario de
/// movimientos: panel con el periodo, el nombre, el límite y las categorías;
/// botones de cuenta, fechas y nota; y el teclado propio abajo.
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
  late final _nombreCtrl = TextEditingController(text: _p?.nombre ?? 'Todos los gastos');
  final _nombreFocus = FocusNode();
  final _monto = AmountEntry();
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
    _monto.set(_p?.montoLimite);
    if (_p == null) _ajustarFechas(DateTime.now());
    _notasCtrl.addListener(() => setState(() {})); // "Nota" en el botón
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreFocus.dispose();
    _monto.dispose();
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

  void _setCategoria(int? id, List<Categoria> categorias) {
    setState(() {
      _categoriaId = id;
      // Si el usuario no escribió un nombre, usar el de la categoría
      if (!_nombreEditado) {
        _nombreCtrl.text =
            categorias.where((c) => c.id == id).firstOrNull?.nombre ?? 'Todos los gastos';
      }
    });
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    _nombreFocus.unfocus();
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
    final monto = _monto.value;
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre al presupuesto');
      _nombreFocus.requestFocus();
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

  /// "1 – 30 nov 2026", "3 – 9 nov 2026", "2026".
  String _rango() {
    if (_periodo == 'ANUAL' && _inicio.month == 1 && _inicio.day == 1) {
      return '${_inicio.year}';
    }
    final mismoMes = _inicio.year == _fin.year && _inicio.month == _fin.month;
    final ini = DateFormat(mismoMes ? 'd' : 'd MMM', 'es_ES').format(_inicio);
    return '$ini – ${DateFormat('d MMM y', 'es_ES').format(_fin)}';
  }

  @override
  Widget build(BuildContext context) {
    final categorias = (ref.watch(categoriesNotifierProvider).valueOrNull ?? const <Categoria>[])
        .where((c) => c.activo && c.tipo != 'INGRESO')
        .toList();
    final cuentas = (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;
    final notas = _notasCtrl.text.trim();
    // Moneda de la cuenta elegida (sin cuenta, la de la mayoría: COP)
    final moneda = cuenta?.moneda ?? 'COP';

    return Scaffold(
      backgroundColor: Brand.bg,
      // El teclado del sistema (al escribir el nombre) se pone encima del
      // teclado de números en vez de encoger la pantalla y aplastarlo
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel: periodo, nombre, límite y categorías ────────────
              FormPanel(
                color: _tone,
                children: [
                  Row(
                    children: [
                      PanelCircleButton(
                        icon: Icons.close_rounded,
                        label: 'Cerrar',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: PanelTabs<String>(
                              options: _periodos,
                              value: _periodo,
                              tone: _tone,
                              onChanged: (v) => setState(() {
                                _periodo = v;
                                _ajustarFechas(_inicio);
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nombreCtrl,
                    focusNode: _nombreFocus,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _nombreEditado = true,
                    // Al terminar el nombre se cierra el teclado del sistema
                    // y queda el propio para el límite
                    onSubmitted: (_) => _nombreFocus.unfocus(),
                    cursorColor: Colors.white,
                    style: Brand.text(size: 18, weight: FontWeight.w800, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Nombre del presupuesto',
                      hintStyle: Brand.text(
                        size: 18,
                        weight: FontWeight.w700,
                        color: const Color(0x99FFFFFF),
                      ),
                      filled: true,
                      fillColor: const Color(0x29FFFFFF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  PanelAmount(
                    entry: _monto,
                    label: 'Puedo gastar como máximo',
                  ),
                  Text(
                    _rango(),
                    textAlign: TextAlign.center,
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(0xD9FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Todos" y las categorías de gasto, deslizables
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: categorias.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = i == 0 ? null : categorias[i - 1];
                        return PanelPill(
                          label: c?.nombre ?? 'Todos los gastos',
                          selected: c?.id == _categoriaId,
                          tone: _tone,
                          onTap: () => _setCategoria(c?.id, categorias),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Cuenta · Fechas · Nota ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: cuenta == null
                          ? Icons.account_balance_wallet_outlined
                          : accountStyle(cuenta.tipo).icon,
                      label: cuenta?.nombre ?? 'Todas',
                      highlighted: cuenta != null,
                      onTap: () => _pickCuenta(cuentas),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.calendar_today_outlined,
                      label: 'Fechas',
                      highlighted: _periodo == 'PERSONALIZADO',
                      onTap: _abrirFechas,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: notas.isEmpty ? 'Nota' : notas,
                      highlighted: notas.isNotEmpty,
                      onTap: _abrirNota,
                    ),
                  ),
                ],
              ),
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
                  label: _monto.isEmpty
                      ? 'Escribe el límite'
                      : _p == null
                      ? 'Crear presupuesto'
                      : 'Guardar cambios',
                  background: Brand.ink,
                  loading: _saving,
                  onPressed: _monto.isEmpty ? null : _save,
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
    _nombreFocus.unfocus();
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

  Future<void> _abrirFechas() => _hoja(
    'Fechas',
    (update) {
      final personalizado = _periodo == 'PERSONALIZADO';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandGroup(
            children: [
              BrandGroupRow(
                label: personalizado ? 'Desde' : 'Empieza',
                value: brandDateLabel(_inicio),
                onTap: () async {
                  final d = await pickBrandDate(context, initial: _inicio);
                  if (d != null) update(() => _ajustarFechas(d));
                },
              ),
              BrandGroupRow(
                label: personalizado ? 'Hasta' : 'Termina',
                value: brandDateLabel(_fin),
                // Solo el personalizado deja elegir el final
                onTap: !personalizado
                    ? null
                    : () async {
                        final d = await pickBrandDate(context, initial: _fin, first: _inicio);
                        if (d != null) update(() => _fin = d);
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            personalizado
                ? 'Elige el inicio y el final del presupuesto.'
                : 'El final se calcula con el periodo. Para elegirlo, usa "Otro".',
            style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
          ),
        ],
      );
    },
  );

  Future<void> _abrirNota() => _hoja(
    'Nota',
    (update) => BrandTextArea(controller: _notasCtrl, hint: '¿Para qué es este presupuesto?'),
  );
}
