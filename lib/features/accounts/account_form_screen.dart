import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../../core/utils/monedas_constants.dart';
import '../categories/category_style.dart';
import '../transactions/form_panel.dart';
import '../transactions/transactions_provider.dart';
import '../transactions/transactions_service.dart';
import 'account_style.dart';
import 'accounts_provider.dart';

const _tipos = [
  'BANCARIA',
  'EFECTIVO',
  'TARJETA_DEBITO',
  'TARJETA_CREDITO',
  'DIGITAL',
  'AHORRO',
  'INVERSION',
];

// Nombre del ícono guardado en cuentas.icono según el tipo
const _iconoPorTipo = {
  'BANCARIA': 'account_balance',
  'EFECTIVO': 'payments',
  'TARJETA_DEBITO': 'credit_card',
  'TARJETA_CREDITO': 'credit_card',
  'DIGITAL': 'wallet',
  'AHORRO': 'savings',
  'INVERSION': 'trending_up',
};

// USD aparece varias veces (Ecuador, El Salvador, Panamá): una por código
final _monedas = {
  for (final m in MonedasConstants.monedasHispanas) m.codigo: m,
}.values.toList();

/// Crear o editar una cuenta, con el diseño del formulario de movimientos:
/// panel del color del tipo con el nombre, el saldo y los tipos; botones de
/// moneda, tarjeta y más; y el teclado propio abajo.
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.cuenta});

  /// Null para crear una nueva.
  final Cuenta? cuenta;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final _editing = widget.cuenta != null;
  late final _nombreCtrl = TextEditingController(text: widget.cuenta?.nombre ?? '');
  final _nombreFocus = FocusNode();
  late final _descCtrl = TextEditingController(text: widget.cuenta?.descripcion ?? '');
  final _saldo = AmountEntry();
  late String _tipo = widget.cuenta?.tipo ?? 'BANCARIA';
  late String _moneda = widget.cuenta?.moneda ?? 'COP';
  late bool _activa = widget.cuenta?.activa ?? true;
  // Tarjeta de crédito: cupo, día de corte y día límite de pago
  late final _cupoCtrl = TextEditingController(
    text: widget.cuenta?.cupo?.toStringAsFixed(0) ?? '',
  );
  late int? _diaCorte = widget.cuenta?.diaCorte;
  late int? _diaPago = widget.cuenta?.diaPago;
  bool _nombreEditado = false;
  bool _saving = false;

  bool get _esCredito => _tipo == 'TARJETA_CREDITO';

  // Al crear una tarjeta de crédito se pide la deuda; la API no acepta saldo
  // inicial negativo, así que se registra como un gasto de apertura
  bool get _pideDeuda => !_editing && _tipo == 'TARJETA_CREDITO';

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _saldo.set(widget.cuenta!.saldoInicial);
    } else {
      _nombreCtrl.text = accountStyle(_tipo).label;
    }
    _descCtrl.addListener(() => setState(() {})); // "Nota" en el botón
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreFocus.dispose();
    _descCtrl.dispose();
    _saldo.dispose();
    _cupoCtrl.dispose();
    super.dispose();
  }

  void _setTipo(String tipo) {
    setState(() {
      _tipo = tipo;
      // El nombre sigue al tipo mientras el usuario no lo haya escrito
      if (!_editing && !_nombreEditado) _nombreCtrl.text = accountStyle(tipo).label;
    });
  }

  Future<void> _pickMoneda() async {
    _nombreFocus.unfocus();
    final picked = await showBrandPicker<String>(
      context,
      title: 'Moneda',
      selected: _moneda,
      options: [
        for (final m in _monedas)
          BrandOption(m.codigo, '${m.nombreMoneda} (${m.codigo})', subtitle: m.pais),
      ],
    );
    if (picked != null) setState(() => _moneda = picked);
  }

  Future<void> _pickDia(
    String titulo,
    int? actual,
    ValueChanged<int?> set,
    void Function(VoidCallback) update,
  ) async {
    final dia = await showBrandPicker<int>(
      context,
      title: titulo,
      selected: actual ?? 0,
      options: [
        const BrandOption(0, 'Sin definir'),
        for (var d = 1; d <= 31; d++) BrandOption(d, 'Día $d'),
      ],
    );
    if (dia != null) update(() => set(dia == 0 ? null : dia));
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      showBrandSnack(context, 'Ponle un nombre a la cuenta');
      _nombreFocus.requestFocus();
      return;
    }
    final monto = _saldo.value ?? 0;
    final desc = _descCtrl.text.trim();
    final color = colorToHex(accountStyle(_tipo).fg);
    // Solo las tarjetas de crédito guardan cupo y fechas
    final cupo = _esCredito ? parseAmount(_cupoCtrl.text) : null;
    final diaCorte = _esCredito ? _diaCorte : null;
    final diaPago = _esCredito ? _diaPago : null;

    setState(() => _saving = true);
    final notifier = ref.read(accountsNotifierProvider.notifier);
    try {
      if (_editing) {
        await notifier.updateAccount(
          widget.cuenta!.id,
          UpdateCuentaRequest(
            nombre: nombre,
            tipo: _tipo,
            moneda: _moneda,
            saldoInicial: monto,
            color: color,
            icono: _iconoPorTipo[_tipo],
            descripcion: desc.isEmpty ? null : desc,
            activa: _activa,
            tarjeta: true, // si dejó de ser de crédito, se borran
            cupo: cupo,
            diaCorte: diaCorte,
            diaPago: diaPago,
          ),
        );
      } else {
        final cuenta = await ref.read(accountsServiceProvider).createAccount(
          CreateCuentaRequest(
            nombre: nombre,
            tipo: _tipo,
            moneda: _moneda,
            saldoInicial: _pideDeuda ? 0 : monto,
            color: color,
            icono: _iconoPorTipo[_tipo],
            descripcion: desc.isEmpty ? null : desc,
            cupo: cupo,
            diaCorte: diaCorte,
            diaPago: diaPago,
          ),
        );
        if (_pideDeuda && monto > 0) {
          await TransactionsService(ApiClient()).createTransaction(
            CreateTransaccionRequest(
              cuentaId: cuenta.id,
              tipoTransaccionId: 2, // GASTO
              monto: monto,
              moneda: _moneda,
              titulo: 'Deuda inicial de la tarjeta',
              fechaTransaccion: DateTime.now(),
            ),
          );
          await ref.read(transactionsNotifierProvider.notifier).refresh();
        }
        await notifier.refresh();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showBrandSnack(
        context,
        _editing ? 'Cuenta actualizada' : 'Cuenta creada',
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
    final style = accountStyle(_tipo);
    final desc = _descCtrl.text.trim();
    final tarjetaLista = _diaPago != null || _cupoCtrl.text.trim().isNotEmpty;

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
              // ── Panel del color del tipo: nombre, saldo y tipos ────────
              FormPanel(
                color: style.fg,
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
                          _editing ? 'Editar cuenta' : 'Nueva cuenta',
                          textAlign: TextAlign.center,
                          style: Brand.text(
                            size: 16,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // La moneda: tocarla abre el selector
                      GestureDetector(
                        onTap: _pickMoneda,
                        child: PanelBadge(_moneda),
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
                    // y queda el propio para el saldo
                    onSubmitted: (_) => _nombreFocus.unfocus(),
                    cursorColor: Colors.white,
                    style: Brand.text(size: 18, weight: FontWeight.w800, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Nombre de la cuenta',
                      hintStyle: Brand.text(
                        size: 18,
                        weight: FontWeight.w700,
                        color: const Color(0x99FFFFFF),
                      ),
                      filled: true,
                      fillColor: const Color(0x29FFFFFF),
                      prefixIcon: Icon(style.icon, color: Colors.white, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  PanelAmount(
                    entry: _saldo,
                    sign: _pideDeuda ? '−' : '',
                    label: _pideDeuda
                        ? 'Deuda actual'
                        : _editing
                        ? 'Saldo inicial'
                        : '¿Cuánto tienes hoy?',
                  ),
                  Text(
                    _pideDeuda
                        ? 'Lo que debes hoy en la tarjeta. Déjalo en 0 si está al día.'
                        : _editing
                        ? 'Cambiarlo ajusta el saldo actual en la misma diferencia.'
                        : 'Déjalo en 0 si la cuenta está vacía.',
                    textAlign: TextAlign.center,
                    style: Brand.text(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xD9FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tipos, deslizables de borde a borde del panel
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _tipos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final t = _tipos[i];
                        return PanelPill(
                          label: accountStyle(t).label,
                          selected: t == _tipo,
                          tone: style.fg,
                          onTap: () => _setTipo(t),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Moneda · Tarjeta · Más ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.currency_exchange_rounded,
                      label: _moneda,
                      onTap: _pickMoneda,
                    ),
                  ),
                  if (_esCredito) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormActionButton(
                        icon: Icons.event_outlined,
                        label: _diaPago == null ? 'Cupo y fechas' : 'Paga el $_diaPago',
                        highlighted: tarjetaLista,
                        onTap: _abrirTarjeta,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: desc.isNotEmpty
                          ? desc
                          : _editing && !_activa
                          ? 'Inactiva'
                          : 'Nota',
                      highlighted: desc.isNotEmpty || !_activa,
                      onTap: _abrirMas,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Teclado (llena el espacio) y guardar ───────────────────
              Expanded(
                child: AmountKeypad(
                  entry: _saldo,
                  decimals: monedaConCentavos(_moneda),
                  expand: true,
                ),
              ),
              const SizedBox(height: 14),
              BrandButton(
                label: _editing ? 'Guardar cambios' : 'Crear cuenta',
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

  Future<void> _abrirTarjeta() async {
    await _hoja(
      'Tarjeta de crédito',
      (update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandGroup(
            children: [
              BrandGroupTextRow(
                label: 'Cupo',
                controller: _cupoCtrl,
                hint: 'Ej: 5.000.000',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              BrandGroupRow(
                label: 'Día de corte',
                value: _diaCorte == null ? 'Sin definir' : 'Día $_diaCorte',
                placeholder: _diaCorte == null,
                onTap: () => _pickDia('Día de corte', _diaCorte, (d) => _diaCorte = d, update),
              ),
              BrandGroupRow(
                label: 'Día límite de pago',
                value: _diaPago == null ? 'Sin definir' : 'Día $_diaPago',
                placeholder: _diaPago == null,
                onTap: () => _pickDia('Día límite de pago', _diaPago, (d) => _diaPago = d, update),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Con el día de pago te recordamos pagar la tarjeta a tiempo.',
            style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
          ),
        ],
      ),
    );
    setState(() {}); // el cupo escrito en la hoja
  }

  Future<void> _abrirMas() => _hoja(
    _editing ? 'Más opciones' : 'Nota',
    (update) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandTextArea(controller: _descCtrl, hint: 'Ej: cuenta de nómina'),
        if (_editing) ...[
          const SizedBox(height: 14),
          BrandGroup(
            children: [
              BrandSwitchRow(
                title: 'Cuenta activa',
                subtitle: 'Las inactivas no aparecen al registrar movimientos '
                    'ni suman al saldo total',
                value: _activa,
                onChanged: (v) => update(() => _activa = v),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
