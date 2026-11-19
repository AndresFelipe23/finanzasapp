import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

/// Abre la pantalla para pagar (o cobrar) [prestamo], como un formulario.
Future<void> abrirPagoPrestamo(BuildContext context, Prestamo prestamo) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PagoPrestamoDialog(prestamo: prestamo),
    ),
  );
}

/// Registrar un pago (si debo) o un cobro (si me deben). Tiene el diseño del
/// formulario de movimientos: panel con el préstamo, el monto y atajos
/// (cuotas o porcentajes), botones de cuenta, fecha y nota, y el teclado.
class PagoPrestamoDialog extends ConsumerStatefulWidget {
  final Prestamo prestamo;
  const PagoPrestamoDialog({super.key, required this.prestamo});

  @override
  ConsumerState<PagoPrestamoDialog> createState() => _PagoPrestamoDialogState();
}

class _PagoPrestamoDialogState extends ConsumerState<PagoPrestamoDialog> {
  final _monto = AmountEntry();
  final _notaCtrl = TextEditingController();
  late int? _cuentaId = widget.prestamo.cuentaId;
  DateTime _fecha = DateTime.now();
  bool _saving = false;

  bool get _debo => widget.prestamo.tipo == 'DEUDA';

  @override
  void initState() {
    super.initState();
    // En cuotas: listo para pagar la próxima cuota
    final p = widget.prestamo;
    if (p.enCuotas && p.proximaCuota != null) {
      final cuotaMensual = p.cuotaTotal!;
      final cuota = cuotaMensual < p.saldoPendiente
          ? cuotaMensual
          : p.saldoPendiente;
      _monto.set(cuota.roundToDouble());
      _notaCtrl.text = 'Cuota ${p.proximaCuota} de ${p.numeroCuotas}';
    }
    _notaCtrl.addListener(() => setState(() {})); // la nota en el botón
  }

  @override
  void dispose() {
    _monto.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas) async {
    final picked = await showBrandPicker<int>(
      context,
      title: _debo ? '¿De dónde sale el pago?' : '¿A dónde entra el dinero?',
      selected: _cuentaId ?? 0,
      options: [
        const BrandOption(
          0,
          'Sin cuenta',
          subtitle: 'Solo baja el saldo pendiente',
        ),
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
    final monto = _monto.value;
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
      await ref
          .read(prestamosNotifierProvider.notifier)
          .crearPago(
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
    final cuentas =
        (ref.watch(accountsNotifierProvider).valueOrNull ?? const <Cuenta>[])
            .where((c) => c.activa)
            .toList();
    final cuenta = cuentas.where((c) => c.id == _cuentaId).firstOrNull;
    final tone = _debo ? Brand.expense : Brand.accent;
    final moneda = cuenta?.moneda ?? 'COP';
    final nota = _notaCtrl.text.trim();
    final hoy = DateUtils.isSameDay(_fecha, DateTime.now());

    // Con cuotas los atajos son en cuotas; sin ellas, en porcentaje del saldo
    double tope(double v) => (v < p.saldoPendiente ? v : p.saldoPendiente).roundToDouble();
    final atajos = <(String, double)>[
      if (p.enCuotas) ...[
        ('1 cuota', tope(p.cuotaTotal!)),
        ('2 cuotas', tope(p.cuotaTotal! * 2)),
        ('Todo', tope(p.saldoPendiente)),
      ] else ...[
        ('25%', tope(p.saldoPendiente * 0.25)),
        ('50%', tope(p.saldoPendiente * 0.5)),
        ('Todo', tope(p.saldoPendiente)),
      ],
    ];

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel: el préstamo, el monto y atajos ─────────────────
              FormPanel(
                color: tone,
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
                              _debo ? 'Pagar a' : 'Cobrar a',
                              style: Brand.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: const Color(0xD9FFFFFF),
                              ),
                            ),
                            Text(
                              p.nombre,
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
                    sign: _debo ? '−' : '+',
                    label: p.enCuotas && p.proximaCuota != null
                        ? 'Cuota ${p.proximaCuota} de ${p.numeroCuotas}'
                        : _debo
                        ? 'Pago'
                        : 'Cobro',
                  ),
                  // Lo que quedaría pendiente con este pago
                  ListenableBuilder(
                    listenable: _monto,
                    builder: (_, __) {
                      final v = _monto.value ?? 0;
                      final queda = p.saldoPendiente - v;
                      return Text(
                        v <= 0
                            ? 'Pendiente: ${_money.format(p.saldoPendiente)}'
                            : queda <= 0.01
                            ? (_debo ? '¡Con este pago quedas a paz y salvo!' : '¡Con este cobro queda saldado!')
                            : 'Quedarían pendientes ${_money.format(queda)}',
                        textAlign: TextAlign.center,
                        style: Brand.text(
                          size: 13,
                          weight: FontWeight.w600,
                          color: const Color(0xD9FFFFFF),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: _monto,
                    builder: (_, __) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (i, (label, valor)) in atajos.indexed) ...[
                            if (i > 0) const SizedBox(width: 8),
                            PanelPill(
                              label: label,
                              selected: _monto.value == valor,
                              tone: tone,
                              onTap: () => _monto.set(valor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Cuenta · Fecha · Nota ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: cuenta == null
                          ? Icons.account_balance_wallet_outlined
                          : accountStyle(cuenta.tipo).icon,
                      label: cuenta?.nombre ?? 'Sin cuenta',
                      highlighted: cuenta != null,
                      onTap: () => _pickCuenta(cuentas),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.calendar_today_outlined,
                      label: hoy ? 'Hoy' : brandDateLabel(_fecha).split(',').first,
                      highlighted: !hoy,
                      onTap: () async {
                        final d = await pickBrandDate(
                          context,
                          initial: _fecha,
                          last: DateTime.now(),
                        );
                        if (d != null) setState(() => _fecha = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: nota.isEmpty ? 'Nota' : nota,
                      highlighted: nota.isNotEmpty,
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
                      ? 'Escribe un monto'
                      : '${_debo ? 'Pagar' : 'Registrar cobro de'} ${_money.format(_monto.value)}',
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

  /// Hoja para escribir la nota del pago.
  Future<void> _abrirNota() {
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
                    BrandGroupTextRow(label: 'Nota', controller: _notaCtrl, hint: 'Opcional'),
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
}
