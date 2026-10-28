/// Configuración de la aplicación
///
/// Este archivo centraliza todas las configuraciones de la app,
/// incluyendo URLs del API, variables de entorno, etc.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Inicializar configuración desde .env
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Si no se puede cargar .env, continuar sin él
      // La app funcionará con valores por defecto
    }
  }

  // URL base del API
  // Prioridad: .env > variable de entorno > valor por defecto
  static String get apiBaseUrl {
    try {
      // Intentar cargar desde .env primero
      if (dotenv.isInitialized && dotenv.env.containsKey('API_BASE_URL')) {
        final envUrl = dotenv.env['API_BASE_URL'];
        if (envUrl != null && envUrl.isNotEmpty) {
          return envUrl;
        }
      }
    } catch (e) {
      // Si hay error cargando .env, continuar con fallback
    }

    // Fallback: variable de entorno
    final envUrl = const String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Último fallback: valor por defecto según el modo
    return bool.fromEnvironment('dart.vm.product')
        ? 'https://gestiondinero.site/' // Producción
        : 'http://localhost:3001/api'; // Desarrollo
  }

  // Configuración de la app
  static const String appName = 'Financially';
  static const String appVersion = '1.0.0';
  static const String developerEmail = 'afesdev2025@gmail.com';
  static const String developerName = 'AFESDEV';

  // Timeouts de red
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Configuración de seguridad
  static const bool allowCleartextTraffic =
      bool.fromEnvironment('dart.vm.product') ? false : true;

  // URLs de documentación y soporte
  static const String privacyPolicyUrl =
      'https://afesdev.github.io/financially/privacy-policy';
  static const String termsOfServiceUrl =
      'https://afesdev.github.io/financially/terms-of-service';
  static const String supportEmail = developerEmail;

  // Verificar si estamos en modo producción
  static bool get isProduction => bool.fromEnvironment('dart.vm.product');

  // Verificar si estamos en modo debug
  static bool get isDebug => !isProduction;

  // Obtener la URL completa del API
  static String getApiUrl(String endpoint) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }
}
