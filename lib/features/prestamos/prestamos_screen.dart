import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/theme/brand.dart';
import 'create_edit_prestamo_screen.dart';
import 'pago_prestamo_dialog.dart';
import 'prestamo_cuotas_screen.dart';
import 'prestamos_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

// Colores de las barras, en el orden en que se asignan
const _palette = [Brand.accent, Brand.blue, Color(0xFF6B3FA0), Brand.expense];

// DEUDA = yo debo · PRESTAMO = me deben (columna prestamos.tipo)
enum _Tab { debo, meDeben }

// ─── Fechas y urgencia ────────────────────────────────────────────────────────

DateTime? _venceDe(Prestamo p) =>
    p.enCuotas ? p.proximoVencimiento : p.fechaFin;

int _diasHasta(DateTime fecha) => DateUtils.dateOnly(
  fecha,
).difference(DateUtils.dateOnly(DateTime.now())).inDays;

bool _estaVencido(Prestamo p) {
  final vence = _venceDe(p);
  return vence != null && _diasHasta(vence) < 0;
}

bool _vencePronto(Prestamo p, {int dias = 7}) {
  final vence = _venceDe(p);
  if (vence == null) return false;
  final faltan = _diasHasta(vence);
  return faltan >= 0 && faltan <= dias;
}

/// Los vencidos primero y, entre ellos, el más antiguo; los que no tienen
/// fecha, al final.
int _porUrgencia(Prestamo a, Prestamo b) {
  final va = _venceDe(a);
  final vb = _venceDe(b);
  if (va == null && vb == null) {
    return b.saldoPendiente.compareTo(a.saldoPendiente);
  }
  if (va == null) return 1;
  if (vb == null) return -1;
  return va.compareTo(vb);
}

({String texto, bool urgente}) _estadoDeVencimiento(DateTime? vence) {
  if (vence == null) return (texto: 'Sin fecha', urgente: false);
  final dias = _diasHasta(vence);
  if (dias < 0) {
    final pasados = -dias;
    return (
      texto: pasados == 1 ? 'Venció ayer' : 'Venció hace $pasados días',
      urgente: true,
    );
  }
  if (dias == 0) return (texto: 'Vence hoy', urgente: true);
  if (dias == 1) return (texto: 'Vence mañana', urgente: true);
  if (dias <= 7) return (texto: 'Vence en $dias días', urgente: true);
  final fecha = DateFormat("d 'de' MMM", 'es_ES').format(vence);
  return (texto: 'Vence el $fecha', urgente: false);
}

// ─── Préstamos ────────────────────────────────────────────────────────────────
class PrestamosScreen extends ConsumerStatefulWidget {
  const PrestamosScreen({super.key});

