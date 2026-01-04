import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor de logging solo en modo debug
    if (AppConfig.isDebug) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            print('🌐 [API Request] ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              print('📤 [Request Data] ${options.data}');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            print('✅ [API Response] ${response.statusCode} ${response.requestOptions.path}');
            handler.next(response);
          },
          onError: (error, handler) {
            print('❌ [API Error] ${error.type}');
            print('   URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
            if (error.response != null) {
              print('   Status: ${error.response?.statusCode}');
              print('   Data: ${error.response?.data}');
            } else {
              print('   Message: ${error.message}');
            }
            handler.next(error);
          },
        ),
      );
    }

    // Interceptor para agregar el token JWT automáticamente
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expirado o inválido
            await storage.delete(key: 'accessToken');
          }
          handler.next(error);
        },
      ),
    );
  }

  // Método para guardar el token
  Future<void> setAuthToken(String token) async {
    await storage.write(key: 'accessToken', value: token);
  }

  // Método para eliminar el token (logout)
  Future<void> clearAuthToken() async {
    await storage.delete(key: 'accessToken');
  }

  // Verificar si hay token guardado
  Future<bool> hasToken() async {
    final token = await storage.read(key: 'accessToken');
    return token != null;
  }

  // Getter para acceder a la URL base
  String get apiBaseUrl => AppConfig.apiBaseUrl;
}
