import 'package:equatable/equatable.dart';

/// Eventos relacionados a la autenticación
/// 
/// [AuthCheckRequested] - Cuando se solicita verificar el estado de autenticación.
/// [AuthLoggedIn] - Cuando el usuario intenta iniciar sesion.
/// [AuthLoggedOut] - Cuando el usuario solicita cerrar sesion.
/// [AuthTokenInvalidated] - Para invalidar el token de autenticación.
/// [AuthUserInactivityDetected] - Cuando se detecta inactividad del usuario.

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}
/// Evento para verificar el estado de autenticación
class AuthCheckRequested extends AuthEvent {}

/// Evento para solicitar el inicio de sesión
/// 
/// [username] - Nombre de usuario. 
/// [password] - Contraseña del usuario.
class AuthLoggedIn extends AuthEvent {
  final String username;
  final String password;

  const AuthLoggedIn({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}
class AuthLoggedOut extends AuthEvent {}

class AuthTokenExpired extends AuthEvent {}

class AuthTokenRefresheRequested extends AuthEvent {}

class AuthUserInactivityDetected extends AuthEvent {}

/// Evento para manejar errores de autenticación desde otros blocs
/// 
/// [errorMessage] - Mensaje de error que se mostrará al usuario.
/// [isNetworkError] - Indica si el error es de red para redirigir a la pantalla adecuada.
class AuthErrorFromBloc extends AuthEvent {
  final String  error;
  
  const AuthErrorFromBloc({
    required this.error
  });
  
  @override
  List<Object> get props => [error];
}