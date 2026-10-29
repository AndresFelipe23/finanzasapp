import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta del diseño "Financially · App móvil" (superficies sólidas, Manrope).
class Brand {
  Brand._();

  // Claro
  static const bg = Color(0xFFF4F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF10201B);
  static const muted = Color(0xFF5A6762);
  static const placeholder = Color(0xFF7A8681);
  static const border = Color(0xFFE3E6E0);
  static const inputBorder = Color(0xFFD5DAD3);
  static const track = Color(0xFFE9ECE6);
  static const accent = Color(0xFF0B6E4F);
  static const accentDark = Color(0xFF084E38);
  static const accentSoft = Color(0xFFE3F0EA);
  static const expense = Color(0xFFB4531A);
  static const expenseSoft = Color(0xFFF8E9DE);
  static const blue = Color(0xFF1F5FAD);
  static const blueSoft = Color(0xFFE6ECF6);

  // Pantallas de bienvenida y onboarding (verde profundo)
  static const deep = Color(0xFF0B3B2C);
  static const deepCard = Color(0xFF124A38);
  static const deepBorder = Color(0xFF3C7462);
  static const deepText = Color(0xFFB9D6C9);
  static const mint = Color(0xFF7FD1AE);
  static const peach = Color(0xFFF0A673);
  static const deepPeachBg = Color(0xFF3A2A1C);
  static const deepMintBg = Color(0xFF1D5A45);

  static TextStyle text({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle title({double size = 30, Color color = ink}) => text(
    size: size,
    weight: FontWeight.w800,
    color: color,
    height: 1.12,
    letterSpacing: -0.02 * size,
  );
}

/// Botón principal de 56 px del diseño.
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = Brand.accent,
    this.foreground = Colors.white,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: Brand.inputBorder,
          disabledForegroundColor: Brand.muted,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: Brand.text(size: 16, weight: FontWeight.w800),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (icon != null) ...[const SizedBox(width: 8), icon!],
                ],
              ),
      ),
    );
  }
}

/// Botón con borde de 56 px (variante secundaria).
class BrandOutlineButton extends StatelessWidget {
  const BrandOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = Brand.inputBorder,
    this.foreground = Brand.ink,
    this.background = Colors.transparent,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color foreground;
  final Color background;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: Brand.text(size: 16, weight: FontWeight.w700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Botón circular de 44 px para volver.
class BrandBackButton extends StatelessWidget {
  const BrandBackButton({super.key, this.onPressed, this.dark = false});

  final VoidCallback? onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? Colors.transparent : Brand.surface,
      shape: CircleBorder(
        side: BorderSide(
          color: dark ? Brand.deepBorder : Brand.border,
          width: dark ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.chevron_left_rounded,
            size: 26,
            color: dark ? Colors.white : Brand.ink,
            semanticLabel: 'Volver',
          ),
        ),
      ),
    );
  }
}

/// Campo de formulario con etiqueta arriba, como en el diseño.
class BrandField extends StatelessWidget {
  const BrandField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.autofillHints,
    this.validator,
    this.suffix,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Brand.text(size: 13, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: Brand.text(size: 15),
          cursorColor: Brand.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Brand.text(size: 15, color: Brand.placeholder),
            filled: true,
            fillColor: Brand.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffix,
            border: _border(Brand.inputBorder),
            enabledBorder: _border(Brand.inputBorder),
            focusedBorder: _border(Brand.accent, 1.5),
            errorBorder: _border(Brand.expense),
            focusedErrorBorder: _border(Brand.expense, 1.5),
            errorStyle: Brand.text(size: 12, color: Brand.expense),
          ),
        ),
      ],
    );
  }
}

void showBrandSnack(BuildContext context, String message, {bool error = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: Brand.text(color: Colors.white)),
      backgroundColor: error ? Brand.expense : Brand.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
