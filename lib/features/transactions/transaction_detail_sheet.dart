import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/presupuesto_models.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';
import '../accounts/accounts_provider.dart';
import '../categories/category_style.dart';
import '../presupuestos/presupuestos_provider.dart';
import 'create_transaction_screen.dart';
import 'transactions_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Colores e ícono según el tipo de movimiento (ingreso, gasto, transferencia).
(Color fg, Color bg, String sign, String label) movementStyle(String tipo) =>
    switch (tipo) {
      'INGRESO' => (Brand.accent, Brand.accentSoft, '+', 'Ingreso'),
      'GASTO' => (Brand.expense, Brand.expenseSoft, '−', 'Gasto'),
      _ => (Brand.blue, Brand.blueSoft, '', 'Transferencia'),
    };

/// Abre el detalle de un movimiento (pantalla "Detalle" del diseño).
void showTransactionDetail(BuildContext context, Transaccion t) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => TransactionDetailScreen(t: t)),
  );
}

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.t});

  final Transaccion t;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _deleting = false;

  /// Reemplaza el detalle por el formulario con los datos del movimiento.
  void _editar() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CreateTransactionScreen.editar(widget.t),
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Eliminar este movimiento?',
          style: Brand.text(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          'El saldo de la cuenta se ajustará. Esta acción no se puede deshacer.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: Brand.text(weight: FontWeight.w700, color: Brand.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.expense),
            child: Text(
              'Eliminar',
              style: Brand.text(weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(transactionsNotifierProvider.notifier)
          .deleteTransaction(widget.t.id);
      // El saldo de las cuentas cambia con el movimiento
      ref.read(accountsNotifierProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.pop(context);
      showBrandSnack(context, 'Movimiento eliminado', error: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final (fg, bg, sign, label) = movementStyle(t.tipoNombre);
    final esIngreso = t.tipoNombre == 'INGRESO';
    final editable = t.tipoNombre == 'GASTO' || esIngreso;
    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? label);
    final fecha = DateFormat("d MMM y · HH:mm", 'es_ES')
        .format(t.fechaTransaccion)
        .replaceAll('.', '');
    final colorCategoria = categoryColors(t.categoriaColor, t.tipoNombre).$1;

    final filas = <(String, Widget)>[
      if (t.categoriaNombre != null)
        (
          'Categoría',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: colorCategoria, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(child: _valor(t.categoriaNombre!)),
            ],
          ),
        ),
      if (t.cuentaNombre != null)
        (esIngreso ? 'Cuenta destino' : 'Cuenta', _valor(t.cuentaNombre!)),
      ('Fecha', _valor(fecha)),
      if (t.metodoPagoNombre != null) ('Método de pago', _valor(t.metodoPagoNombre!)),
      if (t.repetir) ('Repetición', _valor('Pago recurrente')),
      if (t.titulo?.isNotEmpty == true) ('Nota', _valor(t.titulo!)),
      if (t.descripcion?.isNotEmpty == true && t.descripcion != t.titulo)
        ('Descripción', _valor(t.descripcion!)),
      if (t.notas?.isNotEmpty == true) ('Notas', _valor(t.notas!)),
    ];

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const BrandBackButton(),
                  Expanded(
                    child: Text(
                      'Detalle',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 17, weight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                children: [
                  // ── Encabezado: ícono, nombre, monto y etiquetas ──────
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        t.categoriaIcono != null
                            ? categoryIcon(t.categoriaIcono)
                            : Icons.swap_horiz_rounded,
                        color: fg,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Brand.text(size: 16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$sign${_money.format(t.monto)}',
                      style: Brand.text(
                        size: 38,
                        weight: FontWeight.w800,
                        color: fg,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Chip(text: '$label · ${t.moneda}', fg: fg, bg: bg),
                      if (t.repetir)
                        const _Chip(
                          text: 'Recurrente',
                          fg: Brand.ink,
                          bg: Brand.surface,
                          icon: Icons.autorenew_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Datos ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: Brand.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Brand.border),
                    ),
                    child: Column(
                      children: [
                        for (final (i, (k, v)) in filas.indexed) ...[
                          if (i > 0) const Divider(height: 1, color: Brand.border),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 50),
                            child: Row(
                              children: [
                                Text(k, style: Brand.text(size: 14, color: Brand.muted)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Align(alignment: Alignment.centerRight, child: v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Contexto: presupuesto o ingresos del mes ───────────
                  if (t.tipoNombre == 'GASTO') _ContextoPresupuesto(t: t),
                  if (esIngreso) _ContextoIngresos(t: t),
                ],
              ),
            ),

            // ── Acciones ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  if (!editable) ...[
                    // Una transferencia son dos movimientos enlazados (salida
                    // y entrada): se corrige eliminándola y creándola de nuevo
                    Text(
                      'Las transferencias no se editan: elimínala y créala de nuevo.',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 12, color: Brand.muted),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: BrandOutlineButton(
                          label: _deleting ? 'Eliminando…' : 'Eliminar',
                          foreground: Brand.expense,
                          borderColor: const Color(0xFFE3D2C6),
                          background: Brand.surface,
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          onPressed: _deleting ? null : _delete,
                        ),
                      ),
                      if (editable) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: BrandButton(
                            label: 'Editar',
                            background: Brand.ink,
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: _deleting ? null : _editar,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valor(String v) => Text(
    v,
    textAlign: TextAlign.right,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style: Brand.text(size: 14, weight: FontWeight.w700),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.fg, required this.bg, this.icon});

  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: bg == Brand.surface ? Border.all(color: Brand.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: Brand.text(size: 12, weight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con título, cifra, barra y una frase (contexto del detalle).
class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.title,
    required this.value,
    required this.bars,
    required this.caption,
  });

  final String title;
  final String value;
  final List<(double, Color)> bars; // tramos de la barra (fracción, color)
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Brand.text(size: 14, weight: FontWeight.w700)),
              ),
              Text(
                value,
                style: Brand.text(size: 13, weight: FontWeight.w700, color: Brand.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: ColoredBox(
                color: Brand.track,
                child: Row(
                  children: [
                    // flex 0 rompería el Row: los tramos vacíos no se pintan
                    for (final (flex, c) in [
                      ...bars.map((b) => ((b.$1.clamp(0, 1) * 1000).round(), b.$2)),
                      (
                        ((1 - bars.fold<double>(0, (s, b) => s + b.$1)).clamp(0, 1) * 1000)
                            .round(),
                        Colors.transparent,
                      ),
                    ])
                      if (flex > 0) Expanded(flex: flex, child: ColoredBox(color: c)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(caption, style: Brand.text(size: 12, color: Brand.muted, height: 1.4)),
        ],
      ),
    );
  }
}

/// Gasto: el presupuesto que lo cubre (el de su categoría primero).
class _ContextoPresupuesto extends ConsumerWidget {
  const _ContextoPresupuesto({required this.t});

  final Transaccion t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(presupuestosNotifierProvider).valueOrNull ?? const <Presupuesto>[];
    final f = t.fechaTransaccion;
    final candidatos = lista.where((b) {
      final finDia = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day, 23, 59, 59);
      return b.activo &&
          b.montoLimite > 0 &&
          !f.isBefore(b.fechaInicio) &&
          !f.isAfter(finDia) &&
          (b.categoriaId == null || b.categoriaId == t.categoriaId) &&
          (b.cuentaId == null || b.cuentaId == t.cuentaId);
    }).toList()
      ..sort((a, b) => (a.categoriaId == null ? 1 : 0).compareTo(b.categoriaId == null ? 1 : 0));
    final b = candidatos.firstOrNull;
    if (b == null) return const SizedBox.shrink();

    final usado = b.montoGastado / b.montoLimite;
    final esteGasto = t.monto / b.montoLimite;
    final restante = b.montoLimite - b.montoGastado;
    final color = usado >= 1 ? Brand.expense : Brand.accent;
    return _ContextCard(
      title: 'Presupuesto ${b.nombre}',
      value: '${(usado * 100).round()}%',
      bars: [(usado.clamp(0, 1).toDouble(), color)],
      caption: 'Este gasto es el ${(esteGasto * 100).round()}% del presupuesto. '
          '${restante >= 0 ? 'Te quedan ${_money.format(restante)}.' : 'Te pasaste por ${_money.format(-restante)}.'}',
    );
  }
}

/// Ingreso: cuánto representa de lo recibido en su mes.
class _ContextoIngresos extends ConsumerWidget {
  const _ContextoIngresos({required this.t});

  final Transaccion t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trans = ref.watch(transactionsNotifierProvider).valueOrNull ?? const <Transaccion>[];
    final f = t.fechaTransaccion;
    final total = trans
        .where((x) =>
            x.tipoNombre == 'INGRESO' &&
            x.fechaTransaccion.year == f.year &&
            x.fechaTransaccion.month == f.month)
        .fold<double>(0, (s, x) => s + x.monto);
    if (total <= 0) return const SizedBox.shrink();

    final share = (t.monto / total).clamp(0, 1).toDouble();
    final mes = DateFormat('MMMM', 'es_ES').format(f);
    return _ContextCard(
      title: 'Ingresos de $mes',
      value: _money.format(total),
      bars: [(share, Brand.accent), (1 - share, Brand.mint)],
      caption: 'Este ingreso es el ${(share * 100).round()}% de lo que recibiste este mes.',
    );
  }
}
