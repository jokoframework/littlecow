import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:littlecow/core/api_routes.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/models/token_info_response.dart';
import 'package:littlecow/models/token_response.dart';
import 'package:littlecow/models/user_response.dart';
import 'package:littlecow/core/errors/exception_handler.dart';

class AuthService {
  final Dio _dio;

  AuthService({
    Dio? dio,
    bool handleStorageOperations = true,
  }) : _dio = dio ?? Dio();

  Future<JokoTokenResponse> login(String username, String password) async {
    try {
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

  Future<JokoTokenResponse> refreshAccessToken(String refreshToken) async {
    try {
      if (refreshToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      debugPrint('Refreshing access token with refresh token');

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

  Future<JokoTokenInfoResponse> getTokenInfo(String accessToken) async {
    try {
      if (accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.get(
        ApiRoutes.tokenInfo,
        queryParameters: {'accessToken': accessToken},
      );
      final tokenInfo = JokoTokenInfoResponse.fromJson(response.data);
      return tokenInfo;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Future<UserResponse> getUserInfo(String accessToken, String username) async {
    try {
      if (accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.get(
        ApiRoutes.userInfo(username),
        options: Options(
          headers: ApiRoutes.getCommonHeaders(token: accessToken),
        ),
      );
      final userInfo = UserResponse.fromJson(response.data);
      return userInfo;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  void dispose() {}
}
