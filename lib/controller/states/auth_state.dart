import 'package:littlecow/model/user_model.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthInProgress extends AuthState {
  const AuthInProgress();
}

class AuthLoginSuccess extends AuthState {
  final User user;
  final String token;

  const AuthLoginSuccess({required this.user, required this.token});
}
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});
}