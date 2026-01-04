import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

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

  Future<void> createRule(CreatePagoRecurrenteRequest req) async {
    try {
      await apiClient.dio.post('/api/pagos-recurrentes', data: req.toJson());
    } on DioException catch (e) {
      throw Exception(
        'Error al crear pago recurrente: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
