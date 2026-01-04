import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/category_models.dart';

class CategoriesService {
  final ApiClient apiClient;

  CategoriesService(this.apiClient);

  /// Obtiene todas las categorías del usuario
  Future<List<Categoria>> getAllCategories({String? tipo}) async {
    try {
      final queryParams = tipo != null ? {'tipo': tipo} : null;

      final response = await apiClient.dio.get(
        '/api/categorias',
        queryParameters: queryParams,
      );

      return (response.data as List)
          .map((json) => Categoria.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener categorías: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  /// Obtiene categorías filtradas por tipo
  Future<List<Categoria>> getCategoriesByType(String tipo) async {
    return getAllCategories(tipo: tipo);
  }

  /// Obtiene una categoría por su ID
  Future<Categoria> getCategoryById(int id) async {
    try {
      final response = await apiClient.dio.get('/api/categorias/$id');
      return Categoria.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Categoría no encontrada');
      }
      throw Exception(
        'Error al obtener categoría: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener categoría: $e');
    }
  }

  /// Crea una nueva categoría
  Future<Categoria> createCategory(CreateCategoriaRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/categorias',
        data: request.toJson(),
      );

      return Categoria.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Ya existe una categoría con este nombre');
      }
      throw Exception(
        'Error al crear categoría: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  /// Actualiza una categoría
  Future<Categoria> updateCategory(
    int id,
    UpdateCategoriaRequest request,
  ) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/categorias/$id',
        data: request.toJson(),
      );

      return Categoria.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Categoría no encontrada');
      }
      throw Exception(
        'Error al actualizar categoría: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  /// Elimina una categoría
  Future<void> deleteCategory(int id) async {
    try {
      await apiClient.dio.delete('/api/categorias/$id');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Categoría no encontrada');
      }
      if (e.response?.statusCode == 409) {
        final message =
            e.response?.data['message'] ??
            'No se puede eliminar porque tiene transacciones asociadas';
        throw Exception(message);
      }
      throw Exception(
        'Error al eliminar categoría: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  /// Obtiene el resumen de categorías con estadísticas
  Future<List<CategoriaSummary>> getCategoriesSummary() async {
    try {
      final response = await apiClient.dio.get('/api/categorias/summary');

      return (response.data as List)
          .map((json) => CategoriaSummary.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener resumen de categorías: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al obtener resumen de categorías: $e');
    }
  }

  /// Crea categorías predeterminadas para el usuario
  Future<void> createDefaultCategories() async {
    try {
      await apiClient.dio.post('/api/categorias/default');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('El usuario ya tiene categorías personalizadas');
      }
      throw Exception(
        'Error al crear categorías predeterminadas: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al crear categorías predeterminadas: $e');
    }
  }
}
