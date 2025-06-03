import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:littlecow/controller/bloc/auth/auth_event.dart';
import 'package:littlecow/controller/bloc/auth/auth_state.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/data/auth_repository.dart';
import 'package:watch_it/watch_it.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final  _authRepository = di<AuthRepository>();
  StreamSubscription? _tokenInvalidSubscription;
  
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    //on<AuthTokenRefresheRequested>(_onAuthTokenRefresheRequested);
    //on<AuthTokenExpired>(_onAuthTokenExpired);
  }

  /// Este método se encarga de verificar si el usuario ya está autenticado
  /// y emite el estado correspondiente.
  /// 
  /// 1. Comprueba si hay una sesión activa
  /// 2. Si hay sesión activa, obtiene el usuario actual y 
  /// empieza la verificación periódica del token [_startTokenVerification]
  /// 3. Si no hay sesión activa, emite un estado de no autenticado
  /// 4. Si hay un error, emite un estado de error
  /// 
  /// Parametros:
  /// - [event] : Evento de verificación de autenticación
  /// - [emit] : Función para emitir nuevos estados
    FutureOr<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final isAuthenticated = await _authRepository.hasActiveSession();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } 
      }else{
        emit(const AuthUnauthenticated(message: ''));
      }
    }on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(),error: error));
    }
  }

  /// Este método se encarga de iniciar sesión y emite el estado correspondiente.
  /// 
  /// 1. Intenta iniciar sesión con las credenciales proporcionadas
  /// 2. Si el inicio de sesión es exitoso, obtiene el usuario actual y 
  /// empieza la verificación periódica del token con [_startTokenVerification] 
  /// 3. Si el inicio de sesión falla, emite un estado de error
  /// 4. Si hay un error, emite un estado de error
  /// 
  /// Parametros:
  /// [event] : Evento de inicio de sesión
  /// [emit] : Función para emitir nuevos estados
  ///  
  /// Método auxiliar para convertir excepciones en estados de fallo de autenticación
  /// Este método centraliza el manejo de excepciones para evitar repetir código

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
      emit(AuthUnauthenticated(message: error.toString(),error: error));
    }
  }

  /// Este método se encarga de cerrar sesión y emite el estado correspondiente.
  /// 
  /// 1. Intenta cerrar sesión
  /// 2. Si el cierre de sesión es exitoso, detiene la verificación del token
  /// 3. Si el cierre de sesión falla, emite un estado de error
  /// 4. Detiene la verificación del token con [_stopTokenVerification]
  /// 
  /// Parametros:
  /// [event] : Evento de cierre de sesión
  /// [emit] : Función para emitir nuevos estados
  /// 
  FutureOr<void> _onAuthLoggedOut(
      AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated(message: ''));
    }on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(),error: error));
    }
  }
  /*Future<void> _onAuthTokenRefresheRequested (AuthTokenRefresheRequested event,Emitter<AuthState> emit) async {
    emit(AuthLoading());
    async {
      final user = await _authRepository.refreshToken();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated(message: 'Token no pudo ser refrescado'));
      }
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(),error: error));
    }
  }*/

  @override
  Future<void> close() {
    _tokenInvalidSubscription?.cancel();
    _authRepository.dispose();
    return super.close();
  }
}