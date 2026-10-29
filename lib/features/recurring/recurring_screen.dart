import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/theme/brand.dart';
import '../accounts/accounts_provider.dart';
import '../transactions/transactions_provider.dart';
import 'create_recurring_screen.dart';
import 'recurring_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Cuánto representa el pago en un mes, para sumar frecuencias distintas.
double _monthly(PagoRecurrente p) => switch (p.frecuencia) {
  'DIARIO' => p.monto * 30,
  'SEMANAL' => p.monto * 52 / 12,
  'BIMESTRAL' => p.monto / 2,
  'TRIMESTRAL' => p.monto / 3,
  'SEMESTRAL' => p.monto / 6,
  'ANUAL' => p.monto / 12,
  _ => p.monto,
};

String _title(PagoRecurrente p) => p.descripcion.isEmpty
    ? (p.categoriaNombre ?? 'Pago recurrente')
    : p.descripcion;

// ─── Pagos recurrentes ────────────────────────────────────────────────────────
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recurringProvider);

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Brand.accent,
          onRefresh: () => ref.refresh(recurringProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const BrandBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Pagos recurrentes', style: Brand.title(size: 22)),
                  ),
                  Material(
                    color: Brand.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateRecurringScreen()),
                      ),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          semanticLabel: 'Nuevo pago recurrente',
                        ),
                      ),
                    ),
                  ),
                ],
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
                error: (e, _) => [
                  _Message(
                    icon: Icons.wifi_off_rounded,
                    title: 'No se pudieron cargar tus pagos recurrentes',
                    body: e.toString().replaceFirst('Exception: ', ''),
                  ),
                ],
                data: (items) => _content(items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(List<PagoRecurrente> items) {
    if (items.isEmpty) {
      return const [
        _Message(
          icon: Icons.autorenew_rounded,
          title: 'No tienes pagos recurrentes',
          body: 'Crea uno con el botón + (arriendo, Netflix, salario…) o marca '
              '"Se repite" al registrar un movimiento. Se registra solo en cada fecha.',
        ),
      ];
    }

    final far = DateTime(9999);
    final activos = items.where((p) => p.activo).toList()
      ..sort((a, b) => (a.proximaFecha() ?? far).compareTo(b.proximaFecha() ?? far));
    final pausados = items.where((p) => !p.activo).toList();
    final mensual = activos.fold<double>(0, (s, p) => s + _monthly(p));

    final now = DateTime.now();
    final semana = DateTime(now.year, now.month, now.day + 7);
    final estaSemana = activos.where((p) {
      final f = p.proximaFecha();
      return f != null && !f.isAfter(semana);
    }).length;

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
              'Compromiso mensual estimado',
              style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _money.format(mensual),
                style: Brand.title(size: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${activos.length} ${activos.length == 1 ? 'pago activo' : 'pagos activos'}'
              '${estaSemana > 0 ? ' · $estaSemana esta semana' : ''}',
              style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      for (final p in activos)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecurringCard(p: p),
        ),
      if (pausados.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          child: Text(
            'PAUSADOS · ${pausados.length}',
            style: Brand.text(
              size: 12,
              weight: FontWeight.w700,
              color: Brand.muted,
              letterSpacing: 0.7,
            ),
          ),
        ),
        for (final p in pausados)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecurringCard(p: p),
          ),
      ],
      const SizedBox(height: 8),
      Text(
        'Se registran solos en la fecha de cobro. Si activas las '
        'notificaciones, te avisamos ese día a las 9:00.',
        style: Brand.text(size: 12, color: Brand.muted, height: 1.45),
      ),
    ];
  }
}

