import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_event.dart';
import 'package:littlecow/controller/bloc/auth/auth_state.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/data/auth_repository.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_bloc.dart';
import 'package:littlecow/controller/bloc/user_activity/user_activity_state.dart';
import 'package:watch_it/watch_it.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _authRepository = di<AuthRepository>();
  StreamSubscription? _onUserActivitySubscription;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthTokenRefresheRequested>(_onAuthTokenRefresheRequested);
    on<AuthUserInactivityDetected>(_onAuthUserInactivityDetected);
    on<AuthErrorFromBloc>(_onAuthErrorFromBloc);
  }

  void listenToUserActivity(UserActivityBloc userActivityBloc) {
    _onUserActivitySubscription?.cancel();
    _onUserActivitySubscription =
        userActivityBloc.stream.listen((userActivityState) {
      if (userActivityState is UserActivityInactive &&
          state is AuthAuthenticated) {
        add(AuthUserInactivityDetected());
      }
    });
  }

  FutureOr<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    try {
      final isAuthenticated = await _authRepository.hasActiveSession();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(const AuthUnauthenticated(message: ''));
      }
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: '', error: error));
    }
  }

  FutureOr<void> _onAuthLoggedIn(
      AuthLoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final loginResponse = await _authRepository.login(
        event.username,
        event.password,
      );
      if (loginResponse.success) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        }
      }
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    }
  }

  FutureOr<void> _onAuthLoggedOut(
      AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated(message: ''));
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: '', error: error));
    }
  }

  FutureOr<void> _onAuthTokenRefresheRequested(
      AuthTokenRefresheRequested event, Emitter<AuthState> emit) async {
    try {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        emit(AuthLoading());
        final accessToken = await _authRepository.refreshAccessToken();
        if (accessToken != null) {
          final user = await _authRepository.getCurrentUser();
          if (user != null) {
            emit(AuthAuthenticated(user));
          } else {
            emit(const AuthUnauthenticated(
                message: 'No se pudo obtener la información del usuario'));
          }
        } else {
          emit(const AuthUnauthenticated(
              message: 'No se pudo refrescar el token de autenticación'));
        }
      }
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    }
  }

  FutureOr<void> _onAuthUserInactivityDetected(
      AuthUserInactivityDetected event, Emitter<AuthState> emit) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) {
      return;
    }
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated(
          message: 'Tu sesión ha cerrado por inactividad'));
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    } catch (e) {
      emit(AuthUnauthenticated(
          message: 'Error inesperado al cerrar sesión: $e'));
    }
  }

  FutureOr<void> _onAuthErrorFromBloc(
      AuthErrorFromBloc event, Emitter<AuthState> emit) async {
    final errorMessage = event.error.toLowerCase();
    final isAuthError = errorMessage.contains('401') ||
        errorMessage.contains('no autorizado') ||
        errorMessage.contains('credenciales') ||
        errorMessage.contains('sesión') ||
        errorMessage.contains('expirado') ||
        errorMessage.contains('token');

    final isConnectionError = errorMessage.contains('conexión') ||
        errorMessage.contains('internet') ||
        errorMessage.contains('red') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('tiempo de espera');

    if (isAuthError || isConnectionError) {
      try {
        await _authRepository.logout();
      } catch (e) {
        emit(const AuthUnauthenticated(
            message:
                'La sesión ha expirado, por favor inicie sesión nuevamente'));
      } finally {
        emit(AuthUnauthenticated(
            message: isAuthError
                ? 'La sesión ha expirado, por favor inicie sesión nuevamente'
                : 'Error de conexión, por favor inicie sesión nuevamente'));
      }
    } else {
      emit(AuthUnauthenticated(message: event.error));
    }
  }

  @override
  Future<void> close() {
    _onUserActivitySubscription?.cancel();
    _authRepository.dispose();
    return super.close();
  }
}
