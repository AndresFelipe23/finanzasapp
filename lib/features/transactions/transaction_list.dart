import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/transaccion_models.dart';
import '../../core/theme/brand.dart';
import 'transaction_detail_sheet.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);

/// Agrupa por día, del más reciente al más antiguo.
List<MapEntry<DateTime, List<Transaccion>>> groupTransactionsByDay(
  List<Transaccion> list,
) {
  final sorted = [...list]
    ..sort((a, b) => b.fechaTransaccion.compareTo(a.fechaTransaccion));
  final map = <DateTime, List<Transaccion>>{};
  for (final t in sorted) {
    final f = t.fechaTransaccion;
    (map[DateTime(f.year, f.month, f.day)] ??= []).add(t);
  }
  return map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
}

// ─── Lista agrupada por día ───────────────────────────────────────────────────
class TransactionDayGroup extends StatelessWidget {
  const TransactionDayGroup({super.key, required this.day, required this.items});

  final DateTime day;
  final List<Transaccion> items;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final fecha = DateFormat('d MMM', 'es_ES').format(day);
    final prefix = switch (diff) {
      0 => 'Hoy',
      1 => 'Ayer',
      _ => DateFormat('EEE', 'es_ES').format(day).replaceAll('.', ''),
    };
    final year = day.year != now.year ? ' ${day.year}' : '';
    return '$prefix · $fecha$year'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Neto del día: transferencias no suman ni restan
    final net = items.fold<double>(0, (s, t) {
      if (t.tipoNombre == 'INGRESO') return s + t.monto;
      if (t.tipoNombre == 'GASTO') return s - t.monto;
      return s;
    });
    final netLabel =
        '${net > 0 ? '+' : net < 0 ? '−' : ''}${_money.format(net.abs())}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label(),
                  style: Brand.text(
                    size: 12,
                    weight: FontWeight.w700,
                    color: Brand.muted,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              Text(
                netLabel,
                style: Brand.text(
                  size: 12,
                  weight: FontWeight.w700,
                  color: Brand.muted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Brand.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Brand.border),
          ),
          child: Column(
            children: [
              for (final (i, t) in items.indexed) ...[
                if (i > 0) const Divider(height: 1, color: Brand.track),
                _Row(t: t),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.t});

  final Transaccion t;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, sign, label) = movementStyle(t.tipoNombre);
    final title = (t.titulo?.isNotEmpty == true)
        ? t.titulo!
        : (t.categoriaNombre ?? label);
    final meta = [
      if (t.categoriaNombre != null && t.categoriaNombre != title)
        t.categoriaNombre!,
      ?t.cuentaNombre,
    ].join(' · ');

    return InkWell(
      onTap: () => showTransactionDetail(context, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: t.tipoNombre == 'TRANSFERENCIA'
                  ? Icon(Icons.swap_horiz_rounded, size: 20, color: fg)
                  : Text(
                      title.characters.first.toUpperCase(),
                      style: Brand.text(weight: FontWeight.w800, color: fg),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.text(size: 14, weight: FontWeight.w600),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.text(size: 12, color: Brand.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${_money.format(t.monto)}',
              style: Brand.text(size: 14, weight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

