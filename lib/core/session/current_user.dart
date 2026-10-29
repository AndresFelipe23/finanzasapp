import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';

/// Último perfil guardado en esta sesión (Perfil lo actualiza al editar el
/// nombre o la moneda), para que Inicio y el menú lo reflejen sin volver a
/// iniciar sesión.
final currentUserProvider = StateProvider<UserResponse?>((ref) => null);

/// El perfil vigente: el editado en esta sesión si es del mismo usuario; si
/// no (otra cuenta tras cerrar sesión), el que trajo el inicio de sesión.
UserResponse vigente(WidgetRef ref, UserResponse inicial) {
  final editado = ref.watch(currentUserProvider);
  return editado != null && editado.id == inicial.id ? editado : inicial;
}
