import 'package:equatable/equatable.dart';

/// Eventos relacionados a la autenticación
/// 
/// [AuthCheckRequested] - Cuando se solicita verificar el estado de autenticación.
/// [AuthLoggedIn] - Cuando el usuario intenta iniciar sesion.
/// [AuthLoggedOut] - Cuando el usuario solicita cerrar sesion.
/// [AuthTokenInvalidated] - Para invalidar el token de autenticación.

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
/// Evento para solicitar el cierre de sesión
class AuthLoggedOut extends AuthEvent {}

/// Evento para invalidar el token de autenticación
class AuthTokenInvalidated extends AuthEvent {}