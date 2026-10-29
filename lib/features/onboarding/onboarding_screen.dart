import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/monedas_constants.dart';
import '../auth/register_screen.dart';

const _onboardingKey = 'onboarding_completed';

/// Marca el onboarding como visto: la próxima vez el splash va al login.
Future<void> markOnboardingSeen() async {
  try {
    await const FlutterSecureStorage().write(
      key: _onboardingKey,
      value: 'true',
    );
  } catch (_) {
    // Si no persiste, en el peor caso se vuelve a mostrar la bienvenida
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: 'Controla tus gastos',
      body:
          'Tus cuentas bancarias, efectivo y tarjetas en un solo lugar. '
          'Registra cada ingreso y gasto en segundos.',
      art: _GastosArt(),
    ),
    (
      title: 'Presupuestos que funcionan',
      body:
          'Pon un límite a cada categoría y recibe un aviso antes de pasarte. '
          'Sin sorpresas a fin de mes.',
      art: _PresupuestosArt(),
    ),
    (
      title: 'Alcanza tus metas',
      body:
          'Ahorra para lo que importa y mira tu avance crecer, en la moneda '
          'de tu país.',
      art: _MetasArt(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToRegister() async {
    await markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _go(int page) => _pageController.animateToPage(
    page,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: Brand.deep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (_page > 0)
                      BrandBackButton(dark: true, onPressed: () => _go(_page - 1))
                    else
                      BrandBackButton(dark: true),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: _goToRegister,
                        style: TextButton.styleFrom(
                          foregroundColor: Brand.deepText,
                          minimumSize: const Size(44, 44),
                        ),
                        child: Text(
                          'Saltar',
                          style: Brand.text(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Brand.deepText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ExcludeSemantics(child: p.art),
                          const SizedBox(height: 28),
                          Text(
                            p.title,
                            style: Brand.title(size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.body,
                            style: Brand.text(
                              size: 16,
                              color: Brand.deepText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (last) ...[
                Center(child: _Dots(current: _page, count: _pages.length)),
                const SizedBox(height: 18),
                BrandButton(
                  label: 'Empezar',
                  background: Brand.mint,
                  foreground: Brand.deep,
                  onPressed: _goToRegister,
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Dots(current: _page, count: _pages.length),
                    BrandButton(
                      label: 'Siguiente',
                      background: Brand.mint,
                      foreground: Brand.deep,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      onPressed: () => _go(_page + 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${current + 1} de $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == current ? Brand.mint : Brand.deepBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

/* ── Ilustraciones (ejemplos, no datos del usuario) ── */

class _ArtCard extends StatelessWidget {
  const _ArtCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Brand.deepCard,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _GastosArt extends StatelessWidget {
  const _GastosArt();

  Widget _row(String initial, String name, String cat, String amount, bool income) {
    final fg = income ? Brand.mint : Brand.peach;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Brand.deep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: income ? Brand.deepMintBg : Brand.deepPeachBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initial,
              style: Brand.text(weight: FontWeight.w800, color: fg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Brand.text(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(cat, style: Brand.text(size: 12, color: Brand.deepText)),
              ],
            ),
          ),
          Text(
            amount,
            style: Brand.text(size: 14, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Brand.deep,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: Brand.text(size: 12, weight: FontWeight.w700, color: Brand.deepText),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _ArtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hoy',
                style: Brand.text(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '3 movimientos',
                style: Brand.text(size: 13, color: Brand.deepText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('S', 'Supermercado', 'Alimentación', '−\$84.000', false),
          _row('N', 'Nómina', 'Salario', '+\$2.400.000', true),
          _row('T', 'Transporte', 'Movilidad', '−\$12.000', false),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Cuenta bancaria'),
              _chip('Efectivo'),
              _chip('Tarjetas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresupuestosArt extends StatelessWidget {
  const _PresupuestosArt();

  Widget _bar(String label, int pct) {
    final warn = pct >= 90;
    final color = warn ? Brand.peach : Brand.mint;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Brand.text(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '$pct%',
                style: Brand.text(
                  size: 13,
                  weight: warn ? FontWeight.w700 : FontWeight.w500,
                  color: warn ? Brand.peach : Brand.deepText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              color: color,
              backgroundColor: Brand.deep,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ArtCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Este mes',
                    style: Brand.text(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '68% usado',
                    style: Brand.text(size: 13, color: Brand.deepText),
                  ),
                ],
              ),
              _bar('Comida', 81),
              _bar('Transporte', 57),
              _bar('Ocio', 94),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Brand.expenseSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 18,
                    color: Brand.expense,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Casi llegas al límite',
                        style: Brand.text(size: 14, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Te queda el 6% de Ocio este mes.',
                        style: Brand.text(
                          size: 13,
                          color: Brand.muted,
                          height: 1.4,
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
    );
  }
}

class _MetasArt extends StatelessWidget {
  const _MetasArt();

  @override
  Widget build(BuildContext context) {
    // Algunas monedas de la lista real, para mostrar que hay varias
    const muestra = ['COP', 'MXN', 'ARS', 'CLP', 'PEN', 'EUR'];
    final codigos = MonedasConstants.monedasHispanas
        .map((m) => m.codigo)
        .toSet();

    return Column(
      children: [
        _ArtCard(
          child: Column(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _RingPainter(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '70%',
                          style: Brand.text(
                            size: 30,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'ahorrado',
                          style: Brand.text(
                            size: 13,
                            weight: FontWeight.w600,
                            color: Brand.deepText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Viaje de vacaciones',
                style: Brand.text(
                  size: 17,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '70% de la meta',
                style: Brand.text(size: 13, color: Brand.deepText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, c) in muestra.where(codigos.contains).indexed)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: i == 0 ? Brand.mint : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: i == 0
                      ? null
                      : Border.all(color: Brand.deepBorder, width: 1.5),
                ),
                child: Text(
                  c,
                  style: Brand.text(
                    size: 13,
                    weight: i == 0 ? FontWeight.w800 : FontWeight.w700,
                    color: i == 0 ? Brand.deep : Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 7;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = Brand.deep;
    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      base
        ..color = Brand.mint
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
