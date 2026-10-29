import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/compras/compra_automatica.dart';
import '../../core/models/category_models.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/prefs/form_prefs.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_form.dart';
import '../../core/theme/brand_keypad.dart';
import '../accounts/account_style.dart';
import '../accounts/accounts_provider.dart';
import '../categories/categories_provider.dart';
import '../recurring/recurring_provider.dart';
import '../recurring/recurring_service.dart';
import 'category_suggestion.dart';
import 'form_panel.dart';
import 'transactions_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

// IDs de la tabla metodos_pago (datos iniciales de la BD)
const _metodosPago = <(int, String)>[
  (1, 'Efectivo'),
  (2, 'Tarjeta de débito'),
  (3, 'Tarjeta de crédito'),
  (4, 'Transferencia bancaria'),
  (5, 'Cheque'),
  (6, 'PayPal'),
  (7, 'Apple Pay'),
  (8, 'Google Pay'),
];

/// Nuevo gasto o ingreso. Pensado para registrar rápido: monto con teclado
/// propio, categorías ordenadas por uso, cuenta recordada y los demás datos
/// plegados en "Detalles".
class CreateTransactionScreen extends ConsumerStatefulWidget {
  final String tipoTransaccion; // 'INGRESO', 'GASTO'
  // Datos que llegan ya escritos (p. ej. desde la notificación de registro rápido)
  final double? montoInicial;
  final String? notaInicial;

  /// Movimiento a editar: el formulario arranca con sus datos y guarda los
  /// cambios sobre él (sin "Se repite").
  final Transaccion? editar;

  const CreateTransactionScreen({
    super.key,
    required this.tipoTransaccion,
    this.montoInicial,
    this.notaInicial,
    this.editar,
  });

  /// Formulario para editar [t] (gasto o ingreso).
  factory CreateTransactionScreen.editar(Transaccion t, {Key? key}) =>
      CreateTransactionScreen(key: key, tipoTransaccion: t.tipoNombre, editar: t);

  @override
  ConsumerState<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final _monto = AmountEntry();
  final _notaCtrl = TextEditingController();

  late String _tipo = widget.tipoTransaccion == 'INGRESO' ? 'INGRESO' : 'GASTO';
  int? _categoriaId;
  bool _categoriaElegida = false; // true si la eligió el usuario (no sugerida)
  int? _cuentaId;
  final _ultimaCuenta = <String, int?>{};
  DateTime _fecha = DateTime.now();
  int? _metodoPagoId;
  bool _repetir = false;
  String _frecuencia = 'MENSUAL';
  DateTime? _fechaFin;
  bool _saving = false;

