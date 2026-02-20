import 'package:equatable/equatable.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/models/user_model.dart';

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
    this.error,
    required this.message,
  });

  @override
  List<Object?> get props => [message, error];
}
