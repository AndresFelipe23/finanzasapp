import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../core/models/transaccion_models.dart';

enum ExportFormat { csv, pdf }

/// Genera un archivo con los movimientos y abre el diálogo de compartir del
/// sistema (guardar en Drive, enviar por WhatsApp, correo, etc.).
class ExportService {
  static final _fecha = DateFormat('yyyy-MM-dd');
  static final _fechaHora = DateFormat('yyyy-MM-dd HH:mm');
  static final _money = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
    locale: 'es_CO',
  );

  static Future<void> exportar({
    required List<Transaccion> items,
    required ExportFormat formato,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final ordenados = [...items]
      ..sort((a, b) => a.fechaTransaccion.compareTo(b.fechaTransaccion));
    final nombre =
        'financially_${_fecha.format(desde)}_a_${_fecha.format(hasta)}';
    final dir = await getTemporaryDirectory();

    final File file;
    if (formato == ExportFormat.csv) {
      file = File('${dir.path}/$nombre.csv');
      // BOM para que Excel reconozca UTF-8 (tildes y ñ)
      await file.writeAsString('﻿${_csv(ordenados)}', encoding: utf8);
    } else {
      file = File('${dir.path}/$nombre.pdf');
      await file.writeAsBytes(await _pdf(ordenados, desde, hasta));
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Movimientos Financially',
      ),
    );
  }

  static String _titulo(Transaccion t) => (t.titulo?.isNotEmpty == true)
      ? t.titulo!
      : (t.descripcion?.isNotEmpty == true ? t.descripcion! : '');

  // Separador ";" porque Excel en español usa la coma como decimal
  static String _csv(List<Transaccion> items) {
    String esc(String? v) {
      final s = v ?? '';
      return s.contains(RegExp(r'[;"\n\r]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final buf = StringBuffer(
      'Fecha;Tipo;Categoría;Cuenta;Descripción;Monto;Moneda\n',
    );
    for (final t in items) {
      final signo = t.tipoNombre == 'GASTO' ? '-' : '';
      buf.writeln(
        [
          _fechaHora.format(t.fechaTransaccion),
          t.tipoNombre,
          esc(t.categoriaNombre),
          esc(t.cuentaNombre),
          esc(_titulo(t)),
          '$signo${t.monto.toStringAsFixed(2).replaceAll('.', ',')}',
          t.moneda,
        ].join(';'),
      );
    }
    return buf.toString();
  }

  static Future<List<int>> _pdf(
    List<Transaccion> items,
    DateTime desde,
    DateTime hasta,
  ) async {
    double ingresos = 0, gastos = 0;
    for (final t in items) {
      if (t.tipoNombre == 'INGRESO') ingresos += t.monto;
      if (t.tipoNombre == 'GASTO') gastos += t.monto;
    }

    // Paleta del diseño: verde de la marca, naranja para gastos, tinta oscura
    const accent = PdfColor.fromInt(0xFF0B6E4F);
    const expense = PdfColor.fromInt(0xFFB4531A);
    const ink = PdfColor.fromInt(0xFF10201B);
    const muted = PdfColor.fromInt(0xFF5A6762);
    const rowBg = PdfColor.fromInt(0xFFF4F5F1);
    final rango = '${DateFormat('d MMM yyyy', 'es_ES').format(desde)} – '
        '${DateFormat('d MMM yyyy', 'es_ES').format(hasta)}';

    final doc = pw.Document(title: 'Movimientos Financially');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Financially',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              ),
            ),
            pw.Text('Reporte de movimientos · $rango'),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: muted),
          ),
        ),
        build: (_) => [
          pw.Row(
            children: [
              _kpi('Ingresos', _money.format(ingresos), accent),
              pw.SizedBox(width: 10),
              _kpi('Gastos', _money.format(gastos), expense),
              pw.SizedBox(width: 10),
              _kpi('Balance', _money.format(ingresos - gastos), ink),
            ],
          ),
          pw.SizedBox(height: 16),
          if (items.isEmpty)
            pw.Text('No hay movimientos en este periodo.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Fecha', 'Tipo', 'Categoría', 'Descripción', 'Monto'],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: ink),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {4: pw.Alignment.centerRight},
              oddRowDecoration: const pw.BoxDecoration(
                color: rowBg,
              ),
              data: [
                for (final t in items)
                  [
                    _fecha.format(t.fechaTransaccion),
                    switch (t.tipoNombre) {
                      'INGRESO' => 'Ingreso',
                      'GASTO' => 'Gasto',
                      _ => t.tipoNombre,
                    },
                    t.categoriaNombre ?? '',
                    _titulo(t),
                    '${t.tipoNombre == 'GASTO' ? '-' : '+'}'
                        '${_money.format(t.monto)}',
                  ],
              ],
            ),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _kpi(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE3E6E0)),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF5A6762)),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
