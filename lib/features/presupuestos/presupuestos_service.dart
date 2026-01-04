import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/presupuesto_models.dart';

class PresupuestosService {
  final ApiClient apiClient;
  PresupuestosService(this.apiClient);

  Future<List<Presupuesto>> getAll({bool? activos}) async {
    try {
      final res = await apiClient.dio.get(
        '/api/presupuestos',
        queryParameters: activos == null ? null : {'activos': activos},
      );
      final List data = res.data;
      return data.map((e) => Presupuesto.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener presupuestos: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Presupuesto> create(CreatePresupuestoRequest req) async {
    try {
      final res = await apiClient.dio.post(
        '/api/presupuestos',
        data: req.toJson(),
      );
      return Presupuesto.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al crear presupuesto: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Presupuesto> update(int id, Map<String, dynamic> body) async {
    try {
      final res = await apiClient.dio.patch(
        '/api/presupuestos/$id',
        data: body,
      );
      return Presupuesto.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al actualizar presupuesto: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> toggle(int id, bool activo) async {
    try {
      await apiClient.dio.patch(
        '/api/presupuestos/$id/toggle',
        queryParameters: {'activo': activo},
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al cambiar estado: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await apiClient.dio.delete('/api/presupuestos/$id');
    } on DioException catch (e) {
      throw Exception(
        'Error al eliminar presupuesto: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Presupuesto> recalc(int id) async {
    try {
      final res = await apiClient.dio.patch('/api/presupuestos/$id/recalc');
      return Presupuesto.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al recalcular: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> resumen() async {
    try {
      final res = await apiClient.dio.get('/api/presupuestos/resumen');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener resumen: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
