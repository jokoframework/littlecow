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

  /// Obtiene las notificaciones de un usuario específico
  /// 
  /// [userId] es el identificador único del usuario (UUID)
  /// [accessToken] es el token de acceso para autenticación
  /// 
  /// Retorna un [NotificationsResponse] con la lista de notificaciones
  Future<NotificationsResponse> getUserNotifications(String userId, String accessToken) async {
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
  
  /// Marca una notificación como leída
  /// 
  /// [notificationId] es el identificador único de la notificación
  /// [accessToken] es el token de acceso para autenticación
  /// 
  /// Retorna true si se marcó correctamente, false en caso contrario
  Future<bool> markNotificationAsRead(String notificationId, String accessToken, String userId) async {
    try {
      if (accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      final response = await _dio.put(
        ApiRoutes.markNotificationAsRead(notificationId,userId),
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