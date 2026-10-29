import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/prestamo_models.dart';
import 'prestamos_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final prestamosNotifierProvider =
    StateNotifierProvider<PrestamosNotifier, AsyncValue<List<Prestamo>>>((ref) {
      return PrestamosNotifier(PrestamosService(ref.read(apiClientProvider)));
    });

class PrestamosNotifier extends StateNotifier<AsyncValue<List<Prestamo>>> {
  final PrestamosService _service;

  PrestamosNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh({bool? activos}) async {
    try {
      state = const AsyncLoading<List<Prestamo>>().copyWithPrevious(state);
      final items = await _service.getAll(activos: activos);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(CreatePrestamoRequest req) async {
    try {
      await _service.create(req);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggle(int id, bool activa) async {
    await _service.toggle(id, activa);
    await refresh();
  }

  Future<void> update(int id, CreatePrestamoRequest req) async {
    await _service.update(id, req.toJson());
    await refresh();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    await refresh();
  }

  Future<void> crearPago(CreatePagoPrestamoRequest req) async {
    await _service.crearPago(req);
    await refresh();
  }
}
