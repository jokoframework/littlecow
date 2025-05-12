import 'package:dio/dio.dart';
import 'dart:async';
import 'package:littlecow/constants/api_routes.dart'; 
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/data/secure_storage_service.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_model.dart';
import 'package:littlecow/core/errors/exception_handler.dart';

/// Metodos de la clase [AuthService]
/// 
/// 1. Metodos de autenticación principales.
/// - [login] : Para iniciar sesion.
/// - [logout] : Para cerrar sesion.
/// - [hasValidSession] : Para verificar si hay una sesion activa.
/// 
/// 2. Metodos para gestion de usuarios.
/// - [getCurrentUser] : Para obtener el usuario actual.
/// 
/// 3. Metodos para gestion de tokens.
/// - [getValidAccessToken] : Para obtener un token de acceso valido.
/// - [isAccessTokenExpired] : Para verificar si el token de acceso ha expirado.
/// - [getAccessTokenAndUser] : Para obtener el token de acceso y el usuario.
/// - [getTokenInfo] : Para obtener la informacion del token.
/// - [_getTokenInfoFromToken] : Para obtener la informacion del token a partir de un token de acceso.
/// 
/// 4. Gestion de recursos.
/// - [dispose] : Para liberar recursos.
/// 

class AuthService{
  final SecureStorageService _secureStorage;
  final Dio _dio;
  /// Stream para notificar cuando un token ya no es válido
  final _tokenInvalidController = StreamController<void>.broadcast();
  Stream<void> get onTokenInvalid => _tokenInvalidController.stream;
  
