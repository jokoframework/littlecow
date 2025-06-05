import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/data/auth_repository.dart';
import 'package:littlecow/models/notifications/notifications_response.dart';
import 'package:littlecow/services/notification_service.dart';
import 'package:watch_it/watch_it.dart';

class NotificationsRepository {
  final _notificationService = di<NotificationService>();
  final _authRepository = di<AuthRepository>();

  NotificationsRepository();

  Future<NotificationsResponse> getUserNotifications(String userId) async {
    try {
      final accessToken = await _authRepository.getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      return await _notificationService.getUserNotifications(
          userId, accessToken);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }

  Future<bool> markNotificationAsRead(
      String notificationId, String userId) async {
    try {
      final accessToken = await _authRepository.getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      return await _notificationService.markNotificationAsRead(
          notificationId, accessToken, userId);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}