// ─── Tarjeta de un pago ───────────────────────────────────────────────────────
class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({required this.p});

  final PagoRecurrente p;

  String _when() {
    if (!p.activo) return 'En pausa';
    final f = p.proximaFecha();
    if (f == null) return 'Finalizado';
    final now = DateTime.now();
    final days = f.difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (days) {
      0 => 'Hoy',
      1 => 'Mañana',
      < 7 => DateFormat('EEEE', 'es_ES').format(f),
      _ => DateFormat("d 'de' MMM", 'es_ES').format(f),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = p.activo;
    final when = _when();
    final isToday = when == 'Hoy';
    final meta = [
      p.frecuenciaLabel,
      ?p.categoriaNombre,
      ?p.cuentaNombre,
    ].join(' · ');

    return Material(
      color: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Brand.border),
      ),
      child: InkWell(
        onTap: () => _showActions(context, ref),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active ? Brand.blueSoft : Brand.track,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.autorenew_rounded,
                  size: 22,
                  color: active ? Brand.blue : Brand.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(
                        size: 14,
                        weight: FontWeight.w700,
                        color: active ? Brand.ink : Brand.muted,
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money.format(p.monto),
                    style: Brand.text(size: 14, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when[0].toUpperCase() + when.substring(1),
                    style: Brand.text(
                      size: 12,
                      weight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? Brand.accent : Brand.muted,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: active,
                activeTrackColor: Brand.accent,
                onChanged: (v) => _run(
                  context,
                  ref,
                  () => ref.read(recurringServiceProvider).toggle(p.id, v),
                  v ? 'Pago reactivado' : 'Pago pausado',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String ok,
  ) async {
    try {
      await action();
      ref.invalidate(recurringProvider);
      if (context.mounted) showBrandSnack(context, ok, error: false);
    } catch (e) {
      if (context.mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showActions(BuildContext context, WidgetRef ref) {
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
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 2),
                  child: Text(_title(p),
                      style: Brand.text(size: 18, weight: FontWeight.w800)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '${_money.format(p.monto)} · ${p.frecuenciaLabel}',
                    style: Brand.text(size: 13, color: Brand.muted),
                  ),
                ),
                option(
                  Icons.bolt_rounded,
                  'Registrar ahora',
                  () => _run(context, ref, () async {
                    await ref.read(recurringServiceProvider).executeNow(p.id);
                    await ref.read(transactionsNotifierProvider.notifier).refresh();
                    await ref.read(accountsNotifierProvider.notifier).refresh();
                  }, 'Pago registrado como movimiento'),
                ),
                option(Icons.edit_outlined, 'Editar monto o frecuencia',
                    () => _showEdit(context, ref)),
                option(Icons.delete_outline_rounded, 'Eliminar',
                    () => _confirmDelete(context, ref), danger: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Eliminar este pago recurrente?',
            style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'Dejará de registrarse automáticamente. Los movimientos que ya se '
          'crearon no se borran.',
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
    if (ok == true && context.mounted) {
      await _run(
        context,
        ref,
        () => ref.read(recurringServiceProvider).delete(p.id),
        'Pago recurrente eliminado',
      );
    }
  }

  Future<void> _showEdit(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EditSheet(p: p),
    );
    if (result != null && context.mounted) {
      await _run(
        context,
        ref,
        () => ref.read(recurringServiceProvider).update(p.id, result),
        'Pago recurrente actualizado',
      );
    }
  }
}

// ─── Editar ───────────────────────────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.p});

  final PagoRecurrente p;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _descCtrl = TextEditingController(text: widget.p.descripcion);
  late final _montoCtrl =
      TextEditingController(text: widget.p.monto.toStringAsFixed(0));
  late String _frecuencia = widget.p.frecuencia;

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      showBrandSnack(context, 'Escribe un monto válido');
      return;
    }
    final desc = _descCtrl.text.trim();
    Navigator.pop(context, {
      'monto': monto,
      if (desc.isNotEmpty) 'descripcion': desc,
      'frecuencia': _frecuencia,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
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
              const SizedBox(height: 20),
              Text('Editar pago recurrente',
                  style: Brand.text(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 18),
              BrandField(label: 'Descripción', controller: _descCtrl),
              const SizedBox(height: 14),
              Text('Monto', style: Brand.text(size: 13, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Brand.text(size: 18, weight: FontWeight.w800),
                cursorColor: Brand.accent,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: Brand.text(
                    size: 18,
                    weight: FontWeight.w800,
                    color: Brand.muted,
                  ),
                  filled: true,
                  fillColor: Brand.surface,
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
                    borderSide: const BorderSide(color: Brand.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Frecuencia',
                  style: Brand.text(size: 13, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in PagoRecurrente.frecuencias.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _frecuencia == e.key,
                      onSelected: (_) => setState(() => _frecuencia = e.key),
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
              const SizedBox(height: 24),
              BrandButton(label: 'Guardar cambios', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 48, 12, 32),
      child: Column(
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
        ],
      ),
    );
  }
}
