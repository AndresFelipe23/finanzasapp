import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/cuenta_models.dart';
import '../../core/utils/monedas_constants.dart';
import 'accounts_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color primary = Color(0xFF1E2340);
  static const Color accent = Color(0xFF5B5FEE);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textSub = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

// ─── Data ─────────────────────────────────────────────────────────────────────
class _ColorOpt {
  final String hex;
  final String label;
  final Color color;
  const _ColorOpt(this.hex, this.label, this.color);
}

class _IconOpt {
  final String value;
  final String label;
  final IconData icon;
  const _IconOpt(this.value, this.label, this.icon);
}

const _kColores = [
  _ColorOpt('#5B5FEE', 'Índigo', Color(0xFF5B5FEE)),
  _ColorOpt('#3B82F6', 'Azul', Color(0xFF3B82F6)),
  _ColorOpt('#22C55E', 'Verde', Color(0xFF22C55E)),
  _ColorOpt('#14B8A6', 'Teal', Color(0xFF14B8A6)),
  _ColorOpt('#F59E0B', 'Ámbar', Color(0xFFF59E0B)),
  _ColorOpt('#EF4444', 'Rojo', Color(0xFFEF4444)),
  _ColorOpt('#EC4899', 'Rosa', Color(0xFFEC4899)),
  _ColorOpt('#A855F7', 'Morado', Color(0xFFA855F7)),
];

const _kIconos = [
  _IconOpt('account_balance', 'Banco', Icons.account_balance_rounded),
  _IconOpt('account_balance_wallet', 'Billetera', Icons.account_balance_wallet_rounded),
  _IconOpt('credit_card', 'Tarjeta', Icons.credit_card_rounded),
  _IconOpt('savings', 'Ahorros', Icons.savings_rounded),
  _IconOpt('wallet', 'Cartera', Icons.wallet_rounded),
  _IconOpt('payments', 'Pagos', Icons.payments_rounded),
  _IconOpt('trending_up', 'Inversión', Icons.trending_up_rounded),
  _IconOpt('attach_money', 'Dinero', Icons.attach_money_rounded),
];

