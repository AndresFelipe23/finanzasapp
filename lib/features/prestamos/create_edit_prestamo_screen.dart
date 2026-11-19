import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/currency/exchange_rates.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../transactions/form_panel.dart';
import '../transactions/transactions_provider.dart';
import 'prestamos_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);
final _mesFin = DateFormat("MMMM 'de' y", 'es_ES');

const _plazosRapidos = [12, 24, 36, 48, 60];

/// Crear o editar un préstamo. DEUDA = yo debo · PRESTAMO = me deben.
///
/// El formulario funciona como una calculadora: el monto es el protagonista,
/// la forma de pago se elige con dos tarjetas y, en cuotas, un resumen vivo
/// muestra la cuota, el total y los intereses antes de guardar.
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
  // En cuotas el monto es el capital prestado (montoTotal incluye intereses)
  late final _montoCtrl = TextEditingController(
    text: _p == null
        ? ''
        : ((_p.enCuotas ? _p.montoPrestado : null) ?? _p.montoTotal)
              .toStringAsFixed(_p.enCuotas ? 2 : 0),
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
  final _nombreFocus = FocusNode();
  // Teclado propio del monto: escribe en _montoCtrl, que usan los cálculos
  final _monto = AmountEntry();

  // ── Pago en cuotas (créditos) ──
  late bool _enCuotas = _p?.enCuotas ?? false;
  late String _tipoTasa = _p?.tipoTasa ?? 'EA';
  late final _numCuotasCtrl = TextEditingController(
    text: _p?.numeroCuotas?.toString() ?? '',
  );
  late final _cuotaCtrl = TextEditingController(
    text: _p?.cuotaTotal?.toStringAsFixed(2) ?? '',
  );
  late final _previasCtrl = TextEditingController(
    text: (_p?.cuotasPrevias ?? 0) > 0 ? '${_p!.cuotasPrevias}' : '',
  );
  late final _cargoNombreCtrl = TextEditingController(
    text: _p?.cargoAdicionalNombre ?? '',
  );
  late final _cargoTotalCtrl = TextEditingController(
    text: _p?.cargoAdicionalTotal?.toStringAsFixed(2) ?? '',
  );
  late DateTime _primeraCuota =
      _p?.fechaPrimeraCuota ??
      DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        DateTime.now().day,
      );
  // La cuota se recalcula sola hasta que el usuario escribe la del banco
  late bool _cuotaManual = _p?.enCuotas ?? false;
  String _cuotaCalculada = '';

  // El plazo habitual se elige con chips; "Otro" muestra el campo libre.
  late bool _plazoOtro =
      _p?.numeroCuotas != null && !_plazosRapidos.contains(_p!.numeroCuotas);
  late bool _mostrarCargo =
      (_p?.cargoAdicionalTotal ?? 0) > 0 ||
      (_p?.cargoAdicionalNombre?.isNotEmpty ?? false);

  bool get _debo => _tipo == 'DEUDA';

  @override
  void initState() {
    super.initState();
    _monto.set(parseAmount(_montoCtrl.text));
    _monto.addListener(() {
      if (_montoCtrl.text != _monto.raw) _montoCtrl.text = _monto.raw;
    });
    _notasCtrl.addListener(() => setState(() {})); // "Nota" en el botón
    _nombreCtrl.addListener(() => setState(() {})); // sugerencias de nombre
    for (final c in [_montoCtrl, _tasaCtrl, _numCuotasCtrl, _cargoTotalCtrl]) {
      c.addListener(() {
        _recalcularCuota();
        setState(() {}); // el resumen de abajo
      });
    }
    _previasCtrl.addListener(() => setState(() {}));
    _cuotaCtrl.addListener(() {
      // Escribió un valor distinto al calculado: es la cuota del banco
      if (_cuotaCtrl.text != _cuotaCalculada) {
        _cuotaManual = _cuotaCtrl.text.isNotEmpty;
      }
      setState(() {});
    });
  }

  int? get _numCuotas => int.tryParse(_numCuotasCtrl.text.trim());
  int get _previas => int.tryParse(_previasCtrl.text.trim()) ?? 0;
  int get _restantes => math.max(0, (_numCuotas ?? 0) - _previas);
  double get _cargoPorCuota {
    final total = parseAmount(_cargoTotalCtrl.text) ?? 0;
    final n = _numCuotas;
    return n == null || n <= 0 ? 0.0 : total / n;
  }

  double? get _capital => parseAmount(_montoCtrl.text);
  double? get _cuotaMensual => parseAmount(_cuotaCtrl.text);

  /// Cuota fija (sistema francés) con el monto, la tasa y el plazo.
  double? get _cuotaSugerida {
    final capital = _capital;
    final n = _numCuotas;
    final cuotasRestantes = n == null ? 0 : n - _previas;
    if (capital == null || capital <= 0 || cuotasRestantes <= 0) {
      return null;
    }
    final tasa = _tasaCtrl.text.trim().isEmpty
        ? null
        : parseAmount(_tasaCtrl.text);
    return Prestamo.cuotaFija(
      capital,
      Prestamo.tasaMensualDe(tasa, _tipoTasa),
      cuotasRestantes,
    );
  }

  double? get _cuotaTotalSugerida {
    final base = _cuotaSugerida;
    return base == null ? null : base + _cargoPorCuota;
  }

  /// Cuota base (sin el cargo adicional), ya sea la calculada o la del banco.
  double? get _cuotaBase {
    if (!_enCuotas) return null;
    if (!_cuotaManual) return _cuotaSugerida;
    final total = _cuotaMensual;
    if (total == null) return null;
    final base = total - _cargoPorCuota;
    return base > 0 ? base : null;
  }

  DateTime? get _fechaUltimaCuota {
    final n = _numCuotas;
    if (n == null || n <= 0) return null;
    return DateTime(
      _primeraCuota.year,
      _primeraCuota.month + n - 1,
      _primeraCuota.day,
    );
  }

  void _recalcularCuota() {
    if (!_enCuotas || _cuotaManual) return;
    final c = _cuotaTotalSugerida;
    final next = c == null ? '' : c.toStringAsFixed(2);
    _cuotaCalculada = next;
    if (_cuotaCtrl.text != next) _cuotaCtrl.text = next;
  }

  void _usarCalculada() {
    setState(() {
      _cuotaManual = false;
    });
    _recalcularCuota();
  }

  void _setEnCuotas(bool value) {
    setState(() => _enCuotas = value);
    if (value) _recalcularCuota();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreFocus.dispose();
    _monto.dispose();
    _montoCtrl.dispose();
    _tasaCtrl.dispose();
    _notasCtrl.dispose();
    _numCuotasCtrl.dispose();
    _cuotaCtrl.dispose();
    _previasCtrl.dispose();
    _cargoNombreCtrl.dispose();
    _cargoTotalCtrl.dispose();
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

  List<String> _nombresRecientes(List<Prestamo> all) {
    final seen = <String>{};
    final out = <String>[];
    for (final p in all) {
      if (p.tipo != _tipo) continue;
      final nombre = p.nombre.trim();
      if (nombre.isEmpty) continue;
      if (seen.add(nombre.toLowerCase())) out.add(nombre);
      if (out.length >= 4) break;
    }
    return out;
  }

  /// Préstamo temporal con los datos del formulario: permite reutilizar la
  /// tabla de amortización real (`Prestamo.tabla()`) antes de guardar.
  Prestamo? _prestamoTemporal() {
    final n = _numCuotas;
    final cuota = _cuotaMensual;
    final base = _cuotaBase;
    if (n == null || n <= 0 || cuota == null || cuota <= 0) return null;
    if (base == null || base <= 0 || _restantes <= 0) return null;

    final capital = _capital;
    final cargoTotal = parseAmount(_cargoTotalCtrl.text) ?? 0;
    final tasa = _tasaCtrl.text.trim().isEmpty
        ? null
        : parseAmount(_tasaCtrl.text);
    final hoy = DateTime.now();

    return Prestamo(
      id: _p?.id ?? 0,
      usuarioId: _p?.usuarioId ?? 0,
      cuentaId: _cuentaId,
      nombre: _nombreCtrl.text.trim().isEmpty
          ? 'Préstamo'
          : _nombreCtrl.text.trim(),
      tipo: _tipo,
      montoTotal: cuota * _restantes,
      saldoPendiente: cuota * _restantes,
      tasaInteres: tasa,
      fechaInicio: _inicio,
      fechaFin: _fechaUltimaCuota,
      notas: null,
      activa: true,
      fechaCreacion: _p?.fechaCreacion ?? hoy,
      fechaActualizacion: hoy,
      montoPrestado: capital,
      cargoAdicionalNombre: cargoTotal > 0
          ? (_cargoNombreCtrl.text.trim().isEmpty
                ? 'Cargo adicional'
                : _cargoNombreCtrl.text.trim())
          : null,
      cargoAdicionalTotal: cargoTotal > 0 ? cargoTotal : null,
      tipoTasa: _tipoTasa,
      numeroCuotas: n,
      valorCuota: base,
      diaPago: _primeraCuota.day,
      fechaPrimeraCuota: _primeraCuota,
      cuotasPrevias: _previas > 0 ? _previas : null,
    );
  }

  void _abrirTabla() {
    final prestamo = _prestamoTemporal();
    if (prestamo == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TablaAmortizacionSheet(prestamo: prestamo),
    );
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    final monto = parseAmount(_montoCtrl.text);
    final tasaText = _tasaCtrl.text.trim();
    final tasa = tasaText.isEmpty ? null : parseAmount(tasaText);
    if (nombre.isEmpty) {
      showBrandSnack(
        context,
        _debo
            ? '¿A quién le debes? Escribe un nombre'
            : '¿Quién te debe? Escribe un nombre',
      );
      _nombreFocus.requestFocus();
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
    if (!_enCuotas && _fin != null && _fin!.isBefore(_inicio)) {
      showBrandSnack(
        context,
        'La fecha de vencimiento debe ser después del inicio',
      );
      return;
    }
    // La cuota mensual total incluye la cuota base y el cargo prorrateado.
    final n = _numCuotas;
    final cuotaTotal = parseAmount(_cuotaCtrl.text);
    final cargoText = _cargoTotalCtrl.text.trim();
    final double? cargoTotal = cargoText.isEmpty ? 0.0 : parseAmount(cargoText);
    if (_enCuotas) {
      if (n == null || n <= 0) {
        showBrandSnack(context, 'Escribe el número de cuotas');
        return;
      }
      if (cargoText.isNotEmpty && (cargoTotal == null || cargoTotal < 0)) {
        showBrandSnack(context, 'El cargo adicional no es válido');
        return;
      }
      if (cuotaTotal == null || cuotaTotal <= 0) {
        showBrandSnack(context, 'Escribe el valor de la cuota');
        return;
      }
      final cuotaBase = cuotaTotal - (cargoTotal ?? 0) / n;
      if (cuotaBase <= 0) {
        showBrandSnack(
          context,
          'El cargo debe ser menor que el total de las cuotas',
        );
        return;
      }
      if (_previas >= n) {
        showBrandSnack(
          context,
          'Las cuotas ya pagadas deben ser menos que el total',
        );
        return;
      }
    }
    final cargoPorCuota = _enCuotas ? (cargoTotal ?? 0) / n! : 0;
    final cuotaBase = _enCuotas
        ? (_cuotaManual ? cuotaTotal! - cargoPorCuota : _cuotaSugerida!)
        : null;
    final cuotaTotalReal = _enCuotas ? cuotaBase! + cargoPorCuota : null;
    final ultimaCuota = _enCuotas
        ? DateTime(
            _primeraCuota.year,
            _primeraCuota.month + n! - 1,
            _primeraCuota.day,
          )
        : null;
    final notas = _notasCtrl.text.trim();

    setState(() => _saving = true);
    final req = CreatePrestamoRequest(
      nombre: nombre,
      tipo: _tipo,
      montoTotal: _enCuotas ? cuotaTotalReal! * (n! - _previas) : monto,
      tasaInteres: tasa,
      fechaInicio: _inicio,
      // En cuotas vence con la última cuota
      fechaFin: _enCuotas ? ultimaCuota : _fin,
      cuentaId: _cuentaId,
      notas: notas.isEmpty ? null : notas,
      registrarMovimiento: _p == null ? _registrar : null,
      // Al editar se envían siempre: así pasar a "sin cuotas" los borra
      cuotas: _enCuotas || (_p?.enCuotas ?? false),
      montoPrestado: _enCuotas ? monto : null,
      cargoAdicionalNombre: _enCuotas && (cargoTotal ?? 0) > 0
          ? (_cargoNombreCtrl.text.trim().isEmpty
                ? 'Cargo adicional'
                : _cargoNombreCtrl.text.trim())
          : null,
      cargoAdicionalTotal: _enCuotas && (cargoTotal ?? 0) > 0
          ? cargoTotal
          : null,
      tipoTasa: _enCuotas ? _tipoTasa : null,
      numeroCuotas: _enCuotas ? n : null,
      valorCuota: cuotaBase,
      diaPago: _enCuotas ? _primeraCuota.day : null,
      fechaPrimeraCuota: _enCuotas ? _primeraCuota : null,
      cuotasPrevias: _enCuotas && _previas > 0 ? _previas : null,
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
    final cuentas =
        (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
            .where((c) => c.activa)
            .toList();
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;
    final moneda = ref.watch(monedaBaseProvider);
    final todos =
        ref.watch(prestamosNotifierProvider).valueOrNull ?? const <Prestamo>[];
    final sugerencias = _nombreCtrl.text.trim().isEmpty
        ? _nombresRecientes(todos)
        : const <String>[];
    final tone = _debo ? Brand.expense : Brand.accent;
    final notas = _notasCtrl.text.trim();
    final n = _numCuotas;

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
              // ── Panel: quién, cuánto y cómo se paga ────────────────────
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
                        options: const [
                          ('DEUDA', 'Debo'),
                          ('PRESTAMO', 'Me deben'),
                        ],
                        value: _tipo,
                        tone: tone,
                        onChanged: (v) => setState(() => _tipo = v),
                      ),
                      PanelBadge(moneda),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('prestamo-nombre'),
                    controller: _nombreCtrl,
                    focusNode: _nombreFocus,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    // Al terminar el nombre se cierra el teclado del sistema
                    // y queda el propio para el monto
                    onSubmitted: (_) => _nombreFocus.unfocus(),
                    cursorColor: Colors.white,
                    style: Brand.text(
                      size: 18,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: _debo
                          ? '¿A quién le debes?'
                          : '¿Quién te debe?',
                      hintStyle: Brand.text(
                        size: 18,
                        weight: FontWeight.w700,
                        color: const Color(0x99FFFFFF),
                      ),
                      filled: true,
                      fillColor: const Color(0x29FFFFFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (sugerencias.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: sugerencias.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => PanelPill(
                          label: sugerencias[i],
                          selected: false,
                          tone: tone,
                          onTap: () => _nombreCtrl.text = sugerencias[i],
                        ),
                      ),
                    ),
                  ],
                  PanelAmount(
                    entry: _monto,
                    sign: _debo ? '−' : '+',
                    label: _enCuotas
                        ? 'Capital del crédito, sin intereses'
                        : _debo
                        ? 'Cuánto debes'
                        : 'Cuánto prestaste',
                  ),
                  const SizedBox(height: 4),
                  // Forma de pago (se encoge si la pantalla es angosta)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PanelPill(
                          label: 'Pago único',
                          selected: !_enCuotas,
                          tone: tone,
                          onTap: () => _setEnCuotas(false),
                        ),
                        const SizedBox(width: 8),
                        PanelPill(
                          label: 'En cuotas',
                          selected: _enCuotas,
                          tone: tone,
                          onTap: () => _setEnCuotas(true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Cuenta · Condiciones · Nota ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: cuenta == null
                          ? Icons.account_balance_wallet_outlined
                          : accountStyle(cuenta.tipo).icon,
                      label: cuenta?.nombre ?? 'Cuenta',
                      highlighted: cuenta != null,
                      onTap: () => _abrirCuenta(cuentas),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: _enCuotas
                          ? Icons.calendar_month_rounded
                          : Icons.event_outlined,
                      label: _enCuotas
                          ? (n == null || n <= 0 ? 'Cuotas' : '$n cuotas')
                          : (_fin == null
                                ? 'Condiciones'
                                : 'Vence ${DateFormat('d MMM', 'es_ES').format(_fin!)}'),
                      highlighted: _enCuotas
                          ? (n ?? 0) > 0
                          : _fin != null || _tasaCtrl.text.trim().isNotEmpty,
                      onTap: () => _abrirCondiciones(moneda),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: notas.isEmpty ? 'Nota' : _notasPreview(notas),
                      highlighted: notas.isNotEmpty,
                      onTap: _abrirNota,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Lo que se va a guardar: cuotas y total, o el vencimiento
              _FooterResumen(
                enCuotas: _enCuotas,
                monto: _capital,
                cuota: _cuotaMensual,
                numCuotas: _numCuotas,
                previas: _previas,
                vence: _fin,
              ),
              const SizedBox(height: 10),

              // ── Teclado (llena el espacio) y guardar ───────────────────
              Expanded(
                child: AmountKeypad(
                  entry: _monto,
                  decimals: monedaConCentavos(moneda),
                  expand: true,
                ),
              ),
              const SizedBox(height: 14),
              BrandButton(
                label: _p == null ? 'Guardar préstamo' : 'Guardar cambios',
                background: Brand.ink,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hoja inferior con el título y el contenido, como "Detalles" en el
  /// formulario de movimientos. El contenido se vuelve a pintar al escribir
  /// en cualquiera de los campos del préstamo.
  Future<void> _hoja(
    String titulo,
    Widget Function(void Function(VoidCallback)) contenido,
  ) {
    _nombreFocus.unfocus();
    final campos = Listenable.merge([
      _montoCtrl,
      _tasaCtrl,
      _numCuotasCtrl,
      _cuotaCtrl,
      _previasCtrl,
      _cargoNombreCtrl,
      _cargoTotalCtrl,
      _notasCtrl,
    ]);
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
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.88,
              ),
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
                      Text(
                        titulo,
                        style: Brand.text(size: 20, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      ListenableBuilder(
                        listenable: campos,
                        builder: (_, __) => contenido(update),
                      ),
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirCuenta(List<Cuenta> cuentas) => _hoja('Cuenta', (update) {
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandGroup(
          children: [
            BrandGroupRow(
              label: 'Cuenta',
              value: cuenta?.nombre ?? 'Ninguna',
              placeholder: cuenta == null,
              onTap: () async {
                await _pickCuenta(cuentas);
                update(() {});
              },
            ),
            if (_p == null && _cuentaId != null)
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
                onChanged: (v) => update(() => _registrar = v),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'La cuenta de donde sale o a donde entra el dinero de los pagos.',
          style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
        ),
      ],
    );
  });

  Future<void> _abrirNota() => _hoja(
    'Nota',
    (update) => BrandTextArea(
      controller: _notasCtrl,
      hint: 'Ej: cuotas de \$200.000 cada mes',
    ),
  );

  Future<void> _abrirCondiciones(String moneda) => _hoja(
    _enCuotas ? 'Datos del crédito' : 'Condiciones del pago',
    (update) =>
        _enCuotas ? _datosCredito(moneda, update) : _datosPagoUnico(update),
  );

  Widget _datosPagoUnico(void Function(VoidCallback) update) {
    return BrandGroup(
      children: [
        BrandGroupTextRow(
          label: 'Interés anual',
          controller: _tasaCtrl,
          hint: 'Sin intereses',
          suffix: _tasaCtrl.text.isEmpty ? null : '%',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [DecimalAmountInputFormatter()],
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
            if (d != null) update(() => _inicio = d);
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
            update(() => _fin = d);
          },
        ),
      ],
    );
  }

  Widget _datosCredito(String moneda, void Function(VoidCallback) update) {
    final calculada = _cuotaTotalSugerida;
    final actual = _cuotaMensual;
    final puedeVolver =
        _cuotaManual &&
        calculada != null &&
        (actual == null || (calculada - actual).abs() >= 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandGroup(
          children: [
            BrandGroupTextRow(
              label: 'Tasa de interés',
              controller: _tasaCtrl,
              hint: 'Sin intereses',
              suffix: _tasaCtrl.text.isEmpty ? null : '%',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalAmountInputFormatter()],
            ),
            _TasaTipoRow(
              value: _tipoTasa,
              onChanged: (v) {
                update(() => _tipoTasa = v);
                _recalcularCuota();
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: _PlazoChips(
                selected: _plazoOtro ? null : _numCuotas,
                otro: _plazoOtro,
                onSelected: (n) {
                  update(() {
                    _plazoOtro = false;
                    _numCuotasCtrl.text = '$n';
                  });
                  _recalcularCuota();
                },
                onOtro: () => update(() => _plazoOtro = true),
              ),
            ),
            if (_plazoOtro)
              BrandGroupTextRow(
                label: 'Número de cuotas',
                controller: _numCuotasCtrl,
                hint: 'Ej: 18',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            BrandGroupRow(
              label: 'Primera cuota',
              value: brandDateLabel(_primeraCuota),
              onTap: () async {
                final d = await pickBrandDate(
                  context,
                  initial: _primeraCuota,
                  first: DateTime(2000),
                  last: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d != null) update(() => _primeraCuota = d);
              },
            ),
            BrandGroupTextRow(
              label: 'Cuotas ya pagadas',
              controller: _previasCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Cargo adicional (colapsable) ─────────────────────────────────
        BrandGroup(
          children: [
            BrandGroupRow(
              label: 'Cargo adicional',
              value: _mostrarCargo ? 'Ocultar' : _cargoResumen ?? 'Agregar',
              placeholder: !_mostrarCargo && _cargoResumen == null,
              onTap: () => update(() => _mostrarCargo = !_mostrarCargo),
            ),
            if (_mostrarCargo) ...[
              BrandGroupTextRow(
                label: 'Nombre del cargo',
                controller: _cargoNombreCtrl,
                hint: 'Ej: Servicio de fianza',
              ),
              BrandGroupTextRow(
                label: 'Cargo total',
                controller: _cargoTotalCtrl,
                hint: 'Se reparte entre las cuotas',
                suffix: _cargoTotalCtrl.text.isEmpty ? null : moneda,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [DecimalAmountInputFormatter()],
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // ── La cuota y el resumen vivo ───────────────────────────────────
        BrandGroup(
          children: [
            BrandGroupTextRow(
              label: 'Valor de la cuota',
              controller: _cuotaCtrl,
              hint: 'Se calcula sola',
              suffix: _cuotaCtrl.text.isEmpty ? null : moneda,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalAmountInputFormatter()],
            ),
            if (puedeVolver)
              BrandGroupRow(
                label: 'Volver a la calculada',
                value: _money.format(calculada),
                onTap: () => update(_usarCalculada),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _ResumenCredito(
          cuota: _cuotaMensual,
          numCuotas: _numCuotas,
          previas: _previas,
          capital: _capital,
          cargoNombre: _cargoNombreCtrl.text.trim(),
          cargoTotal: parseAmount(_cargoTotalCtrl.text) ?? 0,
          cargoPorCuota: _cargoPorCuota,
          primera: _primeraCuota,
          manual: _cuotaManual,
          onVerTabla: _abrirTabla,
        ),
      ],
    );
  }

  String? get _cargoResumen {
    final total = parseAmount(_cargoTotalCtrl.text) ?? 0;
    final nombre = _cargoNombreCtrl.text.trim();
    if (total <= 0 && nombre.isEmpty) return null;
    final etiqueta = nombre.isEmpty ? 'Cargo adicional' : nombre;
    return total > 0 ? '$etiqueta · ${_money.format(total)}' : etiqueta;
  }

  String _notasPreview(String text) {
    final limpio = text.trim().replaceAll('\n', ' ');
    return limpio.length <= 32 ? limpio : '${limpio.substring(0, 32)}…';
  }
}

// ─── Piezas del formulario ───────────────────────────────────────────────────

class _TasaTipoRow extends StatelessWidget {
  const _TasaTipoRow({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Tipo de tasa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Brand.text(size: 14, color: Brand.muted),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Brand.track,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _pill('EA', 'E.A.'),
                  const SizedBox(width: 3),
                  _pill('MV', 'M.V.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String key, String label) {
    final on = value == key;
    return Semantics(
      selected: on,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Brand.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x1410201B),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Brand.text(
              size: 12,
              weight: on ? FontWeight.w800 : FontWeight.w600,
              color: on ? Brand.ink : Brand.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlazoChips extends StatelessWidget {
  const _PlazoChips({
    required this.selected,
    required this.otro,
    required this.onSelected,
    required this.onOtro,
  });

  final int? selected;
  final bool otro;
  final ValueChanged<int> onSelected;
  final VoidCallback onOtro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plazo', style: Brand.text(size: 14, color: Brand.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in _plazosRapidos)
              _chip(
                label: '$n',
                on: !otro && selected == n,
                onTap: () => onSelected(n),
              ),
            _chip(label: 'Otro', on: otro, onTap: onOtro),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool on,
    required VoidCallback onTap,
  }) {
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? Brand.accentSoft : Brand.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: on ? Brand.accent : Brand.border,
            width: on ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: Brand.text(
                size: 13,
                weight: on ? FontWeight.w800 : FontWeight.w600,
                color: on ? Brand.accent : Brand.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta oscura con el resultado del crédito, siempre visible antes de
/// guardar.
class _ResumenCredito extends StatelessWidget {
  const _ResumenCredito({
    required this.cuota,
    required this.numCuotas,
    required this.previas,
    required this.capital,
    required this.cargoNombre,
    required this.cargoTotal,
    required this.cargoPorCuota,
    required this.primera,
    required this.manual,
    required this.onVerTabla,
  });

  final double? cuota;
  final int? numCuotas;
  final int previas;
  final double? capital;
  final String cargoNombre;
  final double cargoTotal;
  final double cargoPorCuota;
  final DateTime primera;
  final bool manual;
  final VoidCallback onVerTabla;

  @override
  Widget build(BuildContext context) {
    final n = numCuotas;
    final restantes = n == null ? 0 : n - previas;
    final c = cuota;
    if (c == null || c <= 0 || n == null || n <= 0 || restantes <= 0) {
      return _Placeholder(
        text: restantes <= 0 && n != null && n > 0
            ? 'Las cuotas ya pagadas deben ser menos que el total.'
            : 'Completa el capital, la tasa y el plazo para ver la cuota.',
      );
    }

    final total = c * restantes;
    final cargos = cargoPorCuota * restantes;
    final intereses = capital == null
        ? null
        : math.max(0, total - cargos - capital!);
    final fin = DateTime(primera.year, primera.month + n - 1, primera.day);
    final capitalParte = capital == null || total <= 0
        ? null
        : (capital! / total).clamp(0.0, 1.0);
    final capFlex = capitalParte == null ? 0 : (capitalParte * 100).round();
    final intFlex = capitalParte == null ? 0 : 100 - capFlex;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CUOTA MENSUAL',
                  style: Brand.text(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFFB9C6C0),
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  manual ? 'editada' : 'calculada',
                  style: Brand.text(
                    size: 10,
                    weight: FontWeight.w700,
                    color: manual ? Brand.peach : Brand.mint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money.format(c),
              style: Brand.title(size: 32, color: Colors.white),
            ),
          ),
          if (previas > 0)
            Text(
              'Faltan $restantes de $n cuotas',
              style: Brand.text(size: 12, color: const Color(0xFFB9C6C0)),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  label: 'Total a pagar',
                  value: _money.format(total),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Dato(
                  label: 'Intereses',
                  value: intereses == null ? '—' : _money.format(intereses),
                ),
              ),
            ],
          ),
          if (capitalParte != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (capFlex > 0)
                    Expanded(
                      flex: capFlex,
                      child: Container(height: 8, color: Brand.mint),
                    ),
                  if (capFlex > 0 && intFlex > 0) const SizedBox(width: 2),
                  if (intFlex > 0)
                    Expanded(
                      flex: intFlex,
                      child: Container(height: 8, color: Brand.peach),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              [
                'Capital ${_money.format(capital)}',
                if (cargoTotal > 0)
                  '${cargoNombre.isEmpty ? 'Cargo' : cargoNombre} '
                      '${_money.format(cargoTotal)}',
                if (intereses != null) 'Intereses ${_money.format(intereses)}',
              ].join(' · '),
              style: Brand.text(
                size: 11,
                color: const Color(0xFFB9C6C0),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Termina en ${_mesFin.format(fin)}',
            style: Brand.text(size: 12, color: const Color(0xFFB9C6C0)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF2A3B34)),
          InkWell(
            onTap: onVerTabla,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_rows_outlined,
                    size: 18,
                    color: Brand.mint,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ver tabla de amortización',
                      style: Brand.text(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Brand.mint,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Brand.mint,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Brand.text(size: 11, color: const Color(0xFFB9C6C0)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Brand.text(
              size: 15,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Brand.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calculate_outlined,
              size: 20,
              color: Brand.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Brand.text(size: 12, color: Brand.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen compacto que queda fijo encima del botón de guardar.
class _FooterResumen extends StatelessWidget {
  const _FooterResumen({
    required this.enCuotas,
    required this.monto,
    required this.cuota,
    required this.numCuotas,
    required this.previas,
    required this.vence,
  });

  final bool enCuotas;
  final double? monto;
  final double? cuota;
  final int? numCuotas;
  final int previas;
  final DateTime? vence;

  @override
  Widget build(BuildContext context) {
    String? titulo;
    String? valor;
    IconData icono = Icons.calculate_outlined;

    if (enCuotas) {
      final n = numCuotas;
      final c = cuota;
      final restantes = n == null ? 0 : n - previas;
      if (n != null && n > 0 && c != null && c > 0 && restantes > 0) {
        titulo = restantes == 1
            ? '1 cuota de ${_money.format(c)}'
            : '$restantes cuotas de ${_money.format(c)}';
        valor = 'Total ${_money.format(c * restantes)}';
        icono = Icons.calendar_month_rounded;
      }
    } else if (monto != null && monto! > 0) {
      titulo = vence == null
          ? 'Sin fecha de vencimiento'
          : 'Vence el ${brandDateLabel(vence!)}';
      valor = _money.format(monto);
      icono = Icons.payments_outlined;
    }

    if (titulo == null) {
      return Text(
        'Completa el nombre y el monto para guardar.',
        textAlign: TextAlign.center,
        style: Brand.text(size: 12, color: Brand.muted),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Brand.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: Brand.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.text(size: 11, color: Brand.muted),
                ),
                if (valor != null)
                  Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.text(size: 14, weight: FontWeight.w800),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tabla de amortización (vista previa) ───────────────────────────────────

class _TablaAmortizacionSheet extends StatelessWidget {
  const _TablaAmortizacionSheet({required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    final tabla = prestamo.tabla();
    final fecha = DateFormat('d MMM y', 'es_ES');
    final proxima = prestamo.proximaCuota;
    final intereses = tabla.fold<double>(
      0,
      (suma, c) => suma + (c.interes ?? 0),
    );
    final sinDesglose =
        tabla.isNotEmpty && tabla.every((c) => c.interes == null);
    final fin = prestamo.fechaUltimaCuota;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tabla de amortización',
                          style: Brand.text(size: 20, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${prestamo.numeroCuotas} cuotas de '
                          '${_money.format(prestamo.cuotaTotal)}',
                          style: Brand.text(size: 12, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Brand.ink),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Brand.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniDato(
                      label: 'Total',
                      value: _money.format(prestamo.montoTotal),
                    ),
                  ),
                  Expanded(
                    child: _MiniDato(
                      label: 'Intereses',
                      value: _money.format(intereses),
                    ),
                  ),
                  if (fin != null)
                    Expanded(
                      child: _MiniDato(
                        label: 'Termina',
                        value: _mesFin.format(fin),
                      ),
                    ),
                ],
              ),
            ),
            if (sinDesglose)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  'Pon el monto prestado y la tasa para ver cuánto es interés '
                  'y cuánto abono a capital.',
                  style: Brand.text(size: 12, color: Brand.muted, height: 1.35),
                ),
              ),
            Expanded(
              child: tabla.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay cuotas para mostrar.',
                        style: Brand.text(size: 13, color: Brand.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      itemCount: tabla.length,
                      itemBuilder: (_, i) {
                        final c = tabla[i];
                        return _FilaAmortizacion(
                          cuota: c,
                          proxima: proxima == c.numero,
                          fecha: fecha,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  const _MiniDato({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Brand.text(size: 10, color: Brand.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Brand.text(size: 12, weight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _FilaAmortizacion extends StatelessWidget {
  const _FilaAmortizacion({
    required this.cuota,
    required this.proxima,
    required this.fecha,
  });

  final CuotaCredito cuota;
  final bool proxima;
  final DateFormat fecha;

  @override
  Widget build(BuildContext context) {
    final detalle = cuota.interes == null
        ? null
        : [
            'Interés ${_money.format(cuota.interes)}',
            'Capital ${_money.format(cuota.capital)}',
            if (cuota.cargoAdicional > 0)
              'Cargo ${_money.format(cuota.cargoAdicional)}',
          ].join(' · ');
    final saldo = cuota.saldoCapital == null
        ? null
        : 'Saldo ${_money.format(cuota.saldoCapital)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: proxima ? Brand.accentSoft : Brand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: proxima ? Brand.accent : Brand.border,
          width: proxima ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: cuota.pagada
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Brand.accent,
                  )
                : Text(
                    '${cuota.numero}',
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: proxima ? Brand.accent : Brand.muted,
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cuota.fecha == null
                      ? 'Cuota ${cuota.numero}'
                      : fecha.format(cuota.fecha!),
                  style: Brand.text(
                    size: 13,
                    weight: FontWeight.w600,
                    color: cuota.pagada ? Brand.muted : Brand.ink,
                  ),
                ),
                if (detalle != null)
                  Text(
                    detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.text(size: 10.5, color: Brand.muted),
                  ),
                if (saldo != null)
                  Text(
                    saldo,
                    style: Brand.text(size: 10.5, color: Brand.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money.format(cuota.valor),
            style: Brand.text(
              size: 13,
              weight: FontWeight.w700,
              color: cuota.pagada ? Brand.muted : Brand.ink,
            ),
          ),
        ],
      ),
    );
  }
}
