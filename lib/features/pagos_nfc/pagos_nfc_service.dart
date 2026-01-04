import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/pago_nfc_models.dart';

class PagosNfcService {
  final ApiClient apiClient;
  PagosNfcService(this.apiClient);

  Future<List<PagoNfc>> getAll({int? tarjetaId}) async {
    try {
      final res = await apiClient.dio.get(
        '/api/pagos-nfc',
        queryParameters: tarjetaId == null ? null : {'tarjetaId': tarjetaId},
      );
      final List data = res.data;
      return data.map((e) => PagoNfc.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener pagos NFC: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<PagoNfc> create(Map<String, dynamic> body) async {
    try {
      final res = await apiClient.dio.post('/api/pagos-nfc', data: body);
      return PagoNfc.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception('Error al crear pago NFC: ${e.response?.data['message'] ?? e.message}');
    }
  }
}


