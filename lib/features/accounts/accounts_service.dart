import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/cuenta_models.dart';

class AccountsService {
  final ApiClient apiClient;

  AccountsService(this.apiClient);

  /// Obtiene todas las cuentas del usuario
  Future<List<Cuenta>> getAllAccounts({String? tipo}) async {
    try {
      final queryParams = tipo != null ? {'tipo': tipo} : null;

      final response = await apiClient.dio.get(
        '/api/cuentas',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((json) => Cuenta.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener cuentas: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener cuentas: $e');
    }
  }

  /// Obtiene cuentas filtradas por tipo
  Future<List<Cuenta>> getAccountsByType(String tipo) async {
    return getAllAccounts(tipo: tipo);
  }

  /// Obtiene una cuenta por su ID
  Future<Cuenta> getAccountById(int id) async {
    try {
      final response = await apiClient.dio.get('/api/cuentas/$id');
      return Cuenta.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cuenta no encontrada');
      }
      throw Exception(
        'Error al obtener cuenta: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener cuenta: $e');
    }
  }

  /// Crea una nueva cuenta
  Future<Cuenta> createAccount(CreateCuentaRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/cuentas',
        data: request.toJson(),
      );

      return Cuenta.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Ya existe una cuenta con este nombre');
      }
      throw Exception(
        'Error al crear cuenta: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al crear cuenta: $e');
    }
  }

  /// Actualiza una cuenta
  Future<Cuenta> updateAccount(int id, UpdateCuentaRequest request) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/cuentas/$id',
        data: request.toJson(),
      );

      return Cuenta.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cuenta no encontrada');
      }
      throw Exception(
        'Error al actualizar cuenta: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al actualizar cuenta: $e');
    }
  }

  /// Elimina una cuenta
  Future<void> deleteAccount(int id) async {
    try {
      await apiClient.dio.delete('/api/cuentas/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Cuenta no encontrada');
      }
      if (e.response?.statusCode == 409) {
        final message =
            e.response?.data['message'] ??
            'No se puede eliminar porque tiene transacciones o saldo';
        throw Exception(message);
      }
      throw Exception(
        'Error al eliminar cuenta: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al eliminar cuenta: $e');
    }
  }

  /// Obtiene el resumen de cuentas con estadísticas
  Future<List<CuentaSummary>> getAccountsSummary() async {
    try {
      final response = await apiClient.dio.get('/api/cuentas/summary');

      return (response.data as List)
          .map((json) => CuentaSummary.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener resumen de cuentas: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener resumen de cuentas: $e');
    }
  }
}
