import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:littlecow/controller/events/auth_event.dart';
import 'package:littlecow/controller/states/auth_state.dart';
import 'package:littlecow/data/auth_repository.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _tokenInvalidSubscription;
  Timer? _tokenVerificationTimer;
  
  AuthBloc({AuthRepository? authRepository}) 
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
    on<AuthTokenInvalidated>(_onAuthTokenInvalidated);
    // Escucha el evento de token inválido y emite un estado correspondiente
    _tokenInvalidSubscription = _authRepository.onTokenInvalid.listen(
      (_) => add(AuthTokenInvalidated()),
    );
  }
  /// Verificación periódica del token
  /// 
  /// 1. Verica si el token es válido cada 5 minutos
  /// 2. Si el token no es válido, emite un evento de token invalidado
  /// 3. Cancela cualquier timer existente antes de crear uno nuevo [_stopTokenVerification]
  /// 4. Lanza una excepción en caso de error
  ///   
  void _startTokenVerification() {
    _stopTokenVerification();
    _tokenVerificationTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        final tokenInfo = await _authRepository.getTokenInfo();
        if (tokenInfo == null || !tokenInfo.success) {
          add(AuthTokenInvalidated());
        }
      } catch (e) {
        add(AuthTokenInvalidated());      
      }
    });
  }
  /// Detiene la verificación periódica del token
  void _stopTokenVerification() {
    _tokenVerificationTimer?.cancel();
    _tokenVerificationTimer = null;
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
      emit(AuthFailure(message: e.toString()));
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
        } else {
          emit(const AuthFailure(message: 'No se pudo obtener información del usuario'));
        }
      } else {
        emit(AuthFailure(message: loginResponse.message));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
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
      emit(AuthFailure(message: e.toString()));
    }
  }
  
  /// Este método se encarga de manejar el evento de token inválido.
  /// 
  /// 1. Emite un estado de error indicando que la sesión ha expirado
  /// 2. Espera 2 segundos antes de emitir un estado de no autenticado
  /// 3. Limpia los tokens almacenados
  /// 
  /// Parametros:
  /// [event] : Evento de token inválido
  /// [emit] : Función para emitir nuevos estados
  /// 
  FutureOr<void> _onAuthTokenInvalidated(
      AuthTokenInvalidated event, Emitter<AuthState> emit) async {
    emit(const AuthFailure(message: 'La sesión ha expirado. Por favor, inicie sesión nuevamente.'));
    await Future.delayed(const Duration(seconds: 2));
    emit(AuthUnauthenticated());
    await _authRepository.logout();
  }


  @override
  Future<void> close() {
    _tokenInvalidSubscription?.cancel();
    _stopTokenVerification();
    _authRepository.dispose();
    return super.close();
  }
}