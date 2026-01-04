import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Check if onboarding has been completed
      String? onboardingCompleted;
      try {
        onboardingCompleted = await _storage.read(key: 'onboarding_completed');
      } catch (e) {
        // Si hay error leyendo el storage, asumimos que es primera vez
        debugPrint('Error leyendo onboarding status: $e');
        onboardingCompleted = null;
      }

      if (!mounted) return;

      if (onboardingCompleted == 'true') {
        // User has already seen onboarding, go directly to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // First time user, show onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error en splash screen: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      // En caso de error, ir directamente al login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const _SplashView();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Builder(
          builder: (context) {
            try {
              return Lottie.asset(
                'assets/animations/loading.json',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Si falla cargar la animación, mostrar un indicador simple
                  return const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              // Fallback a un indicador simple
              return const SizedBox(
                width: 220,
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
