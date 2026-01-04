import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _storage = const FlutterSecureStorage();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Gestiona tus Finanzas con Financially',
      description: 'Controla tus ingresos y gastos de manera fácil e intuitiva',
      animation: 'assets/animations/money.json',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF6366F1),
    ),
    OnboardingSlide(
      title: 'Categoriza Transacciones',
      description:
          'Organiza tus gastos por categorías y visualiza dónde se va tu dinero',
      animation: 'assets/animations/money.json',
      icon: Icons.category,
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingSlide(
      title: 'Establece Presupuestos',
      description:
          'Define presupuestos mensuales y mantén el control de tus gastos',
      animation: 'assets/animations/money.json',
      icon: Icons.pie_chart,
      color: const Color(0xFFEC4899),
    ),
    OnboardingSlide(
      title: 'Alcanza tus Metas',
      description: 'Crea metas financieras y ahorra para lograrlas',
      animation: 'assets/animations/money.json',
      icon: Icons.flag,
      color: const Color(0xFF10B981),
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _goToLogin() async {
    // Mark onboarding as completed
    await _storage.write(key: 'onboarding_completed', value: 'true');

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    slide: _slides[index],
                    isLast: index == _slides.length - 1,
                    onFinish: _goToLogin,
                  );
                },
              ),
            ),
            _buildPageIndicators(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      label: const Text(
                        'Anterior',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: _currentPage == _slides.length - 1
                        ? _goToLogin
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slides[_currentPage].color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1
                              ? 'Comenzar'
                              : 'Siguiente',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == _slides.length - 1
                              ? Icons.check
                              : Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _slides.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index
                  ? _slides[_currentPage].color
                  : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final String animation;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.animation,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingSlide slide;
  final bool isLast;
  final VoidCallback onFinish;

  const _OnboardingPage({
    required this.slide,
    required this.isLast,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            slide.color.withOpacity(0.1),
            slide.color.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Container decorado para la animación
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    slide.color.withOpacity(0.15),
                    slide.color.withOpacity(0.05),
                  ],
                ),
              ),
              child: Center(
                child: Lottie.asset(
                  slide.animation,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Icono decorativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: slide.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(slide.icon, size: 32, color: slide.color),
            ),
            const SizedBox(height: 32),
            // Título con estilo mejorado
            Text(
              slide.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: slide.color,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Descripción con mejor estilo
            Text(
              slide.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
