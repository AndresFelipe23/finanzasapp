import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/pago_nfc_models.dart';
import 'pagos_nfc_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final pagosNfcServiceProvider = Provider<PagosNfcService>((ref) => PagosNfcService(ref.read(apiClientProvider)));

final pagosNfcProvider = StateNotifierProvider<PagosNfcNotifier, AsyncValue<List<PagoNfc>>>((ref) {
  return PagosNfcNotifier(ref.read(pagosNfcServiceProvider));
});

class PagosNfcNotifier extends StateNotifier<AsyncValue<List<PagoNfc>>> {
  final PagosNfcService _service;
  PagosNfcNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh({int? tarjetaId}) async {
    try {
      state = const AsyncValue.loading();
      final items = await _service.getAll(tarjetaId: tarjetaId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}


