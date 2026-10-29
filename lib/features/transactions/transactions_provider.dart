import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transaccion_models.dart';
import 'transactions_service.dart';
import '../categories/categories_provider.dart'; // Para usar apiClientProvider

// Provider del servicio
final transactionsServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionsService(apiClient);
});

// Provider para todas las transacciones
final transactionsProvider = FutureProvider<List<Transaccion>>((ref) async {
  final service = ref.watch(transactionsServiceProvider);
  return await service.getAllTransactions();
});

// Notifier para manejar las operaciones de transacciones
class TransactionsNotifier
    extends StateNotifier<AsyncValue<List<Transaccion>>> {
  TransactionsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadTransactions();
  }

  final TransactionsService _service;

  Future<void> _loadTransactions() async {
    state = const AsyncLoading<List<Transaccion>>().copyWithPrevious(state);
    try {
      final transactions = await _service.getAllTransactions();
      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTransaction(CreateTransaccionRequest request) async {
    try {
      await _service.createTransaction(request);
      // Recargar la lista
      final transactions = await _service.getAllTransactions();
      state = AsyncValue.data(transactions);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateTransaction(
    int id,
    UpdateTransaccionRequest request,
  ) async {
    try {
      await _service.updateTransaction(id, request);
      // Recargar la lista
      final transactions = await _service.getAllTransactions();
      state = AsyncValue.data(transactions);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _service.deleteTransaction(id);
      // Recargar la lista
      final transactions = await _service.getAllTransactions();
      state = AsyncValue.data(transactions);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> refresh() => _loadTransactions();
}

final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaccion>>>((
      ref,
    ) {
      final service = ref.watch(transactionsServiceProvider);
      return TransactionsNotifier(service);
    });
