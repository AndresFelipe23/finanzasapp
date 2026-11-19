import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/meta_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../transactions/form_panel.dart';
import 'metas_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Morado de ahorro: el mismo de los aportes a metas en los movimientos.
const _tone = Color(0xFF6B3FA0);

/// Crear o editar una meta de ahorro, con el diseño del formulario de
/// movimientos: panel de color con el nombre y el monto, botones de fecha,
/// aporte automático y nota, y el teclado propio abajo.
class CreateMetaScreen extends ConsumerStatefulWidget {
  final Meta? metaToEdit;
  const CreateMetaScreen({super.key, this.metaToEdit});

  @override
  ConsumerState<CreateMetaScreen> createState() => _CreateMetaScreenState();
}

class _CreateMetaScreenState extends ConsumerState<CreateMetaScreen> {
  late final _meta = widget.metaToEdit;
  late final _nombreCtrl = TextEditingController(text: _meta?.nombre ?? '');
  final _nombreFocus = FocusNode();
  late final _descCtrl = TextEditingController(text: _meta?.descripcion ?? '');
  final _monto = AmountEntry();
  late DateTime _fecha = _meta?.fechaObjetivo ??
      DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);
  bool _saving = false;

  // Aporte automático: porcentaje de cada ingreso y mínimo para que aplique
  late bool _auto = _meta?.tieneAporteAuto ?? false;
  late final _pctCtrl = TextEditingController(
    text: _meta?.aporteAutoPorcentaje == null
        ? '10'
        : NumberFormat('0.##', 'es_CO').format(_meta!.aporteAutoPorcentaje),
  );
  late final _minCtrl = TextEditingController(
    text: _meta?.aporteAutoMinimo == null ? '' : _meta!.aporteAutoMinimo!.toStringAsFixed(0),
  );

  @override
  void initState() {
    super.initState();
    _monto.set(_meta?.montoObjetivo);
    _pctCtrl.addListener(() => setState(() {})); // "Aparta X%" en el botón
    _descCtrl.addListener(() => setState(() {})); // la nota en el botón
    // Meta nueva: se empieza por el nombre
    if (_meta == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nombreFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreFocus.dispose();
    _descCtrl.dispose();
    _monto.dispose();
    _pctCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  /// Cuánto habría que ahorrar al mes para llegar a la fecha.
  double? _mensual() {
    final objetivo = _monto.value;
    if (objetivo == null || objetivo <= 0) return null;
    final faltante = objetivo - (_meta?.montoActual ?? 0);
    if (faltante <= 0) return 0;
    final now = DateTime.now();
    final meses = (_fecha.year - now.year) * 12 + _fecha.month - now.month;
    return faltante / (meses < 1 ? 1 : meses);
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    final monto = _monto.value;
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre a tu meta');
      _nombreFocus.requestFocus();
      return;
    }
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe cuánto quieres ahorrar');
      return;
    }
    final desc = _descCtrl.text.trim();
    final pct = parseAmount(_pctCtrl.text);
    final minimo = parseAmount(_minCtrl.text);
    if (_auto && (pct == null || pct <= 0 || pct > 100)) {
      showBrandSnack(context, 'El porcentaje a apartar va de 0,01 a 100');
      return;
    }

    setState(() => _saving = true);
    final request = CreateMetaRequest(
      nombre: nombre,
      descripcion: desc.isEmpty ? null : desc,
      montoObjetivo: monto,
      fechaObjetivo: _fecha,
      // El color se asigna en la lista; se conservan los que ya tenía
      color: _meta?.color,
      icono: _meta?.icono,
      // Siempre se envía: apagar el interruptor desactiva la regla
      aporteAuto: true,
      aporteAutoPorcentaje: _auto ? pct : null,
      aporteAutoMinimo: _auto && minimo != null && minimo > 0 ? minimo : null,
    );
    try {
      final notifier = ref.read(metasNotifierProvider.notifier);
      if (_meta != null) {
        await notifier.updateMeta(_meta.id, request);
      } else {
        await notifier.create(request);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _meta != null ? 'Meta actualizada' : 'Meta creada',
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
    final llevas = _meta?.montoActual ?? 0;
    final pct = parseAmount(_pctCtrl.text);
    final desc = _descCtrl.text.trim();

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
              // ── Panel: nombre, monto y plan ────────────────────────────
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
                      Expanded(
                        child: Text(
                          _meta != null ? 'Editar meta' : 'Nueva meta',
                          textAlign: TextAlign.center,
                          style: Brand.text(
                            size: 16,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.savings_outlined, color: Colors.white),
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
                    // Al terminar el nombre se cierra el teclado del sistema
                    // y queda el propio para el monto
                    onSubmitted: (_) => _nombreFocus.unfocus(),
                    cursorColor: Colors.white,
                    style: Brand.text(size: 18, weight: FontWeight.w800, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '¿Para qué ahorras?',
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
                    label: llevas > 0
                        ? 'Meta · ya llevas ${_money.format(llevas)}'
                        : 'Quiero ahorrar',
                  ),
                  // Se recalcula al escribir el monto o cambiar la fecha
                  ListenableBuilder(
                    listenable: _monto,
                    builder: (_, __) {
                      final m = _mensual();
                      return Text(
                        m == null
                            ? 'Escribe cuánto quieres ahorrar'
                            : m == 0
                            ? '¡Ya alcanzaste este monto!'
                            : 'Ahorra ${_money.format(m)} al mes para llegar en '
                                  '${DateFormat("MMMM 'de' y", 'es_ES').format(_fecha)}',
                        textAlign: TextAlign.center,
                        style: Brand.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xD9FFFFFF),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Fecha · Apartar · Nota ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.flag_outlined,
                      label: DateFormat('MMM y', 'es_ES').format(_fecha),
                      highlighted: true,
                      onTap: () async {
                        _nombreFocus.unfocus();
                        final d = await pickBrandDate(
                          context,
                          initial: _fecha,
                          first: DateTime.now(),
                          last: DateTime(DateTime.now().year + 30),
                        );
                        if (d != null) setState(() => _fecha = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.bolt_rounded,
                      label: _auto && pct != null
                          ? 'Aparta ${NumberFormat('0.##', 'es_CO').format(pct)}%'
                          : 'Apartar',
                      highlighted: _auto,
                      onTap: _abrirAporteAuto,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: desc.isEmpty ? 'Nota' : desc,
                      highlighted: desc.isNotEmpty,
                      onTap: _abrirNota,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Teclado (llena el espacio) y guardar ───────────────────
              Expanded(
                child: AmountKeypad(entry: _monto, expand: true),
              ),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: _monto,
                builder: (_, __) => BrandButton(
                  label: _monto.isEmpty
                      ? 'Escribe un monto'
                      : _meta != null
                      ? 'Guardar cambios'
                      : 'Crear meta',
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

  Future<void> _abrirAporteAuto() => _hoja(
    'Apartar de cada ingreso',
    (update) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandGroup(
            children: [
              BrandSwitchRow(
                title: 'Apartar automáticamente',
                subtitle: 'Al registrar un ingreso, se aparta un porcentaje para esta meta',
                value: _auto,
                onChanged: (v) => update(() => _auto = v),
              ),
              if (_auto) ...[
                BrandGroupTextRow(
                  label: 'Porcentaje',
                  controller: _pctCtrl,
                  hint: '10',
                  suffix: '%',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                BrandGroupTextRow(
                  label: 'Solo ingresos desde',
                  controller: _minCtrl,
                  hint: 'Sin mínimo',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ],
          ),
          if (_auto) ...[
            const SizedBox(height: 8),
            // El ejemplo sigue al porcentaje mientras se escribe
            ListenableBuilder(
              listenable: _pctCtrl,
              builder: (_, __) {
                final ejemplo = (2000000 * (parseAmount(_pctCtrl.text) ?? 0) / 100).round();
                return Text(
                  'De un ingreso de ${_money.format(2000000)} se apartarían '
                  '${_money.format(ejemplo)}. Sale de la cuenta que recibió el '
                  'ingreso y queda como ahorro: baja el saldo de esa cuenta, pero no '
                  'cuenta como gasto.',
                  style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
                );
              },
            ),
          ],
        ],
      );
    },
  );

  Future<void> _abrirNota() => _hoja(
    'Nota',
    (update) => BrandTextArea(controller: _descCtrl, hint: '¿Por qué es importante?'),
  );
}
