import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/brand.dart';
import '../transactions/transactions_provider.dart';
import 'export_service.dart';

void showExportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Brand.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _ExportSheet(),
  );
}

enum _Periodo { esteMes, mesPasado, tresMeses, anio }

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  _Periodo _periodo = _Periodo.esteMes;
  ExportFormat _formato = ExportFormat.pdf;
  bool _cargando = false;

  static const _labels = {
    _Periodo.esteMes: 'Este mes',
    _Periodo.mesPasado: 'Mes pasado',
    _Periodo.tresMeses: 'Últimos 3 meses',
    _Periodo.anio: 'Este año',
  };

  (DateTime, DateTime) _rango() {
    final now = DateTime.now();
    return switch (_periodo) {
      _Periodo.esteMes => (DateTime(now.year, now.month, 1), now),
      _Periodo.mesPasado => (
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0),
      ),
      _Periodo.tresMeses => (DateTime(now.year, now.month - 2, 1), now),
      _Periodo.anio => (DateTime(now.year, 1, 1), now),
    };
  }

  Future<void> _exportar() async {
    setState(() => _cargando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final (desde, hasta) = _rango();
      final finDia = DateTime(hasta.year, hasta.month, hasta.day, 23, 59, 59);
      final todas = await ref
          .read(transactionsServiceProvider)
          .getAllTransactions();
      final items = todas
          .where(
            (t) =>
                !t.fechaTransaccion.isBefore(desde) &&
                !t.fechaTransaccion.isAfter(finDia),
          )
          .toList();
      await ExportService.exportar(
        items: items,
        formato: _formato,
        desde: desde,
        hasta: hasta,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: Brand.ink,
        backgroundColor: Brand.surface,
        side: BorderSide(color: selected ? Brand.ink : Brand.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: Brand.text(
          size: 13,
          weight: FontWeight.w700,
          color: selected ? Colors.white : Brand.ink,
        ),
      );
    }

    Widget formato(ExportFormat f, IconData icon, String title, String body) {
      final on = _formato == f;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: Material(
            color: on ? Brand.accentSoft : Brand.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: on ? Brand.accent : Brand.border, width: on ? 2 : 1),
            ),
            child: InkWell(
              onTap: () => setState(() => _formato = f),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: on ? Brand.accent : Brand.ink),
                    const SizedBox(height: 10),
                    Text(title, style: Brand.text(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(body, style: Brand.text(size: 12, color: Brand.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Text titulo(String s) => Text(
      s.toUpperCase(),
      style: Brand.text(
        size: 11,
        weight: FontWeight.w700,
        color: Brand.muted,
        letterSpacing: 1.1,
      ),
    );

    return SafeArea(
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
            const SizedBox(height: 20),
            Text(
              'Exportar movimientos',
              style: Brand.text(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Genera un archivo y compártelo por WhatsApp, correo o Drive.',
              style: Brand.text(size: 13, color: Brand.muted),
            ),
            const SizedBox(height: 18),
            titulo('Periodo'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _Periodo.values)
                  chip(
                    _labels[p]!,
                    _periodo == p,
                    () => setState(() => _periodo = p),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            titulo('Formato'),
            const SizedBox(height: 8),
            Row(
              children: [
                formato(ExportFormat.pdf, Icons.picture_as_pdf_outlined,
                    'PDF', 'Reporte con totales'),
                const SizedBox(width: 10),
                formato(ExportFormat.csv, Icons.table_chart_outlined,
                    'CSV', 'Para Excel o Sheets'),
              ],
            ),
            const SizedBox(height: 24),
            BrandButton(
              label: 'Exportar y compartir',
              loading: _cargando,
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              onPressed: _exportar,
            ),
          ],
        ),
      ),
    );
  }
}
