import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/meta_models.dart';

class MetasService {
  final ApiClient apiClient;

  MetasService(this.apiClient);

  Future<List<Meta>> getAll() async {
    try {
      final response = await apiClient.dio.get('/api/metas');
      final List<dynamic> data = response.data;
      return data.map((json) => Meta.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener metas: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Meta> getById(int id) async {
    try {
      final response = await apiClient.dio.get('/api/metas/$id');
      return Meta.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener meta: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Meta> create(CreateMetaRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/metas',
        data: request.toJson(),
      );
      return Meta.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al crear meta: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Meta> update(int id, CreateMetaRequest request) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/metas/$id',
        data: request.toJson(),
      );
      return Meta.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al actualizar meta: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> delete(int id) async {
    try {
      await apiClient.dio.delete('/api/metas/$id');
    } on DioException catch (e) {
      throw Exception(
        'Error al eliminar meta: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<Meta> hacerAporte(AporteMetaRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/metas/${request.metaId}/aportes',
        data: {
          'cuentaId': request.cuentaId,
          'montoAporte': request.montoAporte,
          if (request.notas != null) 'notas': request.notas,
        },
      );
      return Meta.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al hacer aporte: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }

  Future<void> toggleActiva(int id, bool activa) async {
    try {
      await apiClient.dio.patch(
        '/api/metas/$id/toggle',
        queryParameters: {'activa': activa},
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al cambiar estado: ${e.response?.data['message'] ?? e.message}',
      );
    }
  }
}
