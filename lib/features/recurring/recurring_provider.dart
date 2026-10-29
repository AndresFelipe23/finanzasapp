import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pago_recurrente_models.dart';
import '../../core/notifications/notification_service.dart';
import '../categories/categories_provider.dart'; // Para usar apiClientProvider
import 'recurring_service.dart';

final recurringServiceProvider = Provider((ref) {
  return RecurringService(ref.watch(apiClientProvider));
});

final recurringProvider = FutureProvider<List<PagoRecurrente>>((ref) async {
  final items = await ref.watch(recurringServiceProvider).getAll();
  // Cada recarga reprograma los recordatorios con la lista más reciente
  await NotificationService.instance.scheduleRecurringReminders(items);
  return items;
});
