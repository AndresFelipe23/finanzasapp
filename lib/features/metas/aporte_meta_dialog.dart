import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/meta_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../transactions/form_panel.dart';
import '../transactions/transactions_provider.dart';
import 'metas_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Morado de ahorro: el mismo de las metas y los aportes en los movimientos.
const _tone = Color(0xFF6B3FA0);

/// Abre la pantalla para abonar a [meta] (desde abajo, como un formulario).
Future<void> abrirAporteMeta(
  BuildContext context,
  Meta meta, {
  double? montoInicial,
  int? cuentaIdInicial,
  String? notaInicial,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AporteMetaDialog(
        meta: meta,
        montoInicial: montoInicial,
        cuentaIdInicial: cuentaIdInicial,
        notaInicial: notaInicial,
      ),
    ),
  );
}

/// Abonar dinero a una meta. Si se elige una cuenta, el dinero sale de ella.
/// Tiene el diseño del formulario de movimientos: panel con la meta y el
/// monto, atajos, botones de cuenta y nota, y el teclado propio.
class AporteMetaDialog extends ConsumerStatefulWidget {
  final Meta meta;

  /// Datos que llegan ya escritos (p. ej. apartar parte de un ingreso)
  final double? montoInicial;
  final int? cuentaIdInicial;
  final String? notaInicial;

  const AporteMetaDialog({
    super.key,
    required this.meta,
    this.montoInicial,
    this.cuentaIdInicial,
    this.notaInicial,
  });

  @override
  ConsumerState<AporteMetaDialog> createState() => _AporteMetaDialogState();
}

class _AporteMetaDialogState extends ConsumerState<AporteMetaDialog> {
  final _monto = AmountEntry();
  final _notaCtrl = TextEditingController();
  Cuenta? _cuenta;
  bool _saving = false;
  bool _cuentaInicialLista = false;

  @override
  void initState() {
    super.initState();
    final m = widget.montoInicial;
    if (m != null && m > 0) _monto.set(m.roundToDouble());
    _notaCtrl.text = widget.notaInicial ?? '';
    _notaCtrl.addListener(() => setState(() {})); // la nota en el botón
  }

  @override
  void dispose() {
    _monto.dispose();
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
    final monto = _monto.value;
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
    // La cuenta inicial se elige cuando ya hay cuentas cargadas
    if (!_cuentaInicialLista && widget.cuentaIdInicial != null && cuentas.isNotEmpty) {
      _cuentaInicialLista = true;
      _cuenta = cuentas.where((c) => c.id == widget.cuentaIdInicial).firstOrNull;
    }
    final nota = _notaCtrl.text.trim();
    final moneda = _cuenta?.moneda ?? 'COP';
    // Atajos: lo que hace falta al mes para llegar a tiempo, y completarla
    final mensual = m.ahorroMensualNecesario.roundToDouble();
    final faltante = m.faltante.roundToDouble();

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel: la meta, el monto y atajos ─────────────────────
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
                        child: Column(
                          children: [
                            Text(
                              'Abonar a',
                              style: Brand.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: const Color(0xD9FFFFFF),
                              ),
                            ),
                            Text(
                              m.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Brand.text(
                                size: 16,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PanelBadge(moneda),
                    ],
                  ),
                  PanelAmount(
                    entry: _monto,
                    sign: '+',
                    label: 'Faltan ${_money.format(m.faltante)} de ${_money.format(m.montoObjetivo)}',
                  ),
                  // Cuánto quedaría ahorrado con este abono
                  ListenableBuilder(
                    listenable: _monto,
                    builder: (_, __) {
                      final v = _monto.value ?? 0;
                      final total = m.montoActual + v;
                      final pct = m.montoObjetivo <= 0
                          ? 0
                          : (total / m.montoObjetivo * 100).clamp(0, 100).round();
                      return Text(
                        v <= 0
                            ? 'Llevas ${_money.format(m.montoActual)} (${m.porcentajeCompletado.round()}%)'
                            : total >= m.montoObjetivo
                            ? '¡Con este abono cumples la meta!'
                            : 'Quedarías con ${_money.format(total)} ($pct%)',
                        textAlign: TextAlign.center,
                        style: Brand.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xD9FFFFFF),
                        ),
                      );
                    },
                  ),
                  if (faltante > 0) ...[
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: _monto,
                      builder: (_, __) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (mensual > 0 && mensual < faltante) ...[
                              PanelPill(
                                label: 'Lo del mes ${_money.format(mensual)}',
                                selected: _monto.value == mensual,
                                tone: _tone,
                                onTap: () => _monto.set(mensual),
                              ),
                              const SizedBox(width: 8),
                            ],
                            PanelPill(
                              label: 'Completarla ${_money.format(faltante)}',
                              selected: _monto.value == faltante,
                              tone: _tone,
                              onTap: () => _monto.set(faltante),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // ── Desde · Nota ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: _cuenta == null
                          ? Icons.account_balance_wallet_outlined
                          : accountStyle(_cuenta!.tipo).icon,
                      label: _cuenta?.nombre ?? 'Sin cuenta',
                      highlighted: _cuenta != null,
                      onTap: () => _pickCuenta(cuentas),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: nota.isEmpty ? 'Nota' : nota,
                      highlighted: nota.isNotEmpty,
                      onTap: () => _abrirNota(context, _notaCtrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _cuenta == null
                    ? 'Sin cuenta, el abono solo suma a la meta y no mueve saldo.'
                    : 'Sale de ${_cuenta!.nombre} y queda como ahorro, no como gasto.',
                textAlign: TextAlign.center,
                style: Brand.text(size: 12, color: Brand.muted),
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
              ListenableBuilder(
                listenable: _monto,
                builder: (_, __) => BrandButton(
                  label: _monto.isEmpty
                      ? 'Escribe un monto'
                      : 'Abonar ${_money.format(_monto.value)}',
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
}

/// Hoja para escribir la nota del abono o del pago.
Future<void> _abrirNota(BuildContext context, TextEditingController ctrl) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Brand.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
      child: SafeArea(
        child: Padding(
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
              Text('Nota', style: Brand.text(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 14),
              BrandGroup(
                children: [
                  BrandGroupTextRow(label: 'Nota', controller: ctrl, hint: 'Opcional'),
                ],
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
}
