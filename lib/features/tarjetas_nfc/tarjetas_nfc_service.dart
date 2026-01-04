import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/tarjeta_nfc_models.dart';

class TarjetasNfcService {
  final ApiClient apiClient;
  TarjetasNfcService(this.apiClient);

  Future<List<TarjetaNfc>> getAll({bool? activas}) async {
    try {
      final res = await apiClient.dio.get(
        '/api/tarjetas-nfc',
        queryParameters: activas == null ? null : {'activas': activas},
      );
      final List data = res.data;
      return data.map((e) => TarjetaNfc.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener tarjetas: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<TarjetaNfc> create(CreateTarjetaNfcRequest req) async {
    try {
      final res = await apiClient.dio.post('/api/tarjetas-nfc', data: req.toJson());
      return TarjetaNfc.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception('Error al crear tarjeta: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<TarjetaNfc> update(int id, Map<String, dynamic> body) async {
    try {
      final res = await apiClient.dio.patch('/api/tarjetas-nfc/$id', data: body);
      return TarjetaNfc.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar tarjeta: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<TarjetaNfc> toggle(int id, bool activa) async {
    try {
      final res = await apiClient.dio.patch(
        '/api/tarjetas-nfc/$id/toggle',
        queryParameters: {'activa': activa},
      );
      return TarjetaNfc.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception('Error al cambiar estado: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<void> delete(int id) async {
    try {
      await apiClient.dio.delete('/api/tarjetas-nfc/$id');
    } on DioException catch (e) {
      throw Exception('Error al eliminar tarjeta: ${e.response?.data['message'] ?? e.message}');
    }
  }
}


