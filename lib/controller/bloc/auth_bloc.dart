import 'package:bloc/bloc.dart';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

import '../../model/user_model.dart';
import '../events/auth_event.dart';
import '../states/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Dio _dio;

  AuthBloc({Dio? dio})
      : _dio = dio ?? Dio(),
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    developer.log('AuthStarted event triggered', name: 'AuthBloc');
    emit(const AuthInitial());
  }

  void _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    developer.log('AuthLoginRequested event triggered', name: 'AuthBloc');
    emit(const AuthInProgress()); // Emit loading state

    try {
      final loginResponse = await _login(event.name, event.password);
      if (!loginResponse['success']) {
        throw Exception(loginResponse['message']);
      }

      final accessTokenResponse = await _getAccessToken(loginResponse['secret']);
      if (!accessTokenResponse['success']) {
        throw Exception(accessTokenResponse['message']);
      }

      final user = User(name: event.name); // Reemplaza con datos reales del usuario si están disponibles
      emit(AuthLoginSuccess(user: user, token: accessTokenResponse['secret']));
    } catch (e) {
      emit(AuthFailure(message: 'Login failed: ${e.toString()}'));
    }
  }

  void _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    developer.log('AuthLogoutRequested event triggered', name: 'AuthBloc');
    emit(const AuthInProgress()); // Emit loading state for logout

    try {
      // Llamar a la API de logout
      await _logout(event.refreshToken);

      // Emitir el estado inicial después de un logout exitoso
      emit(const AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: 'Logout failed: ${e.toString()}'));
    }
  }

  Future<Map<String, dynamic>> _login(String username, String password) async {
    try {
      final response = await _dio.post(
        'http://192.168.100.145:8080/api/login',
        data: {'username': username, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to login: ${e.response?.data ?? e.message}');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> _getAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        'http://192.168.100.145:8080/api/token/user-access',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-JOKO-AUTH': refreshToken, // Pasar el refresh token en este encabezado
          },
        ),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to get access token: ${e.response?.data ?? e.message}');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> _logout(String refreshToken) async {
    try {
      final response = await _dio.post(
        'http://192.168.100.145:8080/api/logout',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-JOKO-AUTH': refreshToken, // Pasar el refresh token en este encabezado
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Logout failed: ${response.data}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to logout: ${e.response?.data ?? e.message}');
      }
      throw Exception('Unexpected error: $e');
    }
  }
}