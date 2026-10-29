import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/prefs/form_prefs.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart'; // Para apiClientProvider
import 'form_panel.dart';
import 'transactions_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Mover dinero entre dos cuentas propias. Propone el último par usado.
class CreateTransferScreen extends ConsumerStatefulWidget {
  const CreateTransferScreen({super.key});

  @override
  ConsumerState<CreateTransferScreen> createState() =>
      _CreateTransferScreenState();
}

class _CreateTransferScreenState extends ConsumerState<CreateTransferScreen> {
  final _monto = AmountEntry();
  final _notaCtrl = TextEditingController();
  int? _origenId;
  int? _destinoId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargarUltimoPar();
  }

  Future<void> _cargarUltimoPar() async {
    final origen = await FormPrefs.getInt(FormPrefs.transferFrom);
    final destino = await FormPrefs.getInt(FormPrefs.transferTo);
    if (!mounted) return;
    setState(() {
      _origenId ??= origen;
      _destinoId ??= destino;
    });
  }

  @override
  void dispose() {
    _monto.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  double _saldo(Cuenta c) => c.saldoActual ?? c.saldoInicial;

  Future<int?> _pick(String title, List<Cuenta> cuentas, int? selected) {
    return showBrandPicker<int>(
      context,
      title: title,
      selected: selected,
      options: [
        for (final c in cuentas)
          BrandOption(
            c.id,
            c.nombre,
            subtitle: 'Saldo ${_money.format(_saldo(c))} · ${c.moneda}',
            icon: accountStyle(c.tipo).icon,
            color: accountStyle(c.tipo).fg,
          ),
      ],
    );
  }

  Future<void> _save(Cuenta? origen, Cuenta? destino) async {
    final monto = _monto.value;
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe el monto');
      return;
    }
    if (origen == null || destino == null) {
      showBrandSnack(context, 'Elige la cuenta de origen y la de destino');
      return;
    }
    if (origen.id == destino.id) {
      showBrandSnack(context, 'Elige dos cuentas distintas');
      return;
    }
    if (origen.tipo != 'TARJETA_CREDITO' && monto > _saldo(origen)) {
      showBrandSnack(
        context,
        'Saldo insuficiente en ${origen.nombre}: tienes ${_money.format(_saldo(origen))}',
      );
      return;
    }

    setState(() => _saving = true);
    final nota = _notaCtrl.text.trim();
    try {
      await ref.read(apiClientProvider).dio.post(
        '/api/transacciones/transfer',
        data: {
          'cuentaOrigenId': origen.id,
          'cuentaDestinoId': destino.id,
          'monto': monto,
          'moneda': origen.moneda,
          'titulo': nota.isEmpty ? null : nota,
          // Fecha y hora del teléfono: el servidor la guarda tal cual (sin
          // ella usaría la hora de Colombia, mal para otros países)
          'fechaTransaccion': formatApiDateTime(DateTime.now()),
        },
      );
      await FormPrefs.setInt(FormPrefs.transferFrom, origen.id);
      await FormPrefs.setInt(FormPrefs.transferTo, destino.id);
      await Future.wait([
        ref.read(transactionsNotifierProvider.notifier).refresh(),
        ref.read(accountsNotifierProvider.notifier).refresh(),
      ]);
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        'Transferiste ${_money.format(monto)} a ${destino.nombre}',
        error: false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final data = e.response?.data;
      final msg = data is Map ? data['message'] : null;
      showBrandSnack(context, '${msg ?? 'No se pudo hacer la transferencia'}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Motivo de la transferencia, en una hoja con el teclado del sistema.
  Future<void> _editarNota() {
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Motivo', style: Brand.text(size: 20, weight: FontWeight.w800)),
                const SizedBox(height: 14),
                TextField(
                  controller: _notaCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => Navigator.of(sheetCtx).pop(),
                  cursorColor: Brand.accent,
                  style: Brand.text(size: 15, weight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Ej: Ahorro del mes (opcional)',
                    hintStyle: Brand.text(size: 15, color: Brand.placeholder),
                    filled: true,
                    fillColor: Brand.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Brand.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Brand.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Brand.ink, width: 1.5),
                    ),
                  ),
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
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(accountsNotifierProvider);
    final cuentas = (cuentasAsync.valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    Cuenta? byId(int? id) => cuentas.where((c) => c.id == id).firstOrNull;

    // Sin par recordado: la de más saldo como origen y otra como destino
    final porSaldo = [...cuentas]..sort((a, b) => _saldo(b).compareTo(_saldo(a)));
    final origen = byId(_origenId) ?? porSaldo.firstOrNull;
    final destino = byId(_destinoId) ??
        porSaldo.where((c) => c.id != origen?.id).firstOrNull;
    final distintasMonedas =
        origen != null && destino != null && origen.moneda != destino.moneda;
    final moneda = origen?.moneda ?? 'COP';
    final nota = _notaCtrl.text.trim();

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel azul: monto y cuentas ────────────────────────────
              FormPanel(
                color: Brand.blue,
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
                          'Transferir',
                          textAlign: TextAlign.center,
                          style: Brand.text(
                            size: 17,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      PanelBadge(moneda),
                    ],
                  ),
                  PanelAmount(
                    entry: _monto,
                    label: destino == null
                        ? 'Transferencia'
                        : 'Transferencia a ${destino.nombre}',
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          PanelAccountRow(
                            label: 'Desde',
                            name: origen?.nombre ?? 'Elegir cuenta',
                            detail: origen == null ? null : _money.format(_saldo(origen)),
                            icon: origen == null
                                ? Icons.account_balance_wallet_outlined
                                : accountStyle(origen.tipo).icon,
                            onTap: () async {
                              final id = await _pick('Desde', cuentas, origen?.id);
                              if (id != null) setState(() => _origenId = id);
                            },
                          ),
                          const SizedBox(height: 8),
                          PanelAccountRow(
                            label: 'Hacia',
                            name: destino?.nombre ?? 'Elegir cuenta',
                            detail: destino == null ? null : _money.format(_saldo(destino)),
                            icon: destino == null
                                ? Icons.account_balance_wallet_outlined
                                : accountStyle(destino.tipo).icon,
                            onTap: () async {
                              final id = await _pick(
                                'Hacia',
                                cuentas.where((c) => c.id != origen?.id).toList(),
                                destino?.id,
                              );
                              if (id != null) setState(() => _destinoId = id);
                            },
                          ),
                        ],
                      ),
                      // Invierte origen y destino
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: origen == null || destino == null
                              ? null
                              : () => setState(() {
                                  _origenId = destino.id;
                                  _destinoId = origen.id;
                                }),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.swap_vert_rounded,
                              size: 20,
                              color: Brand.blue,
                              semanticLabel: 'Invertir cuentas',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (cuentasAsync.hasValue && cuentas.length < 2) ...[
                const SizedBox(height: 8),
                Text(
                  'Necesitas al menos dos cuentas activas para transferir.',
                  style: Brand.text(size: 12, color: Brand.expense),
                ),
              ],
              if (distintasMonedas) ...[
                const SizedBox(height: 8),
                Text(
                  'Las cuentas tienen monedas distintas; el monto no se convierte.',
                  style: Brand.text(size: 12, color: Brand.expense),
                ),
              ],
              const SizedBox(height: 14),
              FormActionButton(
                icon: Icons.edit_outlined,
                label: nota.isEmpty ? 'Motivo (opcional)' : nota,
                highlighted: nota.isNotEmpty,
                onTap: _editarNota,
              ),
              const SizedBox(height: 14),

              // ── Teclado (llena el espacio) y transferir ────────────────
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
                  label: _monto.isEmpty ? 'Escribe un monto' : 'Transferir',
                  background: Brand.ink,
                  loading: _saving,
                  onPressed: _monto.isEmpty ? null : () => _save(origen, destino),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
