import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:littlecow/controller/events/auth_event.dart';
import 'package:littlecow/controller/states/auth_state.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/data/auth_repository.dart';
import 'package:watch_it/watch_it.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final  _authRepository = di<AuthRepository>();
  StreamSubscription? _tokenInvalidSubscription;
  Timer? _tokenVerificationTimer;
  
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthTokenInvalidated>(_onAuthTokenInvalidated);
    _tokenInvalidSubscription = _authRepository.onTokenInvalid.listen((_) {
      add(AuthTokenInvalidated());
    });
  }
  /// Verificación periódica del token
  /// 
  /// 1. Verifica si el token es válido cada minuto
  /// 2. Si el token no es válido, emite un evento de token invalidado y detiene el timer
  /// 3. Cancela cualquier timer existente antes de crear uno nuevo [_stopTokenVerification]
  /// 4. Solo verifica si el estado actual es AuthAuthenticated para evitar ciclos
  ///   
  void _startTokenVerification() {
    if (state is !AuthAuthenticated) {
      return;
    }
    _stopTokenVerification();
    _tokenVerificationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_tokenVerificationTimer != timer) {
        timer.cancel();
        return;
      }
      if (state is! AuthAuthenticated) {
        _stopTokenVerification();
        return;
      }
      
      debugPrint("Verificando token...");
      try {
        final tokenInfo = await _authRepository.getTokenInfo();
        if (tokenInfo == null || !tokenInfo.success) {
          debugPrint("Token inválido o no encontrado");
          _stopTokenVerification(); 
          add(AuthTokenInvalidated());
        }
      } catch (e) {
        debugPrint("Error al verificar el token: $e");
        _stopTokenVerification(); 
        add(AuthTokenInvalidated()); 
      }
    });
  }
  /// Detiene la verificación periódica del token y asegura que se cancele adecuadamente
  void _stopTokenVerification() {
    if (_tokenVerificationTimer != null) {
      debugPrint("Deteniendo timer de verificación de token");
      _tokenVerificationTimer!.cancel();
      _tokenVerificationTimer = null;
    }
  }

  AuthFailure _handleAuthException(dynamic e) {
    if (e is AuthException) {
      if (e.toString().toLowerCase().contains('credencial')) {
        return AuthFailure(message: e.toString(), errorType: AuthErrorType.invalidCredentials);
      } else if (e.toString().toLowerCase().contains('sesión') || 
                e.toString().toLowerCase().contains('sesion') || 
                e.toString().toLowerCase().contains('expir')) {
        return AuthFailure(message: e.toString(), errorType: AuthErrorType.sessionExpired);
      }
    } else if (e is NetworkException) {
      return AuthFailure(message: e.toString(), errorType: AuthErrorType.connectionError);
    }    
    return AuthFailure(message: e.toString(), errorType: AuthErrorType.unknown);
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
  /// 
  FutureOr<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    
    emit(AuthLoading());
    try {
      final isAuthenticated = await _authRepository.hasActiveSession();
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user));
          _startTokenVerification();
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(_handleAuthException(e));
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
          _startTokenVerification();
        } 
      } 
    } catch (e) {
      emit(_handleAuthException(e));
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
      _stopTokenVerification();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(_handleAuthException(e));
    }
  }
  
  /// Este método se encarga de manejar el evento de token inválido.
  /// 
  /// 1. Detiene INMEDIATAMENTE la verificación periódica del token
  /// 2. Solo procede si el estado actual no es ya AuthUnauthenticated para evitar ciclos
  /// 3. Emite un estado de error indicando que la sesión ha expirado
  /// 4. Limpia los tokens almacenados
  /// 5. Emite un estado de no autenticado para forzar la redirección al login
  /// 
  /// Parametros:
  /// [event] : Evento de token inválido
  /// [emit] : Función para emitir nuevos estados
  /// 
  FutureOr<void> _onAuthTokenInvalidated(
      AuthTokenInvalidated event, Emitter<AuthState> emit) async {
    _stopTokenVerification();
    emit(const AuthFailure(
      message: 'La sesión ha expirado. Por favor, inicie sesión nuevamente.',
      errorType: AuthErrorType.sessionExpired
    ));    
    try {
      await _authRepository.logout();
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
    emit(AuthUnauthenticated());
  }


  @override
  Future<void> close() {
    _tokenInvalidSubscription?.cancel();
    _stopTokenVerification();
    _authRepository.dispose();
    return super.close();
  }
}