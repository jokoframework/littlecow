import 'package:dio/dio.dart';
import 'package:littlecow/constants/api_routes.dart';
import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/models/notifications/notifications_response.dart';
import 'package:littlecow/models/base_response.dart';
import 'package:littlecow/services/auth_service.dart';

class NotificationService {
  final Dio _dio;
  final AuthService _authService;

  NotificationService({
    Dio? dio,
    AuthService? authService,
  }) : _dio = dio ?? Dio(),
       _authService = authService ?? AuthService();

  /// Obtiene las notificaciones de un usuario específico
  /// 
  /// [userId] es el identificador único del usuario (UUID)
  /// 
  /// Retorna un [NotificationsResponse] con la lista de notificaciones
  Future<NotificationsResponse> getUserNotifications(String userId) async {
    try {
      final accessToken = await _authService.getValidAccessToken();
      if (accessToken == null) {
        throw AuthException.tokenExpired();
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
  /// 
  /// Retorna true si se marcó correctamente, false en caso contrario
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final accessToken = await _authService.getValidAccessToken();
      if (accessToken == null) {
        throw AuthException.tokenExpired();
      }
      final response = await _dio.put(
        ApiRoutes.markNotificationAsRead(notificationId),
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