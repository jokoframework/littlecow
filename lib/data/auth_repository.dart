import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_model.dart';
import 'package:littlecow/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  AuthRepository({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();
  
  /// Realiza el inicio de sesión
  /// 
  /// [username] - nombre de usuario.
  /// [password] - contraseña.
  /// Lanza AppException en caso de error.
  Future<JokoTokenResponse> login(String username, String password) async {
    try {
      return await _authService.login(username, password);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Obtiene el usuario actual
  /// 
  /// Devuelve un [User] si hay un usuario autenticado.
  /// Lanza AppException en caso de error.
  Future<User?> getCurrentUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      if (e is AuthException) {
        return null;
      }
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Cierra la sesión del usuario actual
  /// Lanza AppException en caso de error grave que impida el logout.
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Verifica si hay una sesión activa y válida
  Future<bool> hasActiveSession() async {
    try {
      return await _authService.hasValidSession();
    } catch (e) {
      return false; 
    }
  }

  /// Obtiene información del token de acceso actual
  /// Lanza AppException en caso de error.
  Future<JokoTokenInfoResponse?> getTokenInfo() async {
    try {
      return await _authService.getTokenInfo();
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Obtiene un stream que notifica cuando el token se vuelve inválido
  Stream<void> get onTokenInvalid => _authService.onTokenInvalid;
  
  /// Libera recursos cuando ya no se necesita el repositorio
  void dispose() {
    _authService.dispose();
  }
}