import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/models/transaccion_models.dart';

class CreatePagoRecurrenteRequest {
  final int categoriaId;
  final int? cuentaId;
  final int? metodoPagoId;
  final double monto;
  final String descripcion;
  final String
  frecuencia; // DIARIO, SEMANAL, MENSUAL, BIMESTRAL, TRIMESTRAL, SEMESTRAL, ANUAL
  final int? diaVencimiento; // 1..31
  final int? diaSemana; // 1..7 (1=Lunes)
  final String fechaInicio; // YYYY-MM-DD
  final String? fechaFin; // YYYY-MM-DD

  CreatePagoRecurrenteRequest({
    required this.categoriaId,
    this.cuentaId,
    this.metodoPagoId,
    required this.monto,
    required this.descripcion,
    required this.frecuencia,
    this.diaVencimiento,
    this.diaSemana,
    required this.fechaInicio,
    this.fechaFin,
  });

  Map<String, dynamic> toJson() => {
    'categoriaId': categoriaId,
    if (cuentaId != null) 'cuentaId': cuentaId,
    if (metodoPagoId != null) 'metodoPagoId': metodoPagoId,
    'monto': monto,
    'descripcion': descripcion,
    'frecuencia': frecuencia,
    if (diaVencimiento != null) 'diaVencimiento': diaVencimiento,
    if (diaSemana != null) 'diaSemana': diaSemana,
    'fechaInicio': fechaInicio,
    if (fechaFin != null) 'fechaFin': fechaFin,
  };
}

class RecurringService {
  final ApiClient apiClient;
  RecurringService(this.apiClient);

  String _msg(DioException e) {
    final data = e.response?.data;
    return '${(data is Map ? data['message'] : null) ?? e.message}';
  }

  /// Devuelve el id del pago creado (null si el servidor no lo informa).
  Future<int?> createRule(CreatePagoRecurrenteRequest req) async {
    try {
      final res = await apiClient.dio.post('/api/pagos-recurrentes', data: req.toJson());
      final data = res.data;
      return data is Map ? int.tryParse('${data['id']}') : null;
    } on DioException catch (e) {
      throw Exception('Error al crear pago recurrente: ${_msg(e)}');
    }
  }

  Future<List<PagoRecurrente>> getAll() async {
    try {
      final res = await apiClient.dio.get('/api/pagos-recurrentes');
      return (res.data as List)
          .map((j) => PagoRecurrente.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener pagos recurrentes: ${_msg(e)}');
    }
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    try {
      await apiClient.dio.patch('/api/pagos-recurrentes/$id', data: body);
    } on DioException catch (e) {
      throw Exception('Error al actualizar pago recurrente: ${_msg(e)}');
    }
  }

  Future<void> toggle(int id, bool activo) async {
    try {
      await apiClient.dio.patch(
        '/api/pagos-recurrentes/$id/toggle',
        queryParameters: {'activo': '$activo'},
      );
    } on DioException catch (e) {
      throw Exception('Error al cambiar estado: ${_msg(e)}');
    }
  }

  Future<void> executeNow(int id) async {
    try {
      // Fecha y hora del teléfono (sin ella el servidor usa la de Colombia)
      await apiClient.dio.post(
        '/api/pagos-recurrentes/$id/ejecutar',
        data: {'fecha': formatApiDateTime(DateTime.now())},
      );
    } on DioException catch (e) {
      throw Exception('Error al registrar el pago: ${_msg(e)}');
    }
  }

  Future<void> delete(int id) async {
    try {
      await apiClient.dio.delete('/api/pagos-recurrentes/$id');
    } on DioException catch (e) {
      throw Exception('Error al eliminar pago recurrente: ${_msg(e)}');
    }
  }
}
