import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/prestamo_models.dart';

class PrestamosService {
  final ApiClient apiClient;

  PrestamosService(this.apiClient);

  Future<List<Prestamo>> getAll({bool? activos}) async {
    try {
      final response = await apiClient.dio.get(
        '/api/prestamos',
        queryParameters: activos == null ? null : {'activos': activos},
      );
      final List<dynamic> data = response.data;
      return data.map((e) => Prestamo.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener préstamos: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Prestamo> create(CreatePrestamoRequest req) async {
    try {
      final response = await apiClient.dio.post(
        '/api/prestamos',
        data: req.toJson(),
      );
      return Prestamo.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al crear préstamo: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Prestamo> update(int id, Map<String, dynamic> body) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/prestamos/$id',
        data: body,
      );
      return Prestamo.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al actualizar préstamo: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> toggle(int id, bool activa) async {
    try {
      await apiClient.dio.patch(
        '/api/prestamos/$id/toggle',
        queryParameters: {'activa': activa},
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al cambiar estado: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await apiClient.dio.delete('/api/prestamos/$id');
    } on DioException catch (e) {
      throw Exception(
        'Error al eliminar préstamo: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> crearPago(CreatePagoPrestamoRequest req) async {
    try {
      await apiClient.dio.post(
        '/api/prestamos/${req.prestamoId}/pagos',
        data: req.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al crear pago: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
