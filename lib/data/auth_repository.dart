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
  final _authService = di<AuthService>();
  final _secureStorage = di<SecureStorageService>();

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
            await _secureStorage.deleteAllTokens();
          }
        } catch (e) {
          await _secureStorage.deleteAllTokens();
        }
      }
    } catch (e) {
      debugPrint('Error general al limpiar credenciales: $e');
    }
  }
  /// Método para iniciar sesión
  /// 
  /// Parámetros:
  /// - [username]: Nombre de usuario
  /// - [password]: Contraseña del usuario
  /// 
  /// 1. Llama al servicio de autenticación para iniciar sesión
  /// 2. Si la respuesta es exitosa, guarda el token de refresco y el nombre de usuario en el almacenamiento seguro
  /// 
  /// Retorno:
  /// - [JokoTokenResponse] con el token de refresco
  Future<JokoTokenResponse> login(String username, String password) async {
    try {
      final loginResponse = await _authService.login(username, password);
      if (loginResponse.success) {
        await _secureStorage.saveRefreshToken(loginResponse.secret);
        await _secureStorage.saveUsername(username);
      }
      return loginResponse;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  /// Método para obtener los datos del usuario actual
  /// 
  /// Parámetros:
  /// - Ninguno
  /// 
  /// 1. Obtiene el nombre de usuario del almacenamiento seguro
  /// 2. Obtiene el token de acceso válido [getValidAccessToken]
  /// 3. Llama al servicio de autenticación para obtener la información del usuario
  /// 
  /// Retorno:
  /// - [User] con los datos del usuario actual o null si no existe
  /// 
  Future<User?> getCurrentUser() async {
    try {
      final username = await _secureStorage.getUsername();
      if (username == null || username.isEmpty) {
        return null;
      }
      final accessToken = await getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
      final userResponse =
          await _authService.getUserInfo(accessToken, username);
      if (userResponse.user != null) {
        await _secureStorage.saveUserData(userResponse.user!);
        return userResponse.user;
      }
      return null;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      await _authService.logout(refreshToken);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    } finally {
      await _secureStorage.deleteAllTokens();
    }
  }

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
  /// Verifica si el token de acceso está expirado
  /// 
  /// Parámetros:
  /// - Ninguno
  /// 
  /// 1. Obtiene la fecha de expiración del token de acceso del almacenamiento seguro
  /// 2. Compara la fecha actual con la fecha de expiración
  /// 
  /// Retorno:
  /// - [bool] indicando si el token de acceso está expirado
  /// 
  Future<bool> isAccessTokenExpired() async {
    try {
      final expirationTimestamp =
          await _secureStorage.getAccessTokenExpiration();
      if (expirationTimestamp == null) {
        return true;
      }

      final expirationDate =
          DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
      final now = DateTime.now();
      return now.isAfter(expirationDate.subtract(const Duration(seconds: 30)));
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  /// Obtiene un token de acceso válido
  /// 
  /// Parámetros:
  /// - Ninguno
  /// 
  /// 1. Intenta obtener el token de acceso del almacenamiento seguro
  /// 2. Si el token es nulo o está expirado, llama a [refreshAccessToken]
  /// 3. Verifica la validez del token con el servicio de autenticación
  /// 
  /// Retorno:
  /// - [String] con el token de acceso válido o null si no se pudo obtener
  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return await refreshAccessToken();
      }

      try {
        final tokenInfo = await _authService.getTokenInfo(accessToken);

        if (tokenInfo.success && tokenInfo.expiresIn > 30) {
          final expirationDate =
              DateTime.now().add(Duration(seconds: tokenInfo.expiresIn));
          await _secureStorage
              .saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
          return accessToken;
        } else {
          return await refreshAccessToken();
        }
      } catch (e) {
        return await refreshAccessToken();
      }
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  static bool _isRefreshing = false;
  /// Refresca el token de acceso
  /// 
  /// Parámetros:
  /// - Ninguno
  /// 
  /// 1. Verifica si ya se está refrescando el token para evitar llamadas concurrentes
  /// 2. Obtiene el token de refresco del almacenamiento seguro
  /// 3. Llama al servicio de autenticación para refrescar el token de acceso
  /// 4. Guarda el nuevo token de acceso y su fecha de expiración en el almacenamiento seguro
  /// 
  /// Retorno:
  /// - [String] con el nuevo token de acceso o null si no se pudo refrescar
  /// 
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
        final expirationDate =
            DateTime.now().add(Duration(seconds: tokenResponse.expiration));
        await _secureStorage
            .saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
      }
      return accessToken;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExceptionHandler.handle(e);
    } finally {
      _isRefreshing = false;
    }
  }
  /// Obtiene la información del token
  /// 
  /// Parámetros:
  /// - Ninguno
  /// 
  /// 1. Obtiene el token de acceso válido [getValidAccessToken]
  /// 2. Llama al servicio de autenticación para obtener la información del token
  /// 
  /// Retorno:
  /// - [JokoTokenInfoResponse] con la información del token o null si no se pudo obtener
  /// 
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
