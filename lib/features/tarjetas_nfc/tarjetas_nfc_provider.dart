import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/tarjeta_nfc_models.dart';
import 'tarjetas_nfc_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final tarjetasNfcServiceProvider = Provider<TarjetasNfcService>((ref) => TarjetasNfcService(ref.read(apiClientProvider)));

final tarjetasNfcProvider = StateNotifierProvider<TarjetasNfcNotifier, AsyncValue<List<TarjetaNfc>>>((ref) {
  return TarjetasNfcNotifier(ref.read(tarjetasNfcServiceProvider));
});

class TarjetasNfcNotifier extends StateNotifier<AsyncValue<List<TarjetaNfc>>> {
  final TarjetasNfcService _service;
  TarjetasNfcNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh({bool? activas}) async {
    try {
      state = const AsyncValue.loading();
      final items = await _service.getAll(activas: activas);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create(CreateTarjetaNfcRequest req) async {
    await _service.create(req);
    await refresh();
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    await _service.update(id, body);
    await refresh();
  }

  Future<void> toggle(int id, bool activa) async {
    await _service.toggle(id, activa);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    await refresh();
  }
}