  bool get _isIngreso => _tipo == 'INGRESO';
  bool get _editando => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    if (e != null) {
      _monto.set(e.monto);
      _notaCtrl.text = e.titulo ?? '';
      _categoriaId = e.categoriaId;
      _categoriaElegida = true; // no reemplazarla por una sugerida
      _cuentaId = e.cuentaId;
      _fecha = e.fechaTransaccion;
      _metodoPagoId = e.metodoPagoId;
    } else {
      _monto.set(widget.montoInicial);
      _notaCtrl.text = widget.notaInicial ?? '';
    }
    _cargarUltimasCuentas();
  }

  Future<void> _cargarUltimasCuentas() async {
    final gasto = await FormPrefs.getInt(FormPrefs.lastAccount('GASTO'));
    final ingreso = await FormPrefs.getInt(FormPrefs.lastAccount('INGRESO'));
    if (!mounted) return;
    setState(() {
      _ultimaCuenta['GASTO'] = gasto;
      _ultimaCuenta['INGRESO'] = ingreso;
    });
  }

  @override
  void dispose() {
    _monto.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  /// Cuenta propuesta: la última usada para este tipo; si no, la de más saldo.
  Cuenta? _cuentaPropuesta(List<Cuenta> cuentas) {
    if (cuentas.isEmpty) return null;
    final id = _cuentaId ?? _ultimaCuenta[_tipo];
    final match = cuentas.where((c) => c.id == id).firstOrNull;
    if (match != null) return match;
    return ([...cuentas]
          ..sort((a, b) => (b.saldoActual ?? b.saldoInicial)
              .compareTo(a.saldoActual ?? a.saldoInicial)))
        .first;
  }

  /// Categorías del tipo, las más usadas en los últimos 90 días primero.
  List<Categoria> _categoriasOrdenadas(
    List<Categoria> all,
    List<Transaccion> trans,
  ) {
    final desde = DateTime.now().subtract(const Duration(days: 90));
    final usos = <int, int>{};
    for (final t in trans) {
      if (t.tipoNombre != _tipo || t.categoriaId == null) continue;
      if (t.fechaTransaccion.isBefore(desde)) continue;
      usos[t.categoriaId!] = (usos[t.categoriaId!] ?? 0) + 1;
    }
    return all
        .where((c) => c.activo && (c.tipo == _tipo || c.tipo == 'AMBOS'))
        .toList()
      ..sort((a, b) {
        final byUse = (usos[b.id] ?? 0).compareTo(usos[a.id] ?? 0);
        return byUse != 0
            ? byUse
            : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });
  }

  void _onNota(String nota, List<Transaccion> trans, List<Categoria> cats) {
    if (_categoriaElegida) return;
    final sugerida = sugerirCategoriaPorNota(
      nota,
      _tipo,
      trans,
      cats.map((c) => c.id).toSet(),
    );
    if (sugerida != null && sugerida != _categoriaId) {
      setState(() => _categoriaId = sugerida);
    }
  }

  Future<void> _pickCuenta(List<Cuenta> cuentas, Cuenta? actual) async {
    final picked = await showBrandPicker<int>(
      context,
      title: 'Cuenta',
      selected: actual?.id,
      options: [
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
    if (picked != null) setState(() => _cuentaId = picked);
  }

  Future<void> _pickMetodo() async {
    final picked = await showBrandPicker<int>(
      context,
      title: 'Método de pago',
      selected: _metodoPagoId ?? 0,
      options: [
        const BrandOption(0, 'Sin especificar'),
        for (final (id, nombre) in _metodosPago) BrandOption(id, nombre),
      ],
    );
    if (picked != null) setState(() => _metodoPagoId = picked == 0 ? null : picked);
  }

  DateTime _conHoraActual(DateTime dia) {
    final ahora = DateTime.now();
    return DateTime(dia.year, dia.month, dia.day, ahora.hour, ahora.minute, ahora.second);
  }

  Future<void> _save(Cuenta? cuenta, Categoria? categoria) async {
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
      showBrandSnack(context, 'Primero crea una cuenta en Perfil → Mis cuentas');
      return;
    }
    // Una tarjeta de crédito puede quedar en negativo; las demás cuentas no.
    // Al editar, el saldo todavía incluye el movimiento original: se descuenta
    var saldo = cuenta.saldoActual ?? cuenta.saldoInicial;
    final original = widget.editar;
    if (original != null && original.cuentaId == cuenta.id) {
      if (original.tipoNombre == 'GASTO') saldo += original.monto;
      if (original.tipoNombre == 'INGRESO') saldo -= original.monto;
    }
    if (!_isIngreso && cuenta.tipo != 'TARJETA_CREDITO' && monto > saldo) {
      showBrandSnack(
        context,
        'Saldo insuficiente en ${cuenta.nombre}: tienes ${_money.format(saldo)}',
      );
      return;
    }

    setState(() => _saving = true);
    final nota = _notaCtrl.text.trim();
    if (original != null) return _guardarCambios(original, cuenta, categoria, monto, nota);
    try {
      await ref.read(transactionsNotifierProvider.notifier).createTransaction(
        CreateTransaccionRequest(
          cuentaId: cuenta.id,
          tipoTransaccionId: _isIngreso ? 1 : 2,
          categoriaId: categoria.id,
          metodoPagoId: _metodoPagoId,
          monto: monto,
          moneda: cuenta.moneda,
          titulo: nota.isEmpty ? null : nota,
          // La fecha elegida con la hora actual del teléfono: el servidor la
          // guarda tal cual, así sirve en cualquier país
          fechaTransaccion: _conHoraActual(_fecha),
          repetir: _repetir,
        ),
      );
      await FormPrefs.setInt(FormPrefs.lastAccount(_tipo), cuenta.id);

      if (_repetir) {
        String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
        await ref.read(recurringServiceProvider).createRule(
          CreatePagoRecurrenteRequest(
            categoriaId: categoria.id,
            cuentaId: cuenta.id,
            metodoPagoId: _metodoPagoId,
            monto: monto,
            descripcion: nota.isEmpty ? categoria.nombre : nota,
            frecuencia: _frecuencia,
            // El día del cobro se toma de la fecha del movimiento
            diaVencimiento: _frecuencia == 'SEMANAL' || _frecuencia == 'DIARIO'
                ? null
                : _fecha.day,
            diaSemana: _frecuencia == 'SEMANAL' ? _fecha.weekday : null,
            fechaInicio: fmt(_fecha),
            fechaFin: _fechaFin == null ? null : fmt(_fechaFin!),
          ),
        );
        ref.invalidate(recurringProvider);
      }

      await ref.read(accountsNotifierProvider.notifier).refresh();
      if (!mounted) return;
      // true: se guardó (la hoja de registro rápido se cierra al recibirlo)
      Navigator.of(context).pop(true);
      showBrandSnack(
        context,
        '${_isIngreso ? 'Ingreso' : 'Gasto'} de ${_money.format(monto)} en ${categoria.nombre}',
        error: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Edición: actualiza el movimiento original (los saldos se recalculan
  /// solos en el servidor, que los deriva de los movimientos).
  Future<void> _guardarCambios(
    Transaccion original,
    Cuenta cuenta,
    Categoria categoria,
    double monto,
    String nota,
  ) async {
    try {
      final o = original.fechaTransaccion;
      await ref.read(transactionsNotifierProvider.notifier).updateTransaction(
        original.id,
        UpdateTransaccionRequest(
          cuentaId: cuenta.id,
          tipoTransaccionId: _isIngreso ? 1 : 2,
          categoriaId: categoria.id,
          metodoPagoId: _metodoPagoId,
          monto: monto,
          moneda: cuenta.moneda,
          titulo: nota, // '' borra la nota
          // La fecha elegida conservando la hora original del movimiento
          fechaTransaccion: DateTime(
            _fecha.year,
            _fecha.month,
            _fecha.day,
            o.hour,
            o.minute,
            o.second,
          ),
        ),
      );
      // Compra registrada automáticamente: la tarjeta queda asociada a la
      // cuenta elegida para las próximas compras con ella
      await CompraAutomatica.aprenderTarjeta(original.notas, cuenta.id);
      await ref.read(accountsNotifierProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showBrandSnack(context, 'Movimiento actualizado', error: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(accountsNotifierProvider);
    final cuentas = (cuentasAsync.valueOrNull ?? const <Cuenta>[])
        .where((c) => c.activa)
        .toList();
    final sinCuentas = cuentasAsync.hasValue && cuentas.isEmpty;
    final trans = ref.watch(transactionsNotifierProvider).valueOrNull ?? const [];
    final categorias = _categoriasOrdenadas(
      ref.watch(categoriesNotifierProvider).valueOrNull ?? const [],
      trans,
    );
    // Nota precargada: sugerir la categoría en cuanto hay datos para hacerlo
    if (_categoriaId == null &&
        !_categoriaElegida &&
        _notaCtrl.text.isNotEmpty &&
        trans.isNotEmpty) {
      _categoriaId = sugerirCategoriaPorNota(
        _notaCtrl.text,
        _tipo,
        trans,
        categorias.map((c) => c.id).toSet(),
      );
    }

    final cuenta = _cuentaPropuesta(cuentas);
    final categoria = categorias.where((c) => c.id == _categoriaId).firstOrNull;
    final moneda = cuenta?.moneda ?? 'COP';
    final tone = _isIngreso ? Brand.accent : Brand.expense;
    final tipoLabel = _editando
        ? (_isIngreso ? 'Editar ingreso' : 'Editar gasto')
        : (_isIngreso ? 'Ingreso' : 'Gasto');
    final nota = _notaCtrl.text.trim();
    final hoy = DateUtils.isSameDay(_fecha, DateTime.now());

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel de color: tipo, monto y categorías ───────────────
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
                          _cuentaId = null; // vuelve a la última cuenta de ese tipo
                          if (categoria != null &&
                              categoria.tipo != 'AMBOS' &&
                              categoria.tipo != v) {
                            _categoriaId = null;
                            _categoriaElegida = false;
                          }
                        }),
                      ),
                      PanelBadge(moneda),
                    ],
                  ),
                  PanelAmount(
                    entry: _monto,
                    sign: _isIngreso ? '+' : '−',
                    label: categoria == null
                        ? tipoLabel
                        : '$tipoLabel en ${categoria.nombre}'
                              '${_categoriaElegida ? '' : ' · sugerida'}',
                  ),
                  const SizedBox(height: 10),
                  if (categorias.isEmpty)
                    Text(
                      'No tienes categorías de este tipo. Créalas en Perfil → Categorías.',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 13, color: Colors.white),
                    )
                  else
                    // Deslizable, de borde a borde del panel; las más usadas primero
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
                            onTap: () => setState(() {
                              _categoriaId = c.id;
                              _categoriaElegida = true;
                            }),
                          );
                        },
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
                      label: cuenta?.nombre ?? 'Cuenta',
                      onTap: cuentas.isEmpty ? null : () => _pickCuenta(cuentas, cuenta),
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
                          last: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _fecha = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FormActionButton(
                      icon: Icons.edit_outlined,
                      label: nota.isNotEmpty
                          ? nota
                          : _repetir
                          ? PagoRecurrente.frecuencias[_frecuencia] ?? 'Nota'
                          : 'Nota',
                      highlighted: nota.isNotEmpty || _repetir || _metodoPagoId != null,
                      onTap: () => _abrirDetalles(trans, categorias),
                    ),
                  ),
                ],
              ),
              if (sinCuentas) ...[
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
                  label: _monto.isEmpty
                      ? 'Escribe un monto'
                      : _editando
                      ? 'Guardar cambios'
                      : _isIngreso
                      ? 'Guardar ingreso'
                      : 'Guardar gasto',
                  background: Brand.ink,
                  loading: _saving,
                  onPressed: _monto.isEmpty ? null : () => _save(cuenta, categoria),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nota, método de pago y repetición, en una hoja aparte para que el
  /// formulario quede con lo esencial.
  Future<void> _abrirDetalles(
    List<Transaccion> trans,
    List<Categoria> categorias,
  ) {
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
                    Text('Detalles', style: Brand.text(size: 20, weight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    BrandGroup(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 54,
                            child: Row(
                              children: [
                                Text('Nota', style: Brand.text(size: 14, color: Brand.muted)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _notaCtrl,
                                    autofocus: _notaCtrl.text.isEmpty,
                                    textAlign: TextAlign.right,
                                    textCapitalization: TextCapitalization.sentences,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => Navigator.of(sheetCtx).pop(),
                                    onChanged: (v) {
                                      update(() {});
                                      _onNota(v, trans, categorias);
                                    },
                                    cursorColor: Brand.accent,
                                    style: Brand.text(size: 14, weight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: 'Ej: Almuerzo, Uber…',
                                      hintStyle: Brand.text(size: 14, color: Brand.placeholder),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        BrandGroupRow(
                          label: 'Método de pago',
                          value: _metodosPago
                                  .where((m) => m.$1 == _metodoPagoId)
                                  .firstOrNull
                                  ?.$2 ??
                              'Opcional',
                          placeholder: _metodoPagoId == null,
                          onTap: () async {
                            await _pickMetodo();
                            setSheet(() {});
                          },
                        ),
                      ],
                    ),
                    // Repetir solo al crear: editar no crea pagos recurrentes
                    if (!_editando) ...[
                    const SizedBox(height: 10),
                    BrandGroup(
                      children: [
                        BrandSwitchRow(
                          title: 'Se repite',
                          subtitle: 'Se registrará solo en cada fecha',
                          value: _repetir,
                          onChanged: (v) => update(() => _repetir = v),
                        ),
                        if (_repetir) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Wrap(
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
                                    side: BorderSide(
                                      color: _frecuencia == e.key ? Brand.ink : Brand.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    labelStyle: Brand.text(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: _frecuencia == e.key ? Colors.white : Brand.ink,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          BrandGroupRow(
                            label: 'Termina',
                            value: _fechaFin == null ? 'Nunca' : brandDateLabel(_fechaFin!),
                            onTap: () async {
                              final d = await pickBrandDate(
                                context,
                                initial: _fechaFin ?? _fecha.add(const Duration(days: 365)),
                                first: _fecha,
                              );
                              update(() => _fechaFin = d);
                            },
                          ),
                        ],
                      ],
                    ),
                    ],
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
}
