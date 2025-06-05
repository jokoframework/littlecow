import 'package:flutter/material.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/data/secure_storage_service.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_model.dart';
import 'package:littlecow/services/auth_service.dart';
import 'package:watch_it/watch_it.dart';

class AuthRepository {
  final  _authService = di<AuthService>();
  final  _secureStorage = di<SecureStorageService>();
  
  AuthRepository() {
    cleanInvalidCredentials();
  }
  
  /// Limpia las credenciales inválidas al iniciar la aplicación
  Future<void> cleanInvalidCredentials() async {
    try {
      final hasRefreshToken = await _secureStorage.hasRefreshToken();
      if (!hasRefreshToken) {
        return; 
      }

      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final tokenInfo = await _authService.getTokenInfo(accessToken);
          if (!tokenInfo.success || tokenInfo.expiresIn <= 0) {
            debugPrint('Token inválido detectado. Limpiando almacenamiento...');
            await _secureStorage.deleteAllTokens();
            await _secureStorage.deleteUserData();
            await _secureStorage.deleteUsername();
          }
        } catch (e) {
          debugPrint('Error verificando token al iniciar: $e. Limpiando almacenamiento...');
          await _secureStorage.deleteAllTokens();
          await _secureStorage.deleteUserData();
          await _secureStorage.deleteUsername();
        }
      }
    } catch (e) {
      debugPrint('Error general al limpiar credenciales: $e');
    }
  }

  /// Realiza el inicio de sesión
  /// 
  /// [username] - nombre de usuario.
  /// [password] - contraseña.
  /// Lanza AppException en caso de error.
  Future<JokoTokenResponse> login(String username, String password) async {
    try {
      final loginResponse = await _authService.login(username, password);
      if (loginResponse.success) {
        debugPrint('creacion del refreshToken: ${DateTime.now() }, ${loginResponse.secret}');
        await _secureStorage.saveRefreshToken(loginResponse.secret);
        await _secureStorage.saveUsername(username);
      }
      return loginResponse;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  
  Future<User?> getCurrentUser() async {
    try {
      final username = await _secureStorage.getUsername();
      if (username == null || username.isEmpty) {
        return null;
      }
      final accessToken = await getValidAccessToken();
      debugPrint('getCurrentUser: accessToken: ${DateTime.now()}, $accessToken');
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
      final userResponse = await _authService.getUserInfo(accessToken, username);
      if (userResponse.user != null) {
        await _secureStorage.saveUserData(userResponse.user!);
        return userResponse.user;
      }
      return null;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Cierra la sesión del usuario actual
  /// Lanza AppException en caso de error grave que impida el logout.
  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      await _authService.logout(refreshToken);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    } finally {
      await _secureStorage.deleteAllTokens();
      await _secureStorage.deleteUserData();
      await _secureStorage.deleteUsername();
    }
  }
  
  /// Verifica si hay una sesión activa y válida
  Future<bool> hasActiveSession() async {
    try {
      bool refreshTokenExists = await _secureStorage.hasRefreshToken();
      if (refreshTokenExists == false) {
        return false;
      }
      final userExists = await _secureStorage.hasUserData();
      return userExists;
    } catch (e) {
      return false; 
    }
  }

  /// Verifica si el token de acceso ha expirado
  Future<bool> isAccessTokenExpired() async {
    try {
      final expirationTimestamp = await _secureStorage.getAccessTokenExpiration();
      if (expirationTimestamp == null) {
        return true;
      }
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
      final now = DateTime.now();
      return now.isAfter(expirationDate.subtract(const Duration(seconds: 30)));
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  /// Obtiene un token de acceso válido
  /// Si el token está expirado, intenta refrescarlo automáticamente
  /// Ahora verifica la validez del token directamente con token/info
  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();      
      if (accessToken == null || accessToken.isEmpty) {
        return await refreshAccessToken();
      }
      
      try {
        final tokenInfo = await _authService.getTokenInfo(accessToken);
        
        if (tokenInfo.success && tokenInfo.expiresIn > 30) {
          final expirationDate = DateTime.now().add(Duration(seconds: tokenInfo.expiresIn));
          await _secureStorage.saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
          return accessToken;
        } else {
          debugPrint('Token inválido o expirado según token/info. Refrescando...');
          return await refreshAccessToken();
        }
      } catch (e) {
        debugPrint('Error al verificar token con token/info: $e. Refrescando...');
        return await refreshAccessToken();
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  /// Refresca el token de acceso usando el refresh token
  static bool _isRefreshing = false;
  
  Future<String?> refreshAccessToken() async {
    if (_isRefreshing) {
      return null;
    }
    _isRefreshing = true;
    
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final tokenResponse = await _authService.refreshAccessToken(refreshToken);
      final accessToken = tokenResponse.secret;
      await _secureStorage.saveAccessToken(accessToken);
      if (tokenResponse.expiration > 0) {
        final expirationDate = DateTime.now().add(Duration(seconds: tokenResponse.expiration));
        await _secureStorage.saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
      }
      return accessToken;
    } on AppException catch (ex) {
      if (ex.message == AuthException.sessionExpired().message) {
        debugPrint('Expiro el refresh token');
      }
      rethrow;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Obtiene información del token de acceso actual
  /// Lanza AppException en caso de error.
  Future<JokoTokenInfoResponse?> getTokenInfo() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }      
      try {
        final tokenInfo = await _authService.getTokenInfo(accessToken);
        return tokenInfo;
      } on AuthException {
        rethrow;
      } catch (e) {
        final newAccessToken = await refreshAccessToken();
        if (newAccessToken == null || newAccessToken.isEmpty) {
          throw AuthException.sessionExpired();
        }        
        return await _authService.getTokenInfo(newAccessToken);
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  void dispose() {
    _authService.dispose();
  }
}