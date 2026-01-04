import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/presupuesto_models.dart';
import 'presupuestos_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final presupuestosNotifierProvider =
    StateNotifierProvider<PresupuestosNotifier, AsyncValue<List<Presupuesto>>>((
      ref,
    ) {
      return PresupuestosNotifier(
        PresupuestosService(ref.read(apiClientProvider)),
      );
    });

/// Resumen de presupuestos desde el backend
final presupuestosResumenProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = PresupuestosService(ref.read(apiClientProvider));
  return await service.resumen();
});

class PresupuestosNotifier
    extends StateNotifier<AsyncValue<List<Presupuesto>>> {
  final PresupuestosService _service;
  PresupuestosNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh({bool? activos}) async {
    try {
      state = const AsyncValue.loading();
      final items = await _service.getAll(activos: activos);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(CreatePresupuestoRequest req) async {
    await _service.create(req);
    await refresh();
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _service.update(id, body);
    await refresh();
  }

  Future<void> toggle(int id, bool activo) async {
    await _service.toggle(id, activo);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    await refresh();
  }
}
