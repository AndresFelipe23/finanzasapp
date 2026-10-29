import 'package:flutter/material.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_mark.dart';
import '../auth/login_screen.dart';
import 'onboarding_screen.dart';

/// Primera pantalla para quien abre la app sin haber visto el onboarding.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.deep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandLogo(),
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height * 0.55,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const _BalancePreview(),
                        const SizedBox(height: 28),
                        Text(
                          'Tus finanzas, claras y bajo control.',
                          style: Brand.title(size: 34, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Registra ingresos y gastos, arma presupuestos y '
                          'alcanza tus metas de ahorro, en tu propia moneda.',
                          style: Brand.text(
                            size: 16,
                            color: Brand.deepText,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              BrandButton(
                label: 'Crear cuenta gratis',
                background: Brand.mint,
                foreground: Brand.deep,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
              ),
              const SizedBox(height: 12),
              BrandOutlineButton(
                label: 'Ya tengo una cuenta',
                borderColor: Brand.deepBorder,
                foreground: Colors.white,
                onPressed: () async {
                  await markOnboardingSeen();
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.dark = true});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BrandMark(
          size: 40,
          // Sobre el verde profundo el cuadro va un tono más claro
          background: dark ? Brand.deepCard : Brand.deep,
        ),
        const SizedBox(width: 10),
        Text(
          'Financially',
          style: Brand.text(
            size: 20,
            weight: FontWeight.w800,
            color: dark ? Colors.white : Brand.ink,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta ilustrativa: es un ejemplo, no datos del usuario.
class _BalancePreview extends StatelessWidget {
  const _BalancePreview();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Brand.deepCard,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo total',
                  style: Brand.text(size: 13, color: Brand.deepText),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Brand.deep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+12% este mes',
                    style: Brand.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Brand.mint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '\$48.250',
              style: Brand.title(size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Misma curva del diseño (viewBox 294×72), escalada al ancho disponible
    final sx = size.width / 294, sy = size.height / 72;
    final path = Path()
      ..moveTo(0, 60 * sy)
      ..cubicTo(30 * sx, 56 * sy, 50 * sx, 40 * sy, 80 * sx, 44 * sy)
      ..cubicTo(110 * sx, 48 * sy, 130 * sx, 58 * sy, 160 * sx, 36 * sy)
      ..cubicTo(190 * sx, 14 * sy, 220 * sx, 30 * sy, 245 * sx, 18 * sy)
      ..cubicTo(270 * sx, 6 * sy, 280 * sx, 10 * sy, 294 * sx, 6 * sy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Brand.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
