import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/meta_models.dart';
import 'metas_service.dart';

/// Aporte automático a metas: el servidor aparta el porcentaje de cada
/// ingreso (sp_meta_aportes_automaticos_internal). Esto solo sirve para
/// contarle al usuario qué se apartó, comparando las metas antes y después
/// de registrar el ingreso.
class AporteAuto {
  AporteAuto._();

  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

  /// Metas con regla de aporte automático, antes de registrar el ingreso.
  /// Vacío si no hay ninguna o no se pudo consultar (nunca lanza).
  static Future<List<Meta>> reglas(ApiClient api) async {
    try {
      final metas = await MetasService(api).getAll();
      return metas.where((m) => m.tieneAporteAuto && m.activa && !m.estaCompletada).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Lo que se apartó de verdad de un ingreso de [ingreso]: por cada meta de
  /// [antes] a la que le tocaba, cuánto subió su monto. Solo vuelve a
  /// consultar si había alguna a la que le correspondía aportar.
  static Future<List<(Meta, double)>> aplicados(
    ApiClient api,
    List<Meta> antes,
    double ingreso,
  ) async {
    final posibles = antes.where((m) => m.aporteAutoDe(ingreso) > 0).toList();
    if (posibles.isEmpty) return const [];
    try {
      final despues = await MetasService(api).getAll();
      return [
        for (final a in posibles)
          for (final d in despues.where((d) => d.id == a.id))
            if (d.montoActual - a.montoActual > 0.009) (d, d.montoActual - a.montoActual),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// "Apartamos $200.000 para Fondo de emergencia" (o "…en 2 metas").
  static String? resumen(List<(Meta, double)> aplicados) {
    if (aplicados.isEmpty) return null;
    final total = aplicados.fold<double>(0, (s, a) => s + a.$2);
    return aplicados.length == 1
        ? 'Apartamos ${_money.format(total)} para ${aplicados.first.$1.nombre}'
        : 'Apartamos ${_money.format(total)} en ${aplicados.length} metas';
  }
}
