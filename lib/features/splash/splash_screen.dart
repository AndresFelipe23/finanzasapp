import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import '../../core/navigation/main_navigation.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/brand_mark.dart';
import '../onboarding/welcome_screen.dart';
import '../auth/auth_service.dart';
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
    // Un mínimo breve para que el logo no parpadee; el resto del tiempo es
    // lo que tarde en revisar la sesión (antes era una espera fija de 2 s)
    final minimo = Future.delayed(const Duration(milliseconds: 900));
    try {
      await minimo;
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

      if (onboardingCompleted != 'true') {
        // Primera vez: bienvenida → onboarding → registro
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
        return;
      }

      // "Recordarme" sin huella: renovar la sesión y entrar directo. Con la
      // huella activada se pasa por el login, que la pide de inmediato.
      final auth = AuthService(ApiClient());
      if (await auth.rememberSession() && !await auth.biometricLoginEnabled()) {
        final session = await auth.restoreSession();
        if (session != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainNavigation(user: session.user),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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

/// Logo del diseño sobre el verde profundo de la bienvenida (mismo color que
/// el arranque nativo de Android, para que no haya salto de color).
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    // Stack a pantalla completa: el logo queda en el centro exacto y el
    // indicador de carga abajo, sin que uno empuje al otro
    return Scaffold(
      backgroundColor: Brand.deep,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // El mismo logo que el ícono de la app
                    const BrandMark(size: 84, background: Brand.deepCard),
                    const SizedBox(height: 18),
                    Text(
                      'Financially',
                      textAlign: TextAlign.center,
                      style: Brand.title(size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tus finanzas, claras y bajo control',
                      textAlign: TextAlign.center,
                      style: Brand.text(size: 14, color: Brand.deepText),
                    ),
                  ],
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Brand.mint,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
