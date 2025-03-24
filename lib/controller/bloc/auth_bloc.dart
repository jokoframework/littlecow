import 'package:bloc/bloc.dart';
import 'dart:developer' as developer;
import 'package:equatable/equatable.dart';

import '../../model/user_model.dart';
import '../events/auth_event.dart';
import '../states/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
    on<LogoutEvent>(_onLogoutEvent);
  }

  void _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) {
    developer.log('LoginEvent triggered', name: 'AuthBloc');
    // Aquí usarías datos mock
    emit(Authenticated(user: User(name: event.username)));
    developer.log('Authenticated state emitted', name: 'AuthBloc');
  }

  void _onLogoutEvent(LogoutEvent event, Emitter<AuthState> emit) {
    developer.log('LogoutEvent triggered', name: 'AuthBloc');
    emit(AuthInitial());
    developer.log('AuthInitial state emitted', name: 'AuthBloc');
  }
}