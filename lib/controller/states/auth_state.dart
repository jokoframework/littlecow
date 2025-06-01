import 'package:equatable/equatable.dart';
import 'package:littlecow/models/user_model.dart';
///Estados posibles para el manejo de la autenticación.
///
/// [AuthInitial] - Estado inicial de la autenticación.
/// [AuthLoading] - Estado de carga, cuando se está procesando la autenticación.
/// [AuthAuthenticated] - Estado cuando el usuario ha sido autenticado.
/// [AuthUnauthenticated] - Estado cuando el usuario no está autenticado.
/// [AuthFailure] - Estado de error, cuando ocurre un problema durante la autenticación.

/// Tipos de errores de autenticación
enum AuthErrorType {
  invalidCredentials,
  sessionExpired,
  connectionError,
  unknown
}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  final AuthErrorType errorType;

  const AuthFailure({
    required this.message, 
    this.errorType = AuthErrorType.unknown,
  });

  @override
  List<Object> get props => [message, errorType];
}