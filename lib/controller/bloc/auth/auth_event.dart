import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

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

class AuthErrorFromBloc extends AuthEvent {
  final String error;

  const AuthErrorFromBloc({required this.error});

  @override
  List<Object> get props => [error];
}
