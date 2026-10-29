import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/auth_models.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/monedas_constants.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'register_account_screen.dart';

/// Registro · paso 1: datos de la cuenta de usuario.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService(ApiClient());

  String _moneda = 'COP';
  bool _agreed = false;
  bool _showPass = false;
  bool _loading = false;

  // USD aparece varias veces (Ecuador, El Salvador, Panamá): una por código
  late final List<MonedaInfo> _monedas = {
    for (final m in MonedasConstants.monedasHispanas) m.codigo: m,
  }.values.toList();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// 0–4: largo ≥ 8, mayúsculas y minúsculas, números, símbolos.
  int get _strength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    return [
      p.length >= 8,
      p.contains(RegExp('[a-z]')) && p.contains(RegExp('[A-Z]')),
      p.contains(RegExp(r'\d')),
      p.contains(RegExp(r'[^A-Za-z0-9]')),
    ].where((ok) => ok).length;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = await _auth.register(
        RegisterRequest(
          nombre: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          monedaPredeterminada: _moneda,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RegisterAccountScreen(user: auth.user),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showBrandSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showLegal(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: Brand.text(size: 18, weight: FontWeight.w800)),
        content: Text(
          'Estamos preparando este documento. Lo podrás consultar aquí '
          'muy pronto.',
          style: Brand.text(color: Brand.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strength;
    final strengthColor = strength >= 3 ? Brand.accent : Brand.expense;
    final strengthLabel = _passCtrl.text.length < 8
        ? 'Mínimo 8 caracteres'
        : switch (strength) {
            4 => 'Contraseña muy segura',
            3 => 'Contraseña segura',
            _ => 'Agrega mayúsculas, números o símbolos',
          };

    return Scaffold(
      backgroundColor: Brand.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandBackButton(),
                  Text(
                    'Paso 1 de 2',
                    style: Brand.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Brand.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Crea tu cuenta', style: Brand.title()),
              const SizedBox(height: 8),
              Text(
                'Empieza a ordenar tus finanzas en menos de un minuto.',
                style: Brand.text(color: Brand.muted),
              ),
              const SizedBox(height: 22),
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandField(
                      label: 'Nombre completo',
                      hint: 'Tu nombre',
                      controller: _nombreCtrl,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Escribe tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    BrandField(
                      label: 'Correo electrónico',
                      hint: 'nombre@correo.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Escribe tu correo';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                          return 'Ese correo no parece válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    BrandField(
                      label: 'Contraseña',
                      controller: _passCtrl,
                      obscure: !_showPass,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Usa al menos 8 caracteres'
                          : null,
                      suffix: IconButton(
                        onPressed: () => setState(() => _showPass = !_showPass),
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
              if (_passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: i < strength
                                  ? strengthColor
                                  : Brand.inputBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strengthLabel,
                  style: Brand.text(
                    size: 12,
                    weight: FontWeight.w700,
                    color: strengthColor,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Moneda principal',
                style: Brand.text(size: 13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _moneda,
                isExpanded: true,
                style: Brand.text(weight: FontWeight.w600),
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Brand.surface,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Brand.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Brand.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Brand.inputBorder),
                  ),
                ),
                items: [
                  for (final m in _monedas)
                    DropdownMenuItem(
                      value: m.codigo,
                      child: Text(
                        '${m.nombreMoneda} (${m.codigo})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _moneda = v ?? _moneda),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: _agreed,
                      activeColor: Brand.accent,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Acepto los ',
                          style: Brand.text(size: 13, color: Brand.muted),
                        ),
                        _InlineLink(
                          'Términos',
                          () => _showLegal('Términos y condiciones'),
                        ),
                        Text(
                          ' y el ',
                          style: Brand.text(size: 13, color: Brand.muted),
                        ),
                        _InlineLink(
                          'Aviso de privacidad',
                          () => _showLegal('Aviso de privacidad'),
                        ),
                        Text(
                          '.',
                          style: Brand.text(size: 13, color: Brand.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              BrandButton(
                label: 'Crear cuenta',
                loading: _loading,
                onPressed: _agreed ? _submit : null,
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: Brand.text(size: 14, color: Brand.muted),
                    ),
                    _InlineLink(
                      'Inicia sesión',
                      () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink(this.label, this.onTap, {this.size = 13});

  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: Brand.text(
            size: size,
            weight: FontWeight.w700,
            color: Brand.accent,
          ),
        ),
      ),
    );
  }
}
