import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/models/auth_models.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  // Registro de usuario
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Guardar el token
      await apiClient.setAuthToken(authResponse.accessToken);

      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('El email ya está registrado');
      }
      throw Exception(
        'Error al registrar: ${e.response?.data['message'] ?? e.message}',
      );
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  // Inicio de sesión
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Guardar el token
      await apiClient.setAuthToken(authResponse.accessToken);

      return authResponse;
    } on DioException catch (e) {
      // Manejo específico de errores de conexión
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Tiempo de espera agotado. Verifica que el backend esté corriendo en ${apiClient.apiBaseUrl}',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'No se pudo conectar al servidor. Verifica:\n'
          '1. Que el backend esté corriendo\n'
          '2. Que la URL sea correcta: ${apiClient.apiBaseUrl}\n'
          '3. Si usas dispositivo físico, usa tu IP en lugar de localhost',
        );
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      }

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Error desconocido';
      throw Exception('Error al iniciar sesión: $errorMessage');
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await apiClient.clearAuthToken();
    } catch (_) {
      // Ignorar errores al limpiar el token en caso de almacenamiento local inaccesible.
    }
  }

  // Verificar si hay sesión activa
  Future<bool> isLoggedIn() async {
    return await apiClient.hasToken();
  }

  // Guardar credenciales
  Future<void> saveCredentials(String email, String password) async {
    await apiClient.storage.write(key: 'savedEmail', value: email);
    await apiClient.storage.write(key: 'savedPassword', value: password);
  }

  // Eliminar credenciales guardadas
  Future<void> clearCredentials() async {
    await apiClient.storage.delete(key: 'savedEmail');
    await apiClient.storage.delete(key: 'savedPassword');
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
