import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cuenta_models.dart';
import 'accounts_service.dart';
import '../categories/categories_provider.dart'; // Para usar apiClientProvider

// Provider del servicio
final accountsServiceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccountsService(apiClient);
});

// Provider para todas las cuentas
final accountsProvider = FutureProvider<List<Cuenta>>((ref) async {
  final service = ref.watch(accountsServiceProvider);
  return await service.getAllAccounts();
});

// Provider para cuentas bancarias
final bankAccountsProvider = FutureProvider<List<Cuenta>>((ref) async {
  final service = ref.watch(accountsServiceProvider);
  return await service.getAccountsByType('BANCARIA');
});

// Provider para efectivo
final cashAccountsProvider = FutureProvider<List<Cuenta>>((ref) async {
  final service = ref.watch(accountsServiceProvider);
  return await service.getAccountsByType('EFECTIVO');
});

// Provider para el resumen de cuentas
final accountsSummaryProvider = FutureProvider<List<CuentaSummary>>((
  ref,
) async {
  final service = ref.watch(accountsServiceProvider);
  return await service.getAccountsSummary();
});

// Provider para la cuenta seleccionada
final selectedAccountIdProvider = StateProvider<int?>((ref) => null);

// Notifier para manejar las operaciones de cuentas
class AccountsNotifier extends StateNotifier<AsyncValue<List<Cuenta>>> {
  AccountsNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadAccounts();
  }

  final AccountsService _service;

  Future<void> _loadAccounts() async {
    // Conserva la lista anterior mientras recarga: si no, las pantallas la ven
    // vacía un instante (y creen que el usuario no tiene cuentas)
    state = const AsyncLoading<List<Cuenta>>().copyWithPrevious(state);
    try {
      final accounts = await _service.getAllAccounts();
      state = AsyncValue.data(accounts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createAccount(CreateCuentaRequest request) async {
    try {
      await _service.createAccount(request);
      // Recargar la lista
      final accounts = await _service.getAllAccounts();
      state = AsyncValue.data(accounts);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateAccount(int id, UpdateCuentaRequest request) async {
    try {
      await _service.updateAccount(id, request);
      // Recargar la lista
      final accounts = await _service.getAllAccounts();
      state = AsyncValue.data(accounts);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _service.deleteAccount(id);
      // Recargar la lista
      final accounts = await _service.getAllAccounts();
      state = AsyncValue.data(accounts);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> refresh() => _loadAccounts();
}

final accountsNotifierProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<Cuenta>>>((ref) {
      final service = ref.watch(accountsServiceProvider);
      return AccountsNotifier(service);
    });
