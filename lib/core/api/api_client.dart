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
          final options = error.requestOptions;
          final isAuthCall = options.path.contains('/api/auth/');
          if (error.response?.statusCode == 401 &&
              !isAuthCall &&
              options.extra['retried'] != true) {
            // Access token vencido: renovar con el refresh token y reintentar
            final data = await refreshSession();
            if (data != null) {
              options.extra['retried'] = true;
              options.headers['Authorization'] =
                  'Bearer ${data['accessToken']}';
              try {
                return handler.resolve(await dio.fetch(options));
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
            await storage.delete(key: 'accessToken');
          }
          handler.next(error);
        },
      ),
    );
  }

  static const _refreshKey = 'refreshToken';

  // Varias peticiones pueden recibir 401 a la vez; el servidor rota el refresh
  // token en cada uso, así que solo debe haber una renovación en curso.
  static Future<Map<String, dynamic>?>? _refreshing;

  /// Pide un par de tokens nuevo con el refresh token guardado. Devuelve la
  /// respuesta de `/api/auth/refresh` (accessToken, refreshToken, user) o null
  /// si no hay sesión que renovar.
  Future<Map<String, dynamic>?> refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<Map<String, dynamic>?> _doRefresh() async {
    final refresh = await storage.read(key: _refreshKey);
    if (refresh == null) return null;
    try {
      // Dio aparte: sin interceptores, para no entrar en bucle
      final res = await Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
        ),
      ).post('/api/auth/refresh', data: {'refreshToken': refresh});
      final data = Map<String, dynamic>.from(res.data as Map);
      await saveSession(
        data['accessToken'] as String,
        data['refreshToken'] as String?,
      );
      return data;
    } on DioException catch (e) {
      // 401: sesión revocada o vencida. Otros errores (red) conservan el token.
      if (e.response?.statusCode == 401) {
        await storage.delete(key: _refreshKey);
      }
      return null;
    }
  }

  Future<void> saveSession(String accessToken, String? refreshToken) async {
    await storage.write(key: 'accessToken', value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<String?> readRefreshToken() => storage.read(key: _refreshKey);

  // Método para guardar el token
  Future<void> setAuthToken(String token) async {
    await storage.write(key: 'accessToken', value: token);
  }

  // Método para eliminar el token (logout)
  Future<void> clearAuthToken() async {
    await storage.delete(key: 'accessToken');
    await storage.delete(key: _refreshKey);
  }

  // Verificar si hay token guardado
  Future<bool> hasToken() async {
    final token = await storage.read(key: 'accessToken');
    return token != null;
  }

  // Getter para acceder a la URL base
  String get apiBaseUrl => AppConfig.apiBaseUrl;
}
