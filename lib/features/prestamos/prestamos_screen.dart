import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/theme/brand.dart';
import 'create_edit_prestamo_screen.dart';
import 'pago_prestamo_dialog.dart';
import 'prestamos_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

// Colores de las barras, en el orden en que se asignan
const _palette = [
  Brand.accent,
  Brand.blue,
  Color(0xFF6B3FA0),
  Brand.expense,
];

// DEUDA = yo debo · PRESTAMO = me deben (columna prestamos.tipo)
enum _Tab { debo, meDeben }

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

  void _pay(Prestamo p) => showDialog(
    context: context,
    builder: (_) => PagoPrestamoDialog(prestamo: p),
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prestamosNotifierProvider);

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () => ref.read(prestamosNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Préstamos', style: Brand.title(size: 22))),
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
                    body: 'Revisa tu conexión y desliza hacia abajo para '
                        'reintentar.',
                  ),
                ],
                data: (all) => _content(all.where((p) => p.tipo == _tipo).toList()),
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
      ..sort((a, b) => b.saldoPendiente.compareTo(a.saldoPendiente));
    final pausados = items.where((p) => !p.activa && !p.estaPagado).toList();
    final pagados = items.where((p) => p.estaPagado).toList();
    final pendiente = activos.fold<double>(0, (s, p) => s + p.saldoPendiente);

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

    Color colorOf(Prestamo p) => _palette[items.indexOf(p) % _palette.length];

    Widget card(Prestamo p) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _LoanCard(
        p: p,
        color: colorOf(p),
        debo: debo,
        onPay: () => _pay(p),
        onOptions: () => _showOptions(p),
      ),
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

    final n = activos.length;
    return [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: Brand.ink,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              debo ? 'Saldo pendiente total' : 'Por cobrar',
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
            const SizedBox(height: 6),
            Text(
              debo
                  ? '$n ${n == 1 ? 'préstamo activo' : 'préstamos activos'}'
                  : '$n ${n == 1 ? 'préstamo por cobrar' : 'préstamos por cobrar'}',
              style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      ...activos.map(card),
      if (pausados.isNotEmpty) ...[
        section('Pausados', pausados.length),
        ...pausados.map(card),
      ],
      if (pagados.isNotEmpty) ...[
        section(debo ? 'Pagados' : 'Cobrados', pagados.length),
        ...pagados.map(card),
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
        Widget option(IconData icon, String label, VoidCallback onTap,
            {bool danger = false}) {
          final color = danger ? Brand.expense : Brand.ink;
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(label,
                style: Brand.text(weight: FontWeight.w600, color: color)),
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
                  child: Text(p.nombre,
                      style: Brand.text(size: 18, weight: FontWeight.w800)),
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
                option(Icons.delete_outline_rounded, 'Eliminar',
                    () => _confirmDelete(p), danger: true),
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
        title: Text('¿Eliminar "${p.nombre}"?',
            style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'Se borra el préstamo y su historial de pagos. Esta acción no se '
          'puede deshacer.',
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: Brand.text(weight: FontWeight.w700, color: Brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.expense),
            child: Text('Eliminar',
                style: Brand.text(weight: FontWeight.w700, color: Colors.white)),
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
  const _Segmented({required this.value, required this.onChanged});

  final _Tab value;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(_Tab v, String label) {
      final on = v == value;
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
              child: Text(
                label,
                style: Brand.text(
                  size: 14,
                  weight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? Brand.ink : Brand.muted,
                ),
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
    required this.onPay,
    required this.onOptions,
  });

  final Prestamo p;
  final Color color;
  final bool debo;
  final VoidCallback onPay;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final pagado = (p.montoTotal - p.saldoPendiente).clamp(0, p.montoTotal);
    final ratio = p.montoTotal <= 0 ? 0.0 : pagado / p.montoTotal;
    final activo = p.activa && !p.estaPagado;
    final barColor = activo ? color : Brand.muted;

    final tasa = (p.tasaInteres ?? 0) > 0
        ? '${NumberFormat('#,##0.##', 'es_CO').format(p.tasaInteres)}% de interés'
        : 'Sin intereses';
    final vence = p.fechaFin;
    final vencido = activo && vence != null && vence.isBefore(DateTime.now());
    final fechaLabel = vence == null
        ? null
        : '${vencido ? 'Venció' : 'Vence'} el ${DateFormat("d 'de' MMM yyyy", 'es_ES').format(vence)}';

    final initial = p.nombre.trim().isEmpty
        ? '?'
        : p.nombre.trim().characters.first.toUpperCase();

    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: onOptions,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Brand.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Brand.border),
                    ),
                    child: p.estaPagado
                        ? const Icon(Icons.check_rounded, color: Brand.accent)
                        : Text(
                            initial,
                            style: Brand.text(weight: FontWeight.w800),
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
                            weight: FontWeight.w700,
                            color: activo ? Brand.ink : Brand.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.estaPagado
                              ? (debo ? 'Pagado' : 'Cobrado')
                              : !p.activa
                              ? 'En pausa · $tasa'
                              : tasa,
                          style: Brand.text(size: 12, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money.format(p.saldoPendiente),
                    style: Brand.text(weight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.toDouble(),
                  minHeight: 8,
                  color: barColor,
                  backgroundColor: Brand.track,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${debo ? 'Pagado' : 'Cobrado'} ${_money.format(pagado)} de ${_money.format(p.montoTotal)}',
                      style: Brand.text(size: 12, color: Brand.muted),
                    ),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: Brand.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Brand.muted,
                    ),
                  ),
                ],
              ),
              if (activo) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: Brand.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debo ? 'Te falta pagar' : 'Te falta cobrar',
                              style: Brand.text(size: 12, color: Brand.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fechaLabel ?? _money.format(p.saldoPendiente),
                              style: Brand.text(
                                size: 14,
                                weight: FontWeight.w700,
                                color: vencido ? Brand.expense : Brand.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: onPay,
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.accent,
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          debo ? 'Pagar' : 'Registrar cobro',
                          style: Brand.text(
                            size: 13,
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
