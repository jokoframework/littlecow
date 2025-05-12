import 'dart:io';

import 'package:dio/dio.dart';
import 'package:littlecow/core/errors/app_exception.dart';

/// Clase utilitaria para el manejo centralizado de excepciones
/// 
/// Esta clase proporciona métodos para convertir diferentes tipos de errores
/// en instancias de AppException, lo que permite un manejo consistente
/// de errores en toda la aplicación.
class ExceptionHandler {
  /// Convierte una excepción de Dio en una AppException apropiada
  static AppException handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.connectionTimeout();
        
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Error de certificado SSL',
          details: exception.message,
        );
      case DioExceptionType.badResponse:
        if (exception.response != null) {
          final statusCode = exception.response!.statusCode;
          final data = exception.response!.data;
          
          // Manejo específico para errores de autenticación
          if (statusCode == 401) {
            return AuthException.sessionExpired();
          } 
          
          // Errores 4xx - Errores del cliente
          else if (statusCode! >= 400 && statusCode < 500) {
            String message = 'Error de cliente';
            String? errorMessage;
            
            // Intentar extraer mensaje de error si existe
            if (data is Map && data.containsKey('message')) {
              errorMessage = data['message'];
              message = errorMessage ?? 'Error desconocido';
            }
            
            return NetworkException(
              message: message,
              details: errorMessage ?? exception.message,
            );
          } 
          
          // Errores 5xx - Errores del servidor
          else if (statusCode >= 500) {
            return NetworkException.serverError(statusCode);
          }
        }
        return NetworkException(
          message: 'Error en la respuesta del servidor',
          details: exception.message,
        );
        
      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Petición cancelada',
        );
        
      case DioExceptionType.connectionError:
        return NetworkException.noInternet();
        
      case DioExceptionType.unknown:
        if (exception.error is SocketException) {
          return NetworkException.noInternet();
        }
        return NetworkException.unknown(exception);
    }
  }
  
  /// Convierte cualquier excepción en una AppException apropiada
  static AppException handle(dynamic exception) {
    if (exception is AppException) {
      return exception;
    } else if (exception is DioException) {
      return handleDioException(exception);
    } else if (exception is FormatException) {
      return DataException.invalidData(exception.message);
    } else if (exception is SocketException) {
      return NetworkException.noInternet();
    } else {
      return DataException.unknown(exception);
    }
  }
}