const _kTipos = [
  ('BANCARIA', 'Bancaria'),
  ('EFECTIVO', 'Efectivo'),
  ('TARJETA_CREDITO', 'T. Crédito'),
  ('TARJETA_DEBITO', 'T. Débito'),
  ('DIGITAL', 'Digital'),
  ('AHORRO', 'Ahorro'),
  ('INVERSION', 'Inversión'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _saldoCtrl = TextEditingController();

  String _tipo = 'BANCARIA';
  String _moneda = 'COP';
  String _colorHex = '#5B5FEE';
  String _icono = 'account_balance_wallet';
  bool _loading = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _saldoCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    try {
      return Color(int.parse(_colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _C.accent;
    }
  }

  IconData get _iconData {
    for (final o in _kIconos) {
      if (o.value == _icono) return o.icon;
    }
    return Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          // ── AppBar ───────────────────────────────────────────────────
          Container(
            color: _C.surface,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 20,
              bottom: 12,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: _C.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Nueva Cuenta',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _C.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Formulario ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview card en vivo
                    _PreviewCard(
                      nombre: _nombreCtrl.text.trim().isEmpty
                          ? 'Nombre de la cuenta'
                          : _nombreCtrl.text.trim(),
                      tipo: _tipo,
                      moneda: _moneda,
                      saldo: double.tryParse(_saldoCtrl.text.trim()) ?? 0,
                      colorHex: _colorHex,
                      iconData: _iconData,
                    ),

                    const SizedBox(height: 28),

                    // ─ Información ──────────────────────────────────
                    _SectionLabel(label: 'Información'),
                    const SizedBox(height: 12),

                    // Nombre
                    _Field(
                      controller: _nombreCtrl,
                      label: 'Nombre de la cuenta',
                      hint: 'Ej: Banco Principal',
                      icon: Icons.drive_file_rename_outline_rounded,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        if (v.trim().length < 2) {
                          return 'Mínimo 2 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Saldo inicial
                    _Field(
                      controller: _saldoCtrl,
                      label: 'Saldo inicial',
                      hint: '0',
                      icon: Icons.attach_money_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          final n = double.tryParse(v);
                          if (n == null) return 'Número inválido';
                          if (n < 0) return 'No puede ser negativo';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // ─ Tipo de cuenta ────────────────────────────────
                    _SectionLabel(label: 'Tipo de cuenta'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kTipos.map((t) {
                        final sel = _tipo == t.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _tipo = t.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _C.accent
                                  : _C.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? _C.accent : _C.border,
                              ),
                            ),
                            child: Text(
                              t.$2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : _C.textSub,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // ─ Moneda ────────────────────────────────────────
                    _SectionLabel(label: 'Moneda'),
                    const SizedBox(height: 12),
                    _MonedaDropdown(
                      value: _moneda,
                      onChanged: (v) => setState(() => _moneda = v),
                    ),

                    const SizedBox(height: 28),

                    // ─ Personalización ───────────────────────────────
                    _SectionLabel(label: 'Personalización'),
                    const SizedBox(height: 16),

                    // Color
                    Text(
                      'Color',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textSub,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _kColores.map((c) {
                        final sel = _colorHex == c.hex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _colorHex = c.hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? _C.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: c.color
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: sel
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Icono
                    Text(
                      'Icono',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textSub,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: _kIconos.length,
                      itemBuilder: (_, i) {
                        final opt = _kIconos[i];
                        final sel = _icono == opt.value;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _icono = opt.value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _accentColor.withValues(alpha: 0.12)
                                  : _C.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel ? _accentColor : _C.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  opt.icon,
                                  size: 24,
                                  color: sel
                                      ? _accentColor
                                      : _C.textSub,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? _accentColor
                                        : _C.textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // ─ Descripción ───────────────────────────────────
                    _SectionLabel(label: 'Notas (opcional)'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _C.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Añade notas sobre esta cuenta…',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _C.textSub,
                        ),
                        filled: true,
                        fillColor: _C.surface,
                        contentPadding: const EdgeInsets.all(16),
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
                          borderSide: BorderSide(
                              color: _accentColor, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─ Botones ───────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color: _C.bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _C.border),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _C.textSub,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _loading ? null : _handleCreate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                color:
                                    _loading ? _C.accent.withValues(alpha: 0.6) : _C.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Crear Cuenta',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final request = CreateCuentaRequest(
        nombre: _nombreCtrl.text.trim(),
        tipo: _tipo,
        moneda: _moneda,
        saldoInicial: _saldoCtrl.text.trim().isEmpty
            ? 0
            : (double.tryParse(_saldoCtrl.text.trim()) ?? 0),
        color: _colorHex,
        icono: _icono,
        descripcion: _descripcionCtrl.text.trim().isNotEmpty
            ? _descripcionCtrl.text.trim()
            : null,
      );

      await ref
          .read(accountsNotifierProvider.notifier)
          .createAccount(request);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Cuenta creada exitosamente',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: _C.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: _C.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Preview Card ─────────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final String nombre;
  final String tipo;
  final String moneda;
  final double saldo;
  final String colorHex;
  final IconData iconData;

  const _PreviewCard({
    required this.nombre,
    required this.tipo,
    required this.moneda,
    required this.saldo,
    required this.colorHex,
    required this.iconData,
  });

  Color get _color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _C.accent;
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'BANCARIA':
        return 'Bancaria';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'TARJETA_CREDITO':
        return 'T. Crédito';
      case 'TARJETA_DEBITO':
        return 'T. Débito';
      case 'DIGITAL':
        return 'Digital';
      case 'AHORRO':
        return 'Ahorro';
      case 'INVERSION':
        return 'Inversión';
      default:
        return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _color;
    final fmt = NumberFormat('#,###', 'es_CO');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Vista previa',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.textSub,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Franja lateral animada
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 4,
                    color: accentColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          // Icono
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconData,
                                color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _C.primary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    _SmallBadge(
                                        label: _typeLabel(tipo),
                                        color: accentColor),
                                    const SizedBox(width: 6),
                                    _SmallBadge(
                                        label: moneda,
                                        color: _C.textSub,
                                        subtle: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Saldo
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Saldo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: _C.textSub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${fmt.format(saldo.toInt())}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _C.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;
  const _SmallBadge(
      {required this.label, required this.color, this.subtle = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: subtle
              ? _C.bg
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: subtle
                ? _C.border
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: subtle ? _C.textSub : color,
          ),
        ),
      );
}

// ─── Reusable field ───────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _C.primary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: _C.textSub,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: _C.textSub.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: _C.surface,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, size: 18, color: _C.textSub),
        ),
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _C.primary,
        ),
      );
}

// ─── Moneda dropdown ──────────────────────────────────────────────────────────
class _MonedaDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _MonedaDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final codigos = MonedasConstants.codigosUnicos;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.unfold_more_rounded,
            size: 18, color: _C.textSub),
        dropdownColor: _C.surface,
        borderRadius: BorderRadius.circular(14),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _C.primary,
        ),
        items: codigos.map((codigo) {
          final info = MonedasConstants.getMonedaPorCodigo(codigo);
          final paises = MonedasConstants.getMonedasPorPais(
              info?.pais ?? '');
          final display = paises.length > 1
              ? '$codigo — ${paises.map((m) => m.pais).join(', ')}'
              : info != null
                  ? '$codigo — ${info.pais}'
                  : codigo;
          return DropdownMenuItem<String>(
            value: codigo,
            child: Text(
              display,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _C.primary,
              ),
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ─── Helper classes (kept for compatibility) ──────────────────────────────────
class ColorOption {
  final String value;
  final String name;
  final Color actualColor;
  ColorOption(this.value, this.name, this.actualColor);
}

class IconOption {
  final String value;
  final String label;
  final IconData icon;
  IconOption(this.value, this.label, this.icon);
}
