import 'package:flutter/material.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/data/secure_storage_service.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_model.dart';
import 'package:littlecow/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import 'package:watch_it/watch_it.dart';

class AuthRepository {
  final  _authService = di<AuthService>();
  final  _secureStorage = di<SecureStorageService>();
  final _tokenInvalidController = StreamController<void>.broadcast();
  
  AuthRepository(); 

  /// Obtiene un stream que notifica cuando el token se vuelve inválido
  Stream<void> get onTokenInvalid => _tokenInvalidController.stream;

  /// Realiza el inicio de sesión
  /// 
  /// [username] - nombre de usuario.
  /// [password] - contraseña.
  /// Lanza AppException en caso de error.
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
  
  /// Obtiene el usuario actual
  /// 
  /// Devuelve un [User] si hay un usuario autenticado.
  /// Lanza AppException en caso de error.
  /// 
  /// 1. Primero verifica si hay un token válido
  /// 2. Si encuentra datos del usuario en el almacenamiento local, los devuelve
  /// 3. De lo contrario, obtiene el nombre de usuario y realiza una petición a la API
  /// 4. Si la petición a la API falla, utiliza los datos del token como respaldo
  /// 5. Almacena los datos del usuario para futura referencia
  Future<User?> getCurrentUser() async {
    try {
      final accessToken = await getValidAccessToken();
      if (accessToken == null) {
        return null;
      }
      
      final cachedUser = await _secureStorage.getUserData();
      if (cachedUser != null) {
        return cachedUser;
      }
      
      final username = await _secureStorage.getUsername();
      
      if (username != null && username.isNotEmpty) {
        try {
          final userResponse = await _authService.getUserInfo(accessToken, username);
          
          if (userResponse.success && userResponse.user != null) {
            await _secureStorage.saveUserData(userResponse.user!);
            return userResponse.user;
          }
        } catch (e) {
          debugPrint ('Error obteniendo usuario por nombre: $e');
        }
      }
      
      // Plan de respaldo: usar la información del token
      final tokenInfo = await getTokenInfo();
      if (tokenInfo != null && tokenInfo.success) {
        final newUser = User(
          name: tokenInfo.userId, 
          role: tokenInfo.audiencie,
        );
        await _secureStorage.saveUserData(newUser);
        return newUser;
      }
      
      return null;
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
      final refreshToken = await _secureStorage.getRefreshToken();
      await _authService.logout(refreshToken);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    } finally {
      await _secureStorage.deleteAllTokens();
    }
  }
  
  /// Verifica si hay una sesión activa y válida
  Future<bool> hasActiveSession() async {
    try {
      if (!await _secureStorage.hasRefreshToken()) {
        return false;
      }
      
      final user = await getCurrentUser();
      return user != null;
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
      // Añade un margen de seguridad para renovar el token antes de que expire
      return now.isAfter(expirationDate.subtract(const Duration(seconds: 30)));
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  /// Obtiene un token de acceso válido
  /// Si el token está expirado, intenta refrescarlo automáticamente
  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();      
      if (accessToken == null || accessToken.isEmpty) {
        return await refreshAccessToken();
      }      
      try {
        final tokenExpired = await isAccessTokenExpired(); 
        if (!tokenExpired) {
          return accessToken;
        }
      } catch (_) {
        // Si hay un error verificando la expiración, intentar refrescar de todos modos
      }      
      return await refreshAccessToken();
    } catch (e) {
      _tokenInvalidController.add(null);
      return null;
    }
  }

  /// Refresca el token de acceso usando el refresh token
  /// Usa un flag estático para evitar múltiples eventos de token inválido
  static bool _isRefreshing = false;
  static bool _hasNotifiedInvalid = false;
  
  Future<String?> refreshAccessToken() async {
    if (_isRefreshing) {
      return null;
    }
    
    _isRefreshing = true;
    
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _notifyTokenInvalidIfNeeded();
        return null;
      }
      
      final tokenResponse = await _authService.refreshAccessToken(refreshToken);
      if (!tokenResponse.success) {
        _notifyTokenInvalidIfNeeded();
        return null;
      }
      
      final accessToken = tokenResponse.secret;
      await _secureStorage.saveAccessToken(accessToken);
      
      if (tokenResponse.expiration > 0) {
        final expirationDate = DateTime.now().add(Duration(seconds: tokenResponse.expiration));
        await _secureStorage.saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
      }
      
      // Reiniciar el flag de notificación si obtuvimos un token válido
      _hasNotifiedInvalid = false;
      return accessToken;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _notifyTokenInvalidIfNeeded();
      }
      return null;
    } catch (e) {
      _notifyTokenInvalidIfNeeded();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
  
  /// Método auxiliar para notificar token inválido solo una vez
  void _notifyTokenInvalidIfNeeded() {
    if (!_hasNotifiedInvalid) {
      _tokenInvalidController.add(null);
      _hasNotifiedInvalid = true;
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
  
  /// Libera recursos cuando ya no se necesita el repositorio
  void dispose() {
    _authService.dispose();
    _tokenInvalidController.close();
  }
}