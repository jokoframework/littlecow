import 'package:dio/dio.dart';
import 'dart:async';
import 'package:littlecow/constants/api_routes.dart'; 
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/core/errors/exception_handler.dart';

/// Metodos de la clase [AuthService]
/// 
/// 1. Metodos de autenticación principales.
/// - [login] : Para iniciar sesion.
/// - [logout] : Para cerrar sesion.
/// 
/// 2. Metodos para gestion de tokens.
/// - [refreshAccessToken] : Para refrescar el token de acceso.
/// - [getTokenInfo] : Para obtener la informacion del token.
/// 
/// 3. Gestion de recursos.
/// - [dispose] : Para liberar recursos.
/// 

class AuthService{
  final Dio _dio;
  /// Stream para notificar cuando un token ya no es válido
  final _tokenInvalidController = StreamController<void>.broadcast();
  Stream<void> get onTokenInvalid => _tokenInvalidController.stream;
  
  AuthService({
    Dio? dio,
    bool handleStorageOperations = true,
  }) : _dio = dio ?? Dio();
       
  
  /// Método para iniciar sesión
  /// 
  /// 1. Realiza una petición POST a la API para autenticar al usuario
  /// 2. Si la autenticación es exitosa, devuelve la respuesta con el token
  /// 3. Si ocurre un error, lanza una AppException
  /// 
  /// Parámetros:
  /// - [username] : Nombre de usuario
  /// - [password] : Contraseña del usuario
  /// 
  Future<JokoTokenResponse> login(String username, String password) async {
      try{
        final response = await _dio.post(
          ApiRoutes.login,
          data: {
            'username': username,
            'password': password,
          },
          options: Options(
            headers: ApiRoutes.getCommonHeaders(),
          ),
        );        
        return JokoTokenResponse.fromJson(response.data);
      } on DioException catch (e) {
        throw ExceptionHandler.handleDioException(e);
      } catch (e) {
        throw ExceptionHandler.handle(e);
      }
  }
  
  
  /// Método para cerrar sesión
  /// 
  /// 1. Realiza una petición POST a la API para cerrar sesión.
  /// 2. Si ocurre un error, lanza una AppException.
  ///
  Future<void> logout(String? refreshToken) async {
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          ApiRoutes.logout,
          options: Options(
            headers: ApiRoutes.getCommonHeaders(token: refreshToken),
          ),
        );
      }
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Método para refrescar el token de acceso usando el refresh token
  /// 
  /// 1. Realiza una petición POST para obtener un nuevo access token.
  /// 2. Si la respuesta es exitosa, devuelve la respuesta con el nuevo token.
  /// 
  Future<JokoTokenResponse> refreshAccessToken(String refreshToken) async {
    try {
      if (refreshToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.post(
        ApiRoutes.userAccess,
        options: Options(
          headers: ApiRoutes.getCommonHeaders(token: refreshToken),
        ),
      );
      final tokenResponse = JokoTokenResponse.fromJson(response.data);
      if (!tokenResponse.success) {
        throw AuthException(message: tokenResponse.message);
      }
      return tokenResponse;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Obtiene información del token de acceso
  /// 
  /// 1. Realiza una petición GET para obtener información del token.
  /// 2. Si la respuesta es exitosa, devuelve la información del token.
  /// 3. Si el token es inválido, notifica a través del stream.
  Future<JokoTokenInfoResponse> getTokenInfo(String accessToken) async {
    try {
      if (accessToken.isEmpty) {
        _tokenInvalidController.add(null);
        throw AuthException.sessionExpired();
      }
      final response = await _dio.get(
        ApiRoutes.tokenInfo,
        queryParameters: {'accessToken': accessToken},
      );
      final tokenInfo = JokoTokenInfoResponse.fromJson(response.data);
      if (!tokenInfo.success) {
        if (tokenInfo.errorCode == 'token_expired') {
          _tokenInvalidController.add(null);
          throw AuthException.sessionExpired();
        }
        throw AuthException(message: tokenInfo.message);
      }
      return tokenInfo;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _tokenInvalidController.add(null);
      }
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Liberar recursos cuando ya no se necesite el servicio
  void dispose() {
    _tokenInvalidController.close();
  }
}