  AuthService({
    SecureStorageService? secureStorage,
    Dio? dio,
  }) : _secureStorage = secureStorage ?? SecureStorageService(),
       _dio = dio ?? Dio();
       
  
  /// Método para iniciar sesión
  /// 
  /// 1. Realiza una petición POST a la API para autenticar al usuario
  /// 2. Si la autenticación es exitosa, guarda el token y el nombre de usuario
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
        final loginResponse = JokoTokenResponse.fromJson(response.data);
        await _secureStorage.saveRefreshToken(loginResponse.secret);
        await _secureStorage.saveUsername(username);
        return loginResponse;
      } on DioException catch (e) {
        throw ExceptionHandler.handleDioException(e);
      } catch (e) {
        throw ExceptionHandler.handle(e);
      }
  }
  
  
  /// Método para cerrar sesión
  /// 
  /// 1. Elimina el refresh token y el access token almacenados localmente.
  /// 2. Realiza una petición POST a la API para cerrar sesión.
  /// 3. Si la respuesta es exitosa, elimina los tokens almacenados localmente.
  ///
  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(
          ApiRoutes.logout,
          options: Options(
            headers: ApiRoutes.getCommonHeaders(token: refreshToken),
          ),
        );
      }
    }on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    }catch (e) {
      throw ExceptionHandler.handle(e);
    } finally {
      await _secureStorage.deleteAllTokens();
    }
  }
  
  /// Comprueba si existe una sesión activa y válida
  /// 
  /// 1. Verifica si hay un refresh token almacenado.
  /// 2. Si no hay refresh token, devuelve false.
  /// 3. Intenta obtener un nuevo access token y usuario.
  /// 4. Si se obtiene un nuevo token, devuelve true.
  /// 5. Si no se obtiene un nuevo token, devuelve false.
  /// 
  Future<bool> hasValidSession() async {
    try {
      if (!await _secureStorage.hasRefreshToken()) {
        return false;
      }
      final user = await getAccessTokenAndUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Método para obtener el usuario actual
  ///  
  /// 1. Intenta obtener el usuario desde el almacenamiento local.
  /// 2. Si no hay usuario almacenado, intenta obtener un nuevo token y usuario.
  /// 3. Si se obtiene un nuevo token, actualiza el almacenamiento local.
  /// 
  Future<User?> getCurrentUser() async {
    try {
      final accessToken = await getValidAccessToken();
      if (accessToken == null) {
        return null;
      }
      final user = await _secureStorage.getUserData();
      if (user != null) {
        return user;
      }
      return await getAccessTokenAndUser();
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Verifica si el access token actual está expirado
  /// 
  /// 1. Obtiene la fecha de expiración del access token almacenado.
  /// 2. Si no hay fecha de expiración, considera que el token está expirado.
  /// 3. Compara la fecha actual con la fecha de expiración.
  /// 4. Añade un margen de seguridad (30 segundos) para renovar el token antes de que expire.
  /// 
  Future<bool> isAccessTokenExpired() async {
    try{
      final expirationTimestamp = await _secureStorage.getAccessTokenExpiration();
    if (expirationTimestamp == null) {
      return true;
    }
    final expirationDate = DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
    final now = DateTime.now();
    return now.isAfter(expirationDate.subtract(const Duration(seconds: 30)));
    }catch(e){
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Obtiene el access token
  /// 
  /// 1. Verifica si hay un access token almacenado y si no ha expirado.
  /// 2. Si el token es válido, lo devuelve.
  /// 3. Si el token ha expirado, intenta renovarlo usando el refresh token.
  /// 4. Si la renovación es exitosa, devuelve el nuevo token.
  /// 5. Si no se puede renovar el token, devuelve null y notifica que el token es inválido.
  ///   
  Future<String?> getValidAccessToken() async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      final tokenExpired = await isAccessTokenExpired();
      if (accessToken != null && !tokenExpired) {
        return accessToken;
      }
      final user = await getAccessTokenAndUser();
      if (user != null) {
        final newToken = await _secureStorage.getAccessToken();
        return newToken;
      }
      _tokenInvalidController.add(null);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _tokenInvalidController.add(null);
      }
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      _tokenInvalidController.add(null);
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Método para obtener el token de acceso y la información del usuario.
  /// 
  /// 1. Verifica si hay un refresh token almacenado.
  /// 2. Si no hay refresh token, devuelve null.
  /// 3. Realiza una petición POST a la API para obtener un nuevo access token.
  /// 4. Si la respuesta es exitosa, guarda el access token y su fecha de expiración.
  /// 
  Future<User?> getAccessTokenAndUser() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.post(
        ApiRoutes.userAccess,
        options: Options(
          headers: ApiRoutes.getCommonHeaders(token: refreshToken),
        ),
      );
      final tokenResponse = JokoTokenResponse.fromJson(response.data);
      final accessToken = tokenResponse.secret;
      if (!tokenResponse.success) {
        throw AuthException(
          message: tokenResponse.message,
        );
      }
      await _secureStorage.saveAccessToken(accessToken);
      if (tokenResponse.expiration > 0) {
        final expirationDate = DateTime.now().add(Duration(seconds: tokenResponse.expiration));
        await _secureStorage.saveAccessTokenExpiration(expirationDate.millisecondsSinceEpoch);
      }
      final tokenInfo = await _getTokenInfoFromToken(accessToken);
      if (tokenInfo == null) {
        throw DataException.missingData();
      }
      final user = User(
        name: tokenInfo.userId, 
        role: tokenInfo.audiencie,
      );
      await _secureStorage.saveUserData(user);     
      return user;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    }catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Obtiene información del token de acceso actual usando el endpoint /api/token/info
  /// 
  /// 1. Llama al método [getValidAccessToken] para obtener un token válido.
  /// 2. Si el token es válido, llama al método [_getTokenInfoFromToken] para obtener la información del token.
  /// 3. Si el token no es válido, devuelve null.
  Future<JokoTokenInfoResponse?> getTokenInfo() async {
    try {
      final accessToken = await getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      return await _getTokenInfoFromToken(accessToken);
    }on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    }catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Obtiene información del token de acceso pasado como parámetro
  ///  
  /// 1. Realiza una petición GET al endpoint de información del token.
  /// 2. Si la respuesta es exitosa, convierte la respuesta en un objeto JokoTokenInfoResponse.
  /// 3. Si el token es inválido, notifica a través del stream.
  Future<JokoTokenInfoResponse?> _getTokenInfoFromToken(String accessToken) async {
    try{
      if (accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.get(
        ApiRoutes.tokenInfo,
        queryParameters: {'accessToken': accessToken},
      );
      final tokenInfo = JokoTokenInfoResponse.fromJson(response.data);
      if (!tokenInfo.success) {
        if (tokenInfo.errorCode == 'token_expired') {
          throw AuthException.sessionExpired();
        }
        throw AuthException(
          message: tokenInfo.message,
        );
      }
      return tokenInfo;
    }catch (e){
      throw ExceptionHandler.handle(e);
    }
  }
  
  /// Liberar recursos cuando ya no se necesite el servicio
  void dispose() {
    _tokenInvalidController.close();
  }
}
