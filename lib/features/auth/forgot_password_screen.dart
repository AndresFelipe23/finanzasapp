import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/brand.dart';
import 'auth_service.dart';

/// Pide el enlace de recuperación. El correo lleva a la web para elegir la
/// nueva contraseña (`/auth/reset-password`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService(ApiClient()).forgotPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandBackButton(),
              ),
              const SizedBox(height: 28),
              if (_sent) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Brand.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: Brand.accent, size: 32),
                ),
                const SizedBox(height: 20),
                Text('Revisa tu correo', style: Brand.title()),
                const SizedBox(height: 8),
                Text(
                  'Si ${_emailCtrl.text.trim()} tiene una cuenta, te enviamos un '
                  'enlace para crear una contraseña nueva. Puede tardar unos '
                  'minutos; revisa también la carpeta de spam.',
                  style: Brand.text(color: Brand.muted, height: 1.5),
                ),
                const SizedBox(height: 32),
                BrandButton(
                  label: 'Volver a iniciar sesión',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else ...[
                Text('Recupera tu contraseña', style: Brand.title()),
                const SizedBox(height: 8),
                Text(
                  'Escribe el correo de tu cuenta y te enviaremos un enlace '
                  'para crear una nueva.',
                  style: Brand.text(color: Brand.muted, height: 1.45),
                ),
                const SizedBox(height: 28),
                BrandField(
                  label: 'Correo electrónico',
                  hint: 'nombre@correo.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Escribe tu correo'
                      : null,
                ),
                const SizedBox(height: 28),
                BrandButton(
                  label: 'Enviar enlace',
                  loading: _loading,
                  onPressed: _send,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