  @override
  ConsumerState<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends ConsumerState<PrestamosScreen> {
  _Tab _tab = _Tab.debo;

  String get _tipo => _tab == _Tab.debo ? 'DEUDA' : 'PRESTAMO';

  void _openForm([Prestamo? p]) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CreateEditPrestamoScreen(prestamo: p)),
  );

  void _pay(Prestamo p) => abrirPagoPrestamo(context, p);

  void _openCuotas(Prestamo p) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => PrestamoCuotasScreen(prestamo: p)));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prestamosNotifierProvider);
    final todos = async.valueOrNull;
    final counts = todos == null
        ? null
        : {
            _Tab.debo: todos
                .where((p) => p.tipo == 'DEUDA' && p.activa && !p.estaPagado)
                .length,
            _Tab.meDeben: todos
                .where((p) => p.tipo == 'PRESTAMO' && p.activa && !p.estaPagado)
                .length,
          };

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () =>
              ref.read(prestamosNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Préstamos', style: Brand.title(size: 22)),
                  ),
                  Material(
                    color: Brand.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _openForm(),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          semanticLabel: 'Nuevo préstamo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Segmented(
                value: _tab,
                onChanged: (t) => setState(() => _tab = t),
                counts: counts,
              ),
              const SizedBox(height: 18),
              ...async.when(
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Brand.accent,
                      ),
                    ),
                  ),
                ],
                error: (_, __) => [
                  const _Message(
                    icon: Icons.wifi_off_rounded,
                    title: 'No se pudieron cargar tus préstamos',
                    body:
                        'Revisa tu conexión y desliza hacia abajo para '
                        'reintentar.',
                  ),
                ],
                data: (all) =>
                    _content(all.where((p) => p.tipo == _tipo).toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(List<Prestamo> items) {
    final debo = _tab == _Tab.debo;
    final activos = items.where((p) => p.activa && !p.estaPagado).toList()
      ..sort(_porUrgencia);
    final pausados = items.where((p) => !p.activa && !p.estaPagado).toList()
      ..sort(_porUrgencia);
    final pagados = items.where((p) => p.estaPagado).toList()
      ..sort((a, b) => b.fechaActualizacion.compareTo(a.fechaActualizacion));
    final soloCuotas =
        activos.isNotEmpty &&
        activos.every((p) => p.enCuotas && p.capitalPendiente != null);
    final pendiente = activos.fold<double>(
      0,
      (s, p) =>
          s +
          (soloCuotas
              ? (p.capitalPendiente ?? p.saldoPendiente)
              : p.saldoPendiente),
    );
    final intereses = soloCuotas
        ? activos.fold<double>(0, (s, p) => s + (p.totalIntereses ?? 0))
        : null;
    final vencidos = activos.where(_estaVencido).length;
    final proximos = activos
        .where((p) => !_estaVencido(p) && _vencePronto(p))
        .length;

    if (items.isEmpty) {
      return [
        _Message(
          icon: debo ? Icons.request_quote_outlined : Icons.handshake_outlined,
          title: debo ? 'No tienes deudas registradas' : 'Nadie te debe',
          body: debo
              ? 'Registra un crédito o algo que debas para llevar la cuenta '
                    'de cuánto te falta.'
              : 'Si le prestas dinero a alguien, regístralo aquí para no '
                    'perder la cuenta de lo que te devuelve.',
          action: BrandButton(
            label: debo ? 'Registrar deuda' : 'Registrar préstamo',
            onPressed: () => _openForm(),
          ),
        ),
      ];
    }

    Widget card(Prestamo p) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _LoanCard(
        p: p,
        color: _palette[p.id.abs() % _palette.length],
        debo: debo,
        onTap: () => p.enCuotas ? _openCuotas(p) : _showOptions(p),
        onPay: () => _pay(p),
        onOptions: () => _showOptions(p),
      ),
    );

    Widget paidCard(Prestamo p) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _PaidCard(p: p, debo: debo, onTap: () => _showOptions(p)),
    );

    Widget section(String title, int n) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        '${title.toUpperCase()} · $n',
        style: Brand.text(
          size: 12,
          weight: FontWeight.w700,
          color: Brand.muted,
          letterSpacing: 0.7,
        ),
      ),
    );

    return [
      if (activos.isNotEmpty) ...[
        _HeroResumen(
          debo: debo,
          pendiente: pendiente,
          intereses: intereses,
          activos: activos.length,
          vencidos: vencidos,
          proximos: proximos,
        ),
        const SizedBox(height: 18),
      ],
      ...activos.map(card),
      if (pausados.isNotEmpty) ...[
        section('Pausados', pausados.length),
        ...pausados.map(card),
      ],
      if (pagados.isNotEmpty) ...[
        section(debo ? 'Pagados' : 'Cobrados', pagados.length),
        ...pagados.map(paidCard),
      ],
    ];
  }

  void _showOptions(Prestamo p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        Widget option(
          IconData icon,
          String label,
          VoidCallback onTap, {
          bool danger = false,
        }) {
          final color = danger ? Brand.expense : Brand.ink;
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              label,
              style: Brand.text(weight: FontWeight.w600, color: color),
            ),
            onTap: () {
              Navigator.pop(sheetCtx);
              onTap();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombre,
                        style: Brand.text(size: 18, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.estaPagado
                            ? '${p.tipo == 'DEUDA' ? 'Pagado' : 'Cobrado'} · '
                                  '${_money.format(p.montoTotal)}'
                            : '${_money.format(p.capitalPendiente ?? p.saldoPendiente)} '
                                  'pendiente',
                        style: Brand.text(size: 12, color: Brand.muted),
                      ),
                    ],
                  ),
                ),
                if (p.enCuotas)
                  option(
                    Icons.table_rows_outlined,
                    'Ver cuotas',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PrestamoCuotasScreen(prestamo: p),
                      ),
                    ),
                  ),
                option(Icons.edit_outlined, 'Editar', () => _openForm(p)),
                if (!p.estaPagado)
                  option(
                    p.activa
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    p.activa ? 'Pausar' : 'Reanudar',
                    () => _run(
                      () => ref
                          .read(prestamosNotifierProvider.notifier)
                          .toggle(p.id, !p.activa),
                    ),
                  ),
                option(
                  Icons.delete_outline_rounded,
                  'Eliminar',
                  () => _confirmDelete(p),
                  danger: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _confirmDelete(Prestamo p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Eliminar "${p.nombre}"?',
          style: Brand.text(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          'Se borra el préstamo y su historial de pagos. Esta acción no se '
          'puede deshacer.',
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
    if (ok == true) {
      await _run(
        () => ref.read(prestamosNotifierProvider.notifier).delete(p.id),
      );
    }
  }
}

// ─── Componentes ──────────────────────────────────────────────────────────────
class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged, this.counts});

  final _Tab value;
  final ValueChanged<_Tab> onChanged;
  final Map<_Tab, int>? counts;

  @override
  Widget build(BuildContext context) {
    Widget seg(_Tab v, String label) {
      final on = v == value;
      final count = counts?[v];
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? Brand.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(
                        size: 14,
                        weight: on ? FontWeight.w700 : FontWeight.w600,
                        color: on ? Brand.ink : Brand.muted,
                      ),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: ValueKey('count-${v.name}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: on ? Brand.accentSoft : Brand.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: Brand.text(
                          size: 11,
                          weight: FontWeight.w800,
                          color: on ? Brand.accent : Brand.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Brand.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          seg(_Tab.debo, 'Debo'),
          const SizedBox(width: 4),
          seg(_Tab.meDeben, 'Me deben'),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.p,
    required this.color,
    required this.debo,
    required this.onTap,
    required this.onPay,
    required this.onOptions,
  });

  final Prestamo p;
  final Color color;
  final bool debo;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final cuotas = p.enCuotas;
    final activo = p.activa && !p.estaPagado;
    final vence = _venceDe(p);
    final estado = _estadoDeVencimiento(vence);
    final vencido = activo && vence != null && _diasHasta(vence) < 0;
    final pagado = (p.montoTotal - p.saldoPendiente).clamp(0, p.montoTotal);
    // En cuotas el avance es por cuotas pagadas (incluye las de antes)
    final ratio = cuotas
        ? (p.cuotasPagadas / p.numeroCuotas!).clamp(0.0, 1.0)
        : p.montoTotal <= 0
        ? 0.0
        : (pagado / p.montoTotal).clamp(0.0, 1.0);

    final tasaTxt = (p.tasaInteres ?? 0) > 0
        ? '${NumberFormat('#,##0.##', 'es_CO').format(p.tasaInteres)}%'
              '${cuotas ? (p.tipoTasa == 'MV' ? ' M.V.' : ' E.A.') : ''}'
        : null;
    final detalle = cuotas
        ? 'Cuota ${p.proximaCuota ?? p.numeroCuotas} de ${p.numeroCuotas}'
              '${tasaTxt == null ? '' : ' · $tasaTxt'}'
        : tasaTxt == null
        ? 'Sin intereses'
        : '$tasaTxt de interés';
    final meta = !p.activa ? 'En pausa · $detalle' : detalle;

    final monto = p.capitalPendiente ?? p.saldoPendiente;
    final etiquetaMonto = cuotas && p.capitalPendiente != null
        ? 'capital vigente'
        : (debo ? 'saldo pendiente' : 'por cobrar');
    final cuotaTexto = cuotas
        ? (p.cuotaTotal ?? p.saldoPendiente)
        : p.saldoPendiente;
    final caption = cuotas
        ? '${p.cuotasPagadas} de ${p.numeroCuotas} cuotas '
              '${debo ? 'pagadas' : 'cobradas'}'
        : '${debo ? 'Pagado' : 'Cobrado'} ${_money.format(pagado)} '
              'de ${_money.format(p.montoTotal)}';

    final initial = p.nombre.trim().isEmpty
        ? '?'
        : p.nombre.trim().characters.first.toUpperCase();

    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: vencido ? Brand.expense.withValues(alpha: 0.45) : Brand.border,
          width: vencido ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: vencido ? Brand.expenseSoft : Brand.bg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: vencido ? Brand.expenseSoft : Brand.border,
                      ),
                    ),
                    child: Text(
                      initial,
                      style: Brand.text(
                        weight: FontWeight.w800,
                        color: vencido ? Brand.expense : Brand.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.text(
                            size: 15,
                            weight: FontWeight.w700,
                            color: p.activa ? Brand.ink : Brand.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.text(size: 12, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onOptions,
                    tooltip: 'Opciones',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: Brand.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _money.format(monto),
                            style: Brand.text(
                              size: 22,
                              weight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Text(
                          etiquetaMonto,
                          style: Brand.text(size: 11, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w800,
                      color: vencido ? Brand.expense : Brand.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.toDouble(),
                  minHeight: 7,
                  color: vencido ? Brand.expense : color,
                  backgroundColor: Brand.track,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Brand.text(size: 11, color: Brand.muted),
              ),
              if (activo) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: vencido ? Brand.expenseSoft : Brand.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cuotas
                                  ? 'Próxima cuota'
                                  : debo
                                  ? 'Te falta pagar'
                                  : 'Te falta cobrar'}'
                              ' · ${estado.texto}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Brand.text(
                                size: 11,
                                color: estado.urgente
                                    ? Brand.expense
                                    : Brand.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _money.format(cuotaTexto),
                                style: Brand.text(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: estado.urgente
                                      ? Brand.expense
                                      : Brand.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onPay,
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.accent,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          cuotas
                              ? (debo ? 'Pagar cuota' : 'Cobrar cuota')
                              : (debo ? 'Pagar' : 'Cobrar'),
                          maxLines: 1,
                          style: Brand.text(
                            size: 12,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila compacta para préstamos ya pagados o cobrados.
class _PaidCard extends StatelessWidget {
  const _PaidCard({required this.p, required this.debo, required this.onTap});

  final Prestamo p;
  final bool debo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat(
      "d 'de' MMM y",
      'es_ES',
    ).format(p.fechaActualizacion);
    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Brand.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Brand.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(size: 14, weight: FontWeight.w700),
                    ),
                    Text(
                      '${debo ? 'Pagado' : 'Cobrado'} · $fecha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(size: 11, color: Brand.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money.format(p.montoTotal),
                style: Brand.text(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Brand.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta oscura con el total, el conteo y las alertas de vencimiento.
class _HeroResumen extends StatelessWidget {
  const _HeroResumen({
    required this.debo,
    required this.pendiente,
    required this.intereses,
    required this.activos,
    required this.vencidos,
    required this.proximos,
  });

  final bool debo;
  final double pendiente;
  final double? intereses;
  final int activos;
  final int vencidos;
  final int proximos;

  @override
  Widget build(BuildContext context) {
    final titulo = intereses != null
        ? (debo ? 'Capital vigente total' : 'Capital por cobrar')
        : (debo ? 'Saldo pendiente total' : 'Por cobrar');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Brand.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money.format(pendiente),
              style: Brand.title(size: 30, color: Colors.white),
            ),
          ),
          if (intereses != null && intereses! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Intereses por pagar ${_money.format(intereses)}',
              style: Brand.text(size: 12, color: const Color(0xFFB9C6C0)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _HeroChip(
                icon: Icons.folder_open_rounded,
                text:
                    '$activos ${debo ? (activos == 1 ? 'activo' : 'activos') : 'por cobrar'}',
              ),
              if (vencidos > 0)
                _HeroChip(
                  icon: Icons.error_outline_rounded,
                  text: '$vencidos ${vencidos == 1 ? 'vencido' : 'vencidos'}',
                  color: Brand.peach,
                ),
              if (proximos > 0)
                _HeroChip(
                  icon: Icons.schedule_rounded,
                  text: '$proximos esta semana',
                  color: Brand.mint,
                ),
              if (vencidos == 0 && proximos == 0)
                const _HeroChip(
                  icon: Icons.check_circle_outline_rounded,
                  text: 'Todo al día',
                  color: Brand.mint,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.text, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFB9C6C0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            maxLines: 1,
            style: Brand.text(size: 11, weight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 40, 12, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 44, color: Brand.inputBorder),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Brand.text(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Brand.text(size: 13, color: Brand.muted, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
