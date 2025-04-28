import 'package:equatable/equatable.dart';


abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String name;
  final String password;

  const AuthLoginRequested({required this.name, required this.password});
}

class AuthLogoutRequested extends AuthEvent {
  final String refreshToken;

  const AuthLogoutRequested({required this.refreshToken});
}