import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/theme/neo_bank_theme.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  // Asegurar que Flutter esté inicializado para operaciones asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar configuración desde .env
  await AppConfig.initialize();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Manejo de errores global
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // En producción, puedes enviar el error a un servicio de logging
      debugPrint('Error en producción: ${details.exception}');
    }
  };

  // Manejo de errores de la plataforma
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Error de plataforma: $error');
    return true;
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Financially',
      theme: NeoBankTheme.lightTheme(),
      darkTheme: NeoBankTheme.darkTheme(),
      themeMode: ref.watch(themeModeProvider),
      // Configuración de localización en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (fallback)
      ],
      locale: const Locale('es', 'ES'),
      home: const SplashScreen(),
    );
  }
}
