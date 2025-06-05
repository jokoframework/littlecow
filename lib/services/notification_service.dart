import 'package:dio/dio.dart';
import 'package:littlecow/core/api_routes.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/models/notifications/notifications_response.dart';
import 'package:littlecow/models/base_response.dart';

class NotificationService {
  final Dio _dio;

  NotificationService({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Metodo que obitiene las notificaciones de un usuario
  /// Parametros:
  /// - [userId]: ID del usuario
  /// - [accessToken]: Token de acceso del usuario
  /// 
  /// Retorno:
  /// - [NotificationsResponse] con las notificaciones del usuario
  /// 
  Future<NotificationsResponse> getUserNotifications(
      String userId, String accessToken) async {
    try {
      if (accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.get(
        ApiRoutes.getUserNotifications(userId),
        options: Options(
          headers: ApiRoutes.getCommonHeaders(token: accessToken),
        ),
      );
      return NotificationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
  /// Metodo que marca una notificación como leída
  /// Parámetros:
  /// - [notificationId]: ID de la notificación a marcar como leída
  /// - [accessToken]: Token de acceso del usuario
  /// - [userId]: ID del usuario propietario de la notificación
  /// 
  /// Retorno:
  /// - [bool] indicando si la operación fue exitosa
  /// 
  Future<bool> markNotificationAsRead(
      String notificationId, String accessToken, String userId) async {
    try {
      if (accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.put(
        ApiRoutes.markNotificationAsRead(notificationId, userId),
        options: Options(
          headers: ApiRoutes.getCommonHeaders(token: accessToken),
        ),
      );
      final baseResponse = JokoBaseResponse.fromJson(response.data);
      return baseResponse.success;
    } on DioException catch (e) {
      throw ExceptionHandler.handleDioException(e);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
