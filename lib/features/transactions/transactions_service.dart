import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/transaccion_models.dart';

class TransactionsService {
  final ApiClient apiClient;

  TransactionsService(this.apiClient);

  /// Obtiene todas las transacciones del usuario
  Future<List<Transaccion>> getAllTransactions({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String();
      }

      final response = await apiClient.dio.get(
        '/api/transacciones',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return (response.data as List)
          .map((json) => Transaccion.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener transacciones: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener transacciones: $e');
    }
  }

  /// Obtiene transacciones por cuenta
  Future<List<Transaccion>> getTransactionsByAccount(
    int cuentaId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String();
      }

      final response = await apiClient.dio.get(
        '/api/transacciones/cuenta/$cuentaId',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return (response.data as List)
          .map((json) => Transaccion.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener transacciones por cuenta: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener transacciones por cuenta: $e');
    }
  }

  /// Obtiene transacciones por categoría
  Future<List<Transaccion>> getTransactionsByCategory(
    int categoriaId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String();
      }

      final response = await apiClient.dio.get(
        '/api/transacciones/categoria/$categoriaId',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return (response.data as List)
          .map((json) => Transaccion.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener transacciones por categoría: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener transacciones por categoría: $e');
    }
  }

  /// Obtiene una transacción por su ID
  Future<Transaccion> getTransactionById(int id) async {
    try {
      final response = await apiClient.dio.get('/api/transacciones/$id');
      return Transaccion.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Transacción no encontrada');
      }
      throw Exception(
        'Error al obtener transacción: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener transacción: $e');
    }
  }

  /// Crea una nueva transacción
  Future<Transaccion> createTransaction(
    CreateTransaccionRequest request,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '/api/transacciones',
        data: request.toJson(),
      );

      return Transaccion.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al crear transacción: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al crear transacción: $e');
    }
  }

  /// Actualiza una transacción
  Future<Transaccion> updateTransaction(
    int id,
    UpdateTransaccionRequest request,
  ) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/transacciones/$id',
        data: request.toJson(),
      );

      return Transaccion.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Transacción no encontrada');
      }
      throw Exception(
        'Error al actualizar transacción: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al actualizar transacción: $e');
    }
  }

  /// Elimina una transacción
  Future<void> deleteTransaction(int id) async {
    try {
      await apiClient.dio.delete('/api/transacciones/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Transacción no encontrada');
      }
      throw Exception(
        'Error al eliminar transacción: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }

  /// Obtiene el resumen de transacciones
  Future<List<Map<String, dynamic>>> getSummary({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String();
      }

      final response = await apiClient.dio.get(
        '/api/transacciones/summary',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener resumen: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener resumen: $e');
    }
  }
}
