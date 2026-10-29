import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/api/api_client.dart';
import '../../core/home_widget/home_widget_sync.dart';
import '../../core/models/auth_models.dart';
import '../../core/notifications/notification_service.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  // Preferencias de sesión guardadas en el almacenamiento seguro
  static const _rememberKey = 'rememberSession';
  static const _emailKey = 'savedEmail';
  static const _biometricKey = 'biometricLogin';
  static const _biometricAskedKey = 'biometricAsked';
  // Versiones anteriores guardaban la contraseña; se borra al usar el servicio
  static const _legacyPasswordKey = 'savedPassword';

  String _message(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar al servidor. Revisa tu conexión e intenta de nuevo.';
    }
    final data = e.response?.data;
    final msg = data is Map ? data['message'] : null;
    if (msg is List && msg.isNotEmpty) return '${msg.first}';
    if (msg is String && msg.isNotEmpty) return msg;
    return fallback;
  }

  Future<AuthResponse> _persist(AuthResponse auth) async {
    await apiClient.saveSession(auth.accessToken, auth.refreshToken);
    return auth;
  }

  // Registro de usuario
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );
      return await _persist(AuthResponse.fromJson(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Ese correo ya tiene una cuenta. Inicia sesión.');
      }
      throw Exception(_message(e, 'No se pudo crear la cuenta'));
    }
  }

  // Inicio de sesión
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      return await _persist(AuthResponse.fromJson(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Correo o contraseña incorrectos');
      }
      throw Exception(_message(e, 'No se pudo iniciar sesión'));
    }
  }

  /// Renueva la sesión con el refresh token guardado. Null si no hay sesión.
  Future<AuthResponse?> restoreSession() async {
    final data = await apiClient.refreshSession();
    return data == null ? null : AuthResponse.fromJson(data);
  }

  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception('Demasiados intentos. Espera un minuto.');
      }
      throw Exception(_message(e, 'No se pudo enviar el correo'));
    }
  }

  // Cerrar sesión: revoca el refresh token en el servidor y borra la sesión
  Future<void> logout() async {
    try {
      final refresh = await apiClient.readRefreshToken();
      if (refresh != null) {
        await apiClient.dio.post(
          '/api/auth/logout',
          data: {'refreshToken': refresh},
        );
      }
    } catch (_) {
      // Sin red igual se cierra la sesión local
    }
    try {
      await apiClient.clearAuthToken();
      await apiClient.storage.delete(key: _rememberKey);
      // Con el refresh token revocado la huella ya no puede abrir sesión
      await apiClient.storage.delete(key: _biometricKey);
    } catch (_) {
      // Ignorar errores al limpiar el token en caso de almacenamiento local inaccesible.
    }
    // Sin sesión: el widget no muestra montos y no se registra desde la
    // notificación
    await HomeWidgetSync.clear();
    await NotificationService.instance.hideQuickRecord();
  }

  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    return await apiClient.hasToken();
  }

  /* ── Preferencias de la pantalla de inicio de sesión ── */

  Future<String?> savedEmail() => apiClient.storage.read(key: _emailKey);

  Future<bool> rememberSession() async =>
      await apiClient.storage.read(key: _rememberKey) == 'true';

  /// "Recordarme": guarda el correo y permite entrar sin contraseña al abrir
  /// la app. Nunca se guarda la contraseña.
  Future<void> setRemember(bool remember, String email) async {
    await apiClient.storage.delete(key: _legacyPasswordKey);
    if (remember) {
      await apiClient.storage.write(key: _emailKey, value: email);
      await apiClient.storage.write(key: _rememberKey, value: 'true');
    } else {
      await apiClient.storage.delete(key: _emailKey);
      await apiClient.storage.delete(key: _rememberKey);
    }
  }

  /* ── Entrar con huella o Face ID ── */

  Future<bool> biometricAvailable() async {
    try {
      final auth = LocalAuthentication();
      return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// La huella solo sirve si quedó una sesión que renovar.
  Future<bool> biometricLoginEnabled() async =>
      await apiClient.storage.read(key: _biometricKey) == 'true' &&
      await apiClient.readRefreshToken() != null;

  Future<void> setBiometricLogin(bool enabled) async {
    await apiClient.storage.write(key: _biometricAskedKey, value: 'true');
    if (enabled) {
      await apiClient.storage.write(key: _biometricKey, value: 'true');
    } else {
      await apiClient.storage.delete(key: _biometricKey);
    }
  }

  Future<bool> shouldOfferBiometric() async =>
      await apiClient.storage.read(key: _biometricAskedKey) != 'true' &&
      await biometricAvailable();

  /// Verifica la huella y, si pasa, renueva la sesión guardada.
  Future<AuthResponse?> loginWithBiometrics() async {
    final bool ok;
    try {
      ok = await LocalAuthentication().authenticate(
        localizedReason: 'Entra a Financially con tu huella o rostro',
        biometricOnly: true,
      );
    } catch (e) {
      debugPrint('Error de autenticación biométrica: $e');
      throw Exception('No se pudo usar la huella en este dispositivo');
    }
    if (!ok) return null;
    final session = await restoreSession();
    if (session == null) {
      await apiClient.storage.delete(key: _biometricKey);
      throw Exception(
        'Tu sesión expiró. Inicia sesión con tu contraseña para volver a activar la huella.',
      );
    }
    return session;
  }

  // Actualizar perfil del usuario
  Future<UserResponse> updateProfile({
    required String nombre,
    String? telefono,
    DateTime? fechaNacimiento,
    String? monedaPredeterminada,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        '/api/auth/profile',
        data: {
          'nombre': nombre,
          if (telefono != null) 'telefono': telefono,
          if (fechaNacimiento != null)
            'fechaNacimiento': fechaNacimiento.toIso8601String(),
          if (monedaPredeterminada != null)
            'monedaPredeterminada': monedaPredeterminada,
        },
      );

      return UserResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Error al actualizar perfil: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }
}
