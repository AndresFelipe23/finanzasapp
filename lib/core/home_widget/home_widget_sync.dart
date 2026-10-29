import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../currency/exchange_rates.dart';
import '../models/transaccion_models.dart';

/// Datos del widget de la pantalla de inicio (Android). El widget nativo
/// (`FinanciallyWidgetProvider.kt`) solo pinta lo que se guarda aquí.
class HomeWidgetSync {
  HomeWidgetSync._();

  static const _provider = 'com.afesdev.financially.FinanciallyWidgetProvider';
  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  static final _money = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
    locale: 'es_CO',
  );

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Gastos e ingresos del mes en curso a partir de los movimientos.
  static Future<void> update(Iterable<Transaccion> trans) async {
    if (!_supported) return;
    final now = DateTime.now();
    // Otras monedas convertidas con las últimas tasas guardadas (puede
    // correr en segundo plano, sin Riverpod ni red)
    final tasas = await ExchangeRates.enCache();
    double enBase(Transaccion t) => tasas?.aBase(t.monto, t.moneda) ?? t.monto;
    var gastos = 0.0;
    var ingresos = 0.0;
    for (final t in trans) {
      final f = t.fechaTransaccion;
      if (f.year != now.year || f.month != now.month) continue;
      if (t.tipoNombre == 'GASTO') gastos += enBase(t);
      if (t.tipoNombre == 'INGRESO') ingresos += enBase(t);
    }
    await _save({
      'mes': _meses[now.month - 1],
      'gastado': _money.format(gastos),
      'ingresos': _money.format(ingresos),
    });
  }

  /// Al cerrar sesión el widget deja de mostrar montos.
  static Future<void> clear() async {
    if (!_supported) return;
    await _save({'mes': 'Inicia sesión', 'gastado': '—', 'ingresos': '—'});
  }

  static Future<void> _save(Map<String, String> data) async {
    try {
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } catch (e) {
      debugPrint('Widget no actualizado: $e');
    }
  }
}
