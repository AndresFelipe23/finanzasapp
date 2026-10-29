class RegisterRequest {
  final String nombre;
  final String email;
  final String password;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final String? monedaPredeterminada;

  RegisterRequest({
    required this.nombre,
    required this.email,
    required this.password,
    this.telefono,
    this.fechaNacimiento,
    this.monedaPredeterminada,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'email': email,
    'password': password,
    if (telefono != null) 'telefono': telefono,
    if (fechaNacimiento != null)
      'fechaNacimiento': fechaNacimiento?.toIso8601String(),
    if (monedaPredeterminada != null)
      'monedaPredeterminada': monedaPredeterminada,
  };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserResponse user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
    user: UserResponse.fromJson(json['user']),
  );
}

class UserResponse {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final DateTime? fechaNacimiento;
  final String? monedaPredeterminada;

  UserResponse({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.fechaNacimiento,
    this.monedaPredeterminada,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    nombre: json['nombre'],
    email: json['email'],
    telefono: json['telefono'],
    fechaNacimiento: json['fechaNacimiento'] != null
        ? DateTime.parse(json['fechaNacimiento'])
        : null,
    monedaPredeterminada: json['monedaPredeterminada'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'telefono': telefono,
    'fechaNacimiento': fechaNacimiento?.toIso8601String(),
    'monedaPredeterminada': monedaPredeterminada,
  };
}
