import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/prestamo_models.dart';
import '../../core/theme/brand.dart';
import 'pago_prestamo_dialog.dart';
import 'prestamos_provider.dart';

final _money = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 0,
  locale: 'es_CO',
);
final _pct = NumberFormat('#,##0.##', 'es_CO');

/// Crédito en cuotas: resumen (tasa, cuota, total, intereses, fin), la
/// próxima cuota con su botón y la tabla de amortización.
class PrestamoCuotasScreen extends ConsumerWidget {
  const PrestamoCuotasScreen({super.key, required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La versión más reciente (tras pagar una cuota)
    final p =
        ref
            .watch(prestamosNotifierProvider)
            .valueOrNull
            ?.where((x) => x.id == prestamo.id)
            .firstOrNull ??
        prestamo;
    final debo = p.tipo == 'DEUDA';
    final fecha = DateFormat("d MMM y", 'es_ES');
    final tabla = p.tabla();
    final proxima = p.proximaCuota;
    final vence = p.proximoVencimiento;
    final hoy = DateUtils.dateOnly(DateTime.now());
    final alerta = vence != null && vence.difference(hoy).inDays <= 3;
    final tasaMensual = p.tasaMensual;

    final datos = <(String, String)>[
      ('Cuota base (capital + interés)', _money.format(p.valorCuota)),
      if (p.cargoAdicionalTotal != null && p.cargoAdicionalTotal! > 0) ...[
        (
          p.cargoAdicionalNombre ?? 'Cargo adicional',
          '${_money.format(p.cargoAdicionalTotal)} total · ${_money.format(p.cargoAdicionalPorCuota)} por cuota',
        ),
        ('Pago mensual total', _money.format(p.cuotaTotal)),
      ],
      if ((p.tasaInteres ?? 0) > 0)
        (
          'Tasa',
          '${_pct.format(p.tasaInteres)}% ${p.tipoTasa == 'MV' ? 'M.V.' : 'E.A.'}'
              '${tasaMensual != null && p.tipoTasa != 'MV' ? ' · ${_pct.format(tasaMensual * 100)}% mensual' : ''}',
        ),
      // El capital vigente va en la tarjeta de arriba; aquí, lo que falta en
      // cuotas (capital + intereses)
      if (p.totalAPagar != null && p.capitalPendiente != null)
        ('Te falta pagar en cuotas', _money.format(p.totalAPagar)),
      if ((p.totalIntereses ?? 0) > 0)
        ('Intereses futuros estimados', _money.format(p.totalIntereses)),
      if (p.fechaUltimaCuota != null)
        (
          'Termina',
          DateFormat("MMMM 'de' y", 'es_ES').format(p.fechaUltimaCuota!),
        ),
    ];

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const BrandBackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.title(size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Saldo y avance ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: Brand.ink,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Con el capital conocido se muestra el capital vigente; sin
                  // él, lo que falta pagar en cuotas (con intereses)
                  Text(
                    p.capitalPendiente != null
                        ? (debo ? 'Capital vigente' : 'Capital por cobrar')
                        : (debo ? 'Te falta pagar' : 'Te falta cobrar'),
                    style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money.format(p.capitalPendiente ?? p.saldoPendiente),
                    style: Brand.title(size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.cuotasPagadas / p.numeroCuotas!,
                      minHeight: 8,
                      color: Brand.mint,
                      backgroundColor: const Color(0xFF22352E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${p.cuotasPagadas} de ${p.numeroCuotas} cuotas '
                    '${debo ? 'pagadas' : 'cobradas'}',
                    style: Brand.text(size: 13, color: const Color(0xFFB9C6C0)),
                  ),
                ],
              ),
            ),

            // ── Próxima cuota ──────────────────────────────────────────
            if (proxima != null && p.activa) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(
                  color: Brand.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: alerta ? Brand.expense : Brand.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuota $proxima de ${p.numeroCuotas}',
                            style: Brand.text(size: 12, color: Brand.muted),
                          ),
                          Text(
                            _money.format(p.cuotaTotal),
                            style: Brand.text(
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                          ),
                          if (vence != null)
                            Text(
                              '${vence.isBefore(hoy) ? 'Venció' : 'Vence'} el ${fecha.format(vence)}',
                              style: Brand.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: alerta ? Brand.expense : Brand.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => abrirPagoPrestamo(context, p),
                      style: FilledButton.styleFrom(
                        backgroundColor: Brand.accent,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        debo ? 'Pagar cuota' : 'Cobrar cuota',
                        style: Brand.text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Datos del crédito ──────────────────────────────────────
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Brand.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Brand.border),
              ),
              child: Column(
                children: [
                  for (final (i, (k, v)) in datos.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: Brand.border),
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Text(
                            k,
                            style: Brand.text(size: 14, color: Brand.muted),
                          ),
                          const Spacer(),
                          Text(
                            v,
                            style: Brand.text(
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Tabla de cuotas ────────────────────────────────────────
            const SizedBox(height: 22),
            Text('Tabla de cuotas', style: Brand.text(weight: FontWeight.w700)),
            if (tabla.length > (p.cuotasPrevias ?? 0) &&
                tabla[(p.cuotasPrevias ?? 0)].interes == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Pon el monto prestado y la tasa para ver cuánto es interés y '
                  'cuánto abono a capital.',
                  style: Brand.text(size: 12, color: Brand.muted),
                ),
              ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Brand.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Brand.border),
              ),
              child: Column(
                children: [
                  for (final (i, c) in tabla.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: Brand.border),
                    _FilaCuota(
                      c: c,
                      proxima: c.numero == proxima,
                      fecha: fecha,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaCuota extends StatelessWidget {
  const _FilaCuota({
    required this.c,
    required this.proxima,
    required this.fecha,
  });

  final CuotaCredito c;
  final bool proxima;
  final DateFormat fecha;

  @override
  Widget build(BuildContext context) {
    final detalle = c.interes == null
        ? null
        : 'Interés ${_money.format(c.interes)} · Capital ${_money.format(c.capital)}'
              '${c.cargoAdicional > 0 ? ' · Cargo ${_money.format(c.cargoAdicional)}' : ''}'
              ' · Saldo ${_money.format(c.saldoCapital)}';
    return Container(
      color: proxima ? Brand.accentSoft : null,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: c.pagada
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Brand.accent,
                  )
                : Text(
                    '${c.numero}',
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: proxima ? Brand.accent : Brand.muted,
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.fecha == null
                      ? 'Cuota ${c.numero}'
                      : fecha.format(c.fecha!),
                  style: Brand.text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: c.pagada ? Brand.muted : Brand.ink,
                  ),
                ),
                if (detalle != null)
                  Text(
                    detalle,
                    style: Brand.text(size: 11, color: Brand.muted),
                  ),
              ],
            ),
          ),
          Text(
            _money.format(c.valor),
            style: Brand.text(
              size: 14,
              weight: FontWeight.w700,
              color: c.pagada ? Brand.muted : Brand.ink,
            ),
          ),
        ],
      ),
    );
  }
}
