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
    on<AuthUserInactivityDetected>(_onAuthUserInactivityDetected);
    on<AuthErrorFromBloc>(_onAuthErrorFromBloc);
  }

  void listenToUserActivity(UserActivityBloc userActivityBloc) {
    _onUserActivitySubscription?.cancel();
    _onUserActivitySubscription = userActivityBloc.stream.listen((userActivityState) {
      if (userActivityState is UserActivityInactive && state is AuthAuthenticated) {
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
      emit(AuthUnauthenticated(message: '', error: error));
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
      emit(AuthUnauthenticated(message: '',error: error));
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
    if (currentState is! AuthAuthenticated) {
      return;
    }
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated(message: 'Has sido desconectado por inactividad'));
    } on AppException catch (error) {
      emit(AuthUnauthenticated(message: error.toString(), error: error));
    } catch (e) {
      emit(AuthUnauthenticated(message: 'Error inesperado al cerrar sesión: $e'));
    }
  }
  
  /// Este método maneja errores de autenticación originados en otros blocs
  /// 
  /// Convierte los errores específicos en estados apropiados para que el
  /// listener global en main.dart pueda realizar la navegación adecuada
  /// Si se recibe un error 401 o un fallo de conexión, se cierran los tokens
  /// 
  /// Parámetros:
  /// [event] : Evento con información del error
  /// [emit] : Función para emitir nuevos estados
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
        emit(const AuthUnauthenticated(message: 'La sesión ha expirado, por favor inicie sesión nuevamente' ));
      }finally{
        emit(AuthUnauthenticated(message: isAuthError 
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