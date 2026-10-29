import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/category_models.dart';
import 'categories_service.dart';

// Provider del servicio
final categoriesServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoriesService(apiClient);
});

// Provider del ApiClient
final apiClientProvider = Provider((ref) => ApiClient());

// Provider para todas las categorías
final categoriesProvider = FutureProvider<List<Categoria>>((ref) async {
  final service = ref.watch(categoriesServiceProvider);
  return await service.getAllCategories();
});

// Provider para categorías de ingresos
final incomeCategoriesProvider = FutureProvider<List<Categoria>>((ref) async {
  final service = ref.watch(categoriesServiceProvider);
  return await service.getCategoriesByType('INGRESO');
});

// Provider para categorías de gastos
final expenseCategoriesProvider = FutureProvider<List<Categoria>>((ref) async {
  final service = ref.watch(categoriesServiceProvider);
  return await service.getCategoriesByType('GASTO');
});

// Provider para el resumen de categorías
final categoriesSummaryProvider = FutureProvider<List<CategoriaSummary>>((
  ref,
) async {
  final service = ref.watch(categoriesServiceProvider);
  return await service.getCategoriesSummary();
});

// Provider para la categoría seleccionada
final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

// Notifier para manejar las operaciones de categorías
class CategoriesNotifier extends StateNotifier<AsyncValue<List<Categoria>>> {
  CategoriesNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  final CategoriesService _service;

  Future<void> _loadCategories() async {
    state = const AsyncLoading<List<Categoria>>().copyWithPrevious(state);
    try {
      final categories = await _service.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createCategory(CreateCategoriaRequest request) async {
    try {
      await _service.createCategory(request);
      // Recargar la lista
      final categories = await _service.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateCategory(int id, UpdateCategoriaRequest request) async {
    try {
      await _service.updateCategory(id, request);
      // Recargar la lista
      final categories = await _service.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _service.deleteCategory(id);
      // Recargar la lista
      final categories = await _service.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> refresh() => _loadCategories();

  Future<void> createDefaultCategories() async {
    try {
      await _service.createDefaultCategories();
      // Recargar la lista
      final categories = await _service.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error) {
      rethrow;
    }
  }
}

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Categoria>>>((
      ref,
    ) {
      final service = ref.watch(categoriesServiceProvider);
      return CategoriesNotifier(service);
    });
