import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/auth_models.dart';
import '../../core/navigation/main_navigation.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_mark.dart';
import 'auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService(ApiClient());

  bool _showPass = false;
  bool _remember = true;
  bool _loading = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final email = await _auth.savedEmail();
      final bio = await _auth.biometricLoginEnabled();
      if (!mounted) return;
      setState(() {
        if (email != null) _emailCtrl.text = email;
        _remember = email != null || _emailCtrl.text.isEmpty;
        _biometricEnabled = bio;
      });
      // Con la huella activada se ofrece de una vez, como en apps bancarias
      if (bio) _loginWithBiometrics();
    } catch (_) {
      // Sin preferencias guardadas se muestra el formulario vacío
    }
  }

  void _enter(UserResponse user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigation(user: user)),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final res = await _auth.login(
        LoginRequest(email: email, password: _passCtrl.text),
      );
      await _auth.setRemember(_remember, email);
      if (!mounted) return;
      if (await _auth.shouldOfferBiometric() && mounted) {
        final activar = await _askBiometric();
        await _auth.setBiometricLogin(activar);
      }
      if (mounted) _enter(res.user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> _askBiometric() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brand.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Brand.accentSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.fingerprint_rounded,
              color: Brand.accent, size: 30),
        ),
        title: Text(
          '¿Entrar con huella la próxima vez?',
          textAlign: TextAlign.center,
          style: Brand.text(size: 18, weight: FontWeight.w800),
        ),
        content: Text(
          'Podrás abrir Financially sin escribir tu contraseña. Puedes '
          'desactivarlo cerrando sesión.',
          textAlign: TextAlign.center,
          style: Brand.text(size: 14, color: Brand.muted, height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ahora no',
                style: Brand.text(weight: FontWeight.w700, color: Brand.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.accent),
            child: Text('Activar',
                style: Brand.text(weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _loginWithBiometrics() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await _auth.loginWithBiometrics();
      if (!mounted) return;
      if (res != null) {
        _enter(res.user);
        return;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      final enabled = await _auth.biometricLoginEnabled();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _biometricEnabled = enabled;
      });
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canPop)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BrandBackButton(),
                        ),
                      // Spacers arriba y abajo: el formulario queda centrado
                      // en la pantalla y el enlace de registro abajo
                      const Spacer(),
                      const SizedBox(height: 24),
                      // El mismo logo que el ícono de la app
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BrandMark(size: 56),
                      ),
                      const SizedBox(height: 20),
                      Text('Bienvenido de nuevo', style: Brand.title()),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para ver tus cuentas y movimientos.',
                        style: Brand.text(color: Brand.muted),
                      ),
                      const SizedBox(height: 28),
                      AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BrandField(
                              label: 'Correo electrónico',
                              hint: 'nombre@correo.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Escribe tu correo'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            BrandField(
                              label: 'Contraseña',
                              controller: _passCtrl,
                              obscure: !_showPass,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Escribe tu contraseña'
                                  : null,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _showPass = !_showPass),
                                tooltip: _showPass
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                icon: Icon(
                                  _showPass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Brand.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _remember = !_remember),
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _remember,
                                    activeColor: Brand.accent,
                                    onChanged: (v) =>
                                        setState(() => _remember = v ?? false),
                                  ),
                                  Text('Recordarme',
                                      style: Brand.text(size: 14)),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  initialEmail: _emailCtrl.text.trim(),
                                ),
                              ),
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: Brand.text(
                                size: 14,
                                weight: FontWeight.w700,
                                color: Brand.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      BrandButton(
                        label: 'Iniciar sesión',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      if (_biometricEnabled) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Brand.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('o',
                                  style: Brand.text(size: 13, color: Brand.muted)),
                            ),
                            const Expanded(child: Divider(color: Brand.border)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        BrandOutlineButton(
                          label: 'Entrar con huella o Face ID',
                          background: Brand.surface,
                          icon: const Icon(Icons.fingerprint_rounded, size: 22),
                          onPressed: _loading ? null : _loginWithBiometrics,
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('¿No tienes cuenta? ',
                                style: Brand.text(size: 14, color: Brand.muted)),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(
                                'Regístrate',
                                style: Brand.text(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: Brand.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
