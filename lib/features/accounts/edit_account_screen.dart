import 'package:flutter/material.dart';
import '../../core/models/cuenta_models.dart';
import 'account_form_screen.dart';

/// Editar una cuenta (usa el formulario compartido con la creación).
class EditAccountScreen extends StatelessWidget {
  final Cuenta cuenta;

  const EditAccountScreen({super.key, required this.cuenta});

  @override
  Widget build(BuildContext context) => AccountFormScreen(cuenta: cuenta);
}
