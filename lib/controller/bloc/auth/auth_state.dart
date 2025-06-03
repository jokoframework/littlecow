import 'package:equatable/equatable.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/models/user_model.dart';
///Estados posibles para el manejo de la autenticación.
///
/// [AuthInitial] - Estado inicial de la autenticación.
/// [AuthLoading] - Estado de carga, cuando se está procesando la autenticación.
/// [AuthAuthenticated] - Estado cuando el usuario ha sido autenticado.
/// [AuthUnauthenticated] - Estado de error, cuando ocurre un problema durante la autenticación.

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

class AuthUnauthenticated extends AuthState {
  final String message;
  final AppException? error;

  const AuthUnauthenticated({
    this.error, required this.message,
  });

  @override
  List<Object?> get props => [message,error];
}