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
  final  _authRepository = di<AuthRepository>();
  StreamSubscription? _onUserActivitySubscription;
  
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthTokenRefresheRequested>(_onAuthTokenRefresheRequested);
    on<AuthTokenExpired>(_onAuthTokenExpired);
    on<AuthUserInactivityDetected>(_onAuthUserInactivityDetected);
  }

  void listenToUserActivity(UserActivityBloc userActivityBloc) {
    // Cancela cualquier suscripción existente
    _onUserActivitySubscription?.cancel();
    
    // Configura una nueva suscripción para escuchar cambios futuros
    _onUserActivitySubscription = userActivityBloc.stream.listen((userActivityState) {
      // Solo nos interesa el estado UserActivityInactive cuando el usuario está autenticado
      if (userActivityState is UserActivityInactive && state is AuthAuthenticated) {
        print('🔑 AuthBloc: Detected inactivity while authenticated, adding AuthUserInactivityDetected');
        add(AuthUserInactivityDetected());
      }
    });
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
  

  /// Este método se encarga de refrescar el token de autenticación cuando sea necesario.
  /// 
  /// 1. Intenta refrescar el token de acceso
  /// 2. Si el refresco es exitoso, mantiene el estado de autenticación actual
  /// 3. Si el refresco falla, emite un estado de no autenticado
  /// 
  /// Parámetros:
  /// [event] : Evento de solicitud de refresco de token
  /// [emit] : Función para emitir nuevos estados
  /// 
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
            emit(const AuthUnauthenticated(message: 'No se pudo obtener la información del usuario'));
          }
        } else {
          emit(const AuthUnauthenticated(message: 'No se pudo refrescar el token de autenticación'));
        }
      }
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    }
  }

  /// Este método se encarga de manejar la expiración del token de autenticación.
  /// 
  /// 1. Notifica al usuario que la sesión ha expirado
  /// 2. Emite un estado de no autenticado
  /// 
  /// Parámetros:
  /// [event] : Evento de expiración de token
  /// [emit] : Función para emitir nuevos estados
  /// 
  FutureOr<void> _onAuthTokenExpired(
      AuthTokenExpired event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated(message: 'Su sesión ha expirado, por favor inicie sesión nuevamente'));
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    }
  }

  /// Este método se encarga de manejar la inactividad del usuario.
  /// 
  /// 1. Cierra la sesión del usuario si está inactivo
  /// 2. Emite un estado de no autenticado
  /// 
  /// Parámetros:
  /// [event] : Evento de detección de inactividad del usuario
  /// [emit] : Función para emitir nuevos estados
  /// 
  FutureOr<void> _onAuthUserInactivityDetected(
      AuthUserInactivityDetected event, Emitter<AuthState> emit) async {
    // Verificamos primero que estemos en un estado autenticado
    final currentState = state;
    print('🔒 AuthBloc: Handling AuthUserInactivityDetected event - Current state: $currentState');
    
    if (currentState is! AuthAuthenticated) {
      print('⚠️ AuthBloc: Cannot logout due to inactivity - User is not authenticated');
      return;
    }
    
    try {
      print('🔒 AuthBloc: Attempting to logout user due to inactivity');
      await _authRepository.logout();
      print('👋 AuthBloc: User logged out due to inactivity');
      emit(const AuthUnauthenticated(message: 'Has sido desconectado por inactividad'));
    } on AppException catch (error) {
      print('❌ AuthBloc: Error logging out user: ${error.toString()}');
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    } catch (e) {
      print('❌ AuthBloc: Unexpected error logging out user: $e');
      emit(AuthUnauthenticated(message: 'Error inesperado al cerrar sesión: $e'));
    }
  }
  
  @override
  Future<void> close() {
    _onUserActivitySubscription?.cancel();
    _authRepository.dispose();
    return super.close();
  }
}