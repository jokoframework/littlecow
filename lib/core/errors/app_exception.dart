abstract class AppException implements Exception {
  final String message;
  final dynamic details;
  
  const AppException({
    required this.message,
    this.details,
  });
  @override
  String toString() {
    return message;
  }
}

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.details,
  });
  
  factory AuthException.invalidCredentials() {
    return const AuthException(
      message: 'Credenciales inválidas',
    );
  }
  
  factory AuthException.sessionExpired() {
    return const AuthException(
      message: 'La sesión ha expirado',
    );
  }
  
  factory AuthException.networkError() {
    return const AuthException(
      message: 'Error de conexión',
    );
  }
  
  factory AuthException.unknown(dynamic error) {
    return AuthException(
      message: 'Error desconocido: ${error.toString()}',
      details: error,
    );
  }
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.details,
  });
  
  factory NetworkException.connectionTimeout() {
    return const NetworkException(
      message: 'Tiempo de espera agotado',
    );
  }
  
  factory NetworkException.noInternet() {
    return const NetworkException(
      message: 'No hay conexión a Internet',
      
    );
  }
  
  factory NetworkException.serverError(int statusCode) {
    return NetworkException(
      message: 'Error del servidor',
      details: 'Código de estado: $statusCode',
    );
  }
  
  factory NetworkException.unknown(dynamic error) {
    return NetworkException(
      message: 'Error de red desconocido',
      details: error,
    );
  }
}

class DataException extends AppException {
  const DataException({
    required super.message,
    super.details,
  });
  
  factory DataException.invalidData(String? details) {
    return DataException(
      message: 'Datos inválidos',
      details: details,
    );
  }
  
  factory DataException.missingData() {
    return const DataException(
      message: 'Datos faltantes',
    );
  }
  
  factory DataException.unknown(dynamic error) {
    return DataException(
      message: 'Error de datos desconocido',
      details: error,
    );
  }
}