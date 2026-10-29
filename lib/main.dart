import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/compras/compra_automatica.dart';
import 'core/notifications/notification_service.dart';
import 'core/quick_launch/quick_launch.dart';
import 'core/security/app_lock.dart';
import 'core/theme/neo_bank_theme.dart';
import 'features/quick_entry/quick_entry_app.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  // Asegurar que Flutter esté inicializado para operaciones asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar configuración desde .env
  await AppConfig.initialize();

  await NotificationService.instance.init();
  // Accesos directos del ícono y botones del widget de inicio
  await QuickLaunch.init();

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

/// Entrada de la hoja de registro rápido que abren los mosaicos de Ajustes
/// rápidos (`QuickEntryActivity.kt`): solo el formulario, sin splash ni
/// navegación. [args] trae el tipo ('GASTO' o 'INGRESO').
@pragma('vm:entry-point')
Future<void> quickEntryMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    ProviderScope(
      child: QuickEntryApp(
        tipo: args.firstOrNull == 'INGRESO' ? 'INGRESO' : 'GASTO',
      ),
    ),
  );
}

/// Entrada sin pantalla para las compras con tarjeta o con el teléfono que
/// detecta `PurchaseListenerService.kt` en las notificaciones de pago.
/// [args]: paquete de la app que avisó, título, texto y hora (ms).
@pragma('vm:entry-point')
Future<void> compraDetectadaMain(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('financially/compras');
  try {
    await AppConfig.initialize();
    await NotificationService.instance.init();
    if (args.length >= 4) {
      await CompraAutomatica.procesar(
        args[0],
        args[1],
        args[2],
        DateTime.fromMillisecondsSinceEpoch(int.tryParse(args[3]) ?? 0),
      );
    }
  } catch (e) {
    debugPrint('Compra detectada sin procesar: $e');
  } finally {
    // El servicio nativo libera el motor
    await canal.invokeMethod('terminado').catchError((_) => null);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Financially',
      // El diseño es solo de modo claro
      theme: NeoBankTheme.lightTheme(),
      themeMode: ThemeMode.light,
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
      // Sobre el Navigator para que el bloqueo cubra también las rutas apiladas
      builder: (context, child) => AppLockGate(child: child!),
      home: const SplashScreen(),
    );
  }
}
