/// Configuración de la aplicación
/// 
/// Este archivo centraliza todas las configuraciones de la app,
/// incluyendo URLs del API, variables de entorno, etc.
class AppConfig {
  // URL base del API
  // Se puede configurar mediante:
  // 1. Variable de entorno: --dart-define=API_BASE_URL=https://api.example.com
  // 2. Archivo .env (futuro)
  // 3. Valor por defecto según el modo (debug/release)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiUrl,
  );

  // URL por defecto según el modo de compilación
  // En producción debería ser HTTPS
  static const String _defaultApiUrl = 
      bool.fromEnvironment('dart.vm.product')
          ? 'https://gestiondinero.site/' // Producción
          : 'http://localhost:3001/api'; // Desarrollo

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
  static const String privacyPolicyUrl = 'https://afesdev.github.io/financially/privacy-policy';
  static const String termsOfServiceUrl = 'https://afesdev.github.io/financially/terms-of-service';
  static const String supportEmail = developerEmail;

  // Verificar si estamos en modo producción
  static bool get isProduction => 
      bool.fromEnvironment('dart.vm.product');

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

