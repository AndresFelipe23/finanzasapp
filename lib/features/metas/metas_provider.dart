import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/meta_models.dart';
import 'metas_service.dart';

final metasServiceProvider = Provider<MetasService>((ref) {
  return MetasService(ApiClient());
});

final metasProvider = FutureProvider<List<Meta>>((ref) async {
  final service = ref.watch(metasServiceProvider);
  return await service.getAll();
});

class MetasNotifier extends StateNotifier<AsyncValue<List<Meta>>> {
  final MetasService _service;

  MetasNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final metas = await _service.getAll();
      state = AsyncValue.data(metas);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> create(CreateMetaRequest request) async {
    try {
      await _service.create(request);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMeta(int id, CreateMetaRequest request) async {
    try {
      await _service.update(id, request);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMeta(int id) async {
    try {
      await _service.delete(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> hacerAporte(AporteMetaRequest request) async {
    try {
      await _service.hacerAporte(request);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleActiva(int id, bool activa) async {
    try {
      await _service.toggleActiva(id, activa);
      await load();
    } catch (e) {
      rethrow;
    }
  }
}

final metasNotifierProvider =
    StateNotifierProvider<MetasNotifier, AsyncValue<List<Meta>>>((ref) {
      final service = ref.watch(metasServiceProvider);
      return MetasNotifier(service);
    });
