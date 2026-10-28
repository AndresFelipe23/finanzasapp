import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_client.dart';
import '../../core/models/auth_models.dart';
import '../../core/utils/monedas_constants.dart';
import 'auth_service.dart';
import '../../core/navigation/main_navigation.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color accent = Color(0xFF5B5FEE);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1E2340);
  static const Color textSub = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  String _selectedMoneda = 'COP';

  late final AuthService authService;
  late final AnimationController _animCtrl;
  Animation<double> _fade = const AlwaysStoppedAnimation(1.0);
  Animation<Offset> _slide = const AlwaysStoppedAnimation(Offset.zero);

  @override
  void initState() {
    super.initState();
    authService = AuthService(ApiClient());
    _loadSavedCredentials();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final email =
          await authService.apiClient.storage.read(key: 'savedEmail');
      final password =
          await authService.apiClient.storage.read(key: 'savedPassword');
      if (email != null && password != null) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _rememberMe = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      AuthResponse response;
      if (_isRegisterMode) {
        response = await authService.register(RegisterRequest(
          nombre: _nombreController.text,
          email: _emailController.text,
          password: _passwordController.text,
          monedaPredeterminada: _selectedMoneda,
        ));
      } else {
        response = await authService.login(LoginRequest(
          email: _emailController.text,
          password: _passwordController.text,
        ));
      }

      if (_rememberMe) {
        await authService.saveCredentials(
            _emailController.text, _passwordController.text);
      } else {
        await authService.clearCredentials();
      }

      if (mounted) {
        _snack('¡Bienvenido ${response.user.nombre}!', _C.success,
            Icons.check_circle_rounded);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigation(user: response.user)),
        );
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), _C.danger,
            Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _formKey.currentState?.reset();
      _nombreController.clear();
      _confirmPasswordController.clear();
    });
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),

                    // ── Marca ──────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _C.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 22,
                            color: _C.accent,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          'Financially',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _C.primary,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 44),

                    // ── Encabezado ─────────────────────────────────────
                    Text(
                      _isRegisterMode ? 'Crear cuenta' : 'Bienvenido',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _C.primary,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegisterMode
                          ? 'Completa los datos para registrarte'
                          : 'Inicia sesion para continuar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _C.textSub,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Campos ─────────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isRegisterMode) ...[
                            _Field(
                              controller: _nombreController,
                              label: 'Nombre completo',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Ingresa tu nombre'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _Field(
                            controller: _emailController,
                            label: 'Correo electronico',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              if (!v.contains('@')) return 'Correo invalido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _passwordController,
                            label: 'Contrasena',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: _EyeBtn(
                              visible: !_obscurePassword,
                              onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingresa tu contrasena';
                              }
                              if (v.length < 6) return 'Minimo 6 caracteres';
                              return null;
                            },
                          ),
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 14),
                            _Field(
                              controller: _confirmPasswordController,
                              label: 'Confirmar contrasena',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: _EyeBtn(
                                visible: !_obscureConfirmPassword,
                                onTap: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                              validator: (v) =>
                                  v != _passwordController.text
                                      ? 'Las contrasenas no coinciden'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            _MonedaSelector(
                              selected: _selectedMoneda,
                              onChanged: (v) =>
                                  setState(() => _selectedMoneda = v),
                            ),
                          ],
                          if (!_isRegisterMode) ...[
                            const SizedBox(height: 16),
                            _RememberMe(
                              value: _rememberMe,
                              onToggle: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _SubmitBtn(
                            isLoading: _isLoading,
                            label: _isRegisterMode
                                ? 'Crear cuenta'
                                : 'Iniciar sesion',
                            onTap: _handleSubmit,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Toggle ─────────────────────────────────────────
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Center(
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: _isRegisterMode
                                  ? 'Ya tienes cuenta? '
                                  : 'No tienes cuenta? ',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, color: _C.textSub),
                            ),
                            TextSpan(
                              text: _isRegisterMode
                                  ? 'Inicia sesion'
                                  : 'Registrate',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _C.accent,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w500, color: _C.primary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: _C.textSub, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: _C.accent, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: _C.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.danger, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      );
}

// ─── Eye button ───────────────────────────────────────────────────────────────
class _EyeBtn extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _EyeBtn({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: _C.textSub,
          size: 20,
        ),
        onPressed: onTap,
      );
}

// ─── Remember me ──────────────────────────────────────────────────────────────
class _RememberMe extends StatelessWidget {
  final bool value;
  final VoidCallback onToggle;
  const _RememberMe({required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onToggle,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? _C.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? _C.accent : _C.border,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              'Recordar mi sesion',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _C.textSub,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
}

// ─── Moneda selector ──────────────────────────────────────────────────────────
class _MonedaSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _MonedaSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final info = MonedasConstants.getMonedaPorCodigo(selected);
    final hint =
        info != null ? '${info.nombreMoneda} - ${info.pais}' : selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moneda predeterminada',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w600, color: _C.primary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selected,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500, color: _C.primary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.currency_exchange_rounded,
                color: _C.accent, size: 20),
            filled: true,
            fillColor: _C.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _C.accent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
          items: MonedasConstants.codigosUnicos.map((codigo) {
            final m = MonedasConstants.getMonedaPorCodigo(codigo);
            final paises = MonedasConstants.getMonedasPorPais(m?.pais ?? '');
            final label = paises.length > 1
                ? '$codigo (${paises.map((x) => x.pais).join(', ')})'
                : m != null
                    ? '${m.codigo} - ${m.pais}'
                    : codigo;
            return DropdownMenuItem<String>(
                value: codigo, child: Text(label));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          dropdownColor: _C.surface,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _C.textSub, size: 22),
        ),
        const SizedBox(height: 5),
        Text(
          hint,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: _C.textSub, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

// ─── Submit button ────────────────────────────────────────────────────────────
class _SubmitBtn extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onTap;
  const _SubmitBtn(
      {required this.isLoading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _C.accent.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.accent,
            disabledBackgroundColor: _C.accent.withValues(alpha: 0.55),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
        ),
      );
}
