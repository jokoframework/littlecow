import 'package:littlecow/core/errors/app_exception.dart';
import 'package:littlecow/core/errors/exception_handler.dart';
import 'package:littlecow/data/auth_repository.dart';
import 'package:littlecow/models/notifications/notifications_response.dart';
import 'package:littlecow/services/notification_service.dart';

class NotificationsRepository {
  final NotificationService _notificationService;
  final AuthRepository _authRepository;
  
  NotificationsRepository({
    NotificationService? notificationService,
    AuthRepository? authRepository,
  })  : _notificationService = notificationService ?? NotificationService(),
        _authRepository = authRepository ?? AuthRepository();
  
  /// Obtiene las notificaciones de un usuario específico
  /// 
  /// [userId] es el identificador único del usuario (UUID)
  /// 
  /// Retorna un [NotificationsResponse] con la lista de notificaciones
  Future<NotificationsResponse> getUserNotifications(String userId) async {
    try {
      // Obtener token válido del repositorio de autenticación
      final accessToken = await _authRepository.getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      
      // Llamar al servicio con el token obtenido
      return await _notificationService.getUserNotifications(userId, accessToken);
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
      // Obtener token válido del repositorio de autenticación
      final accessToken = await _authRepository.getValidAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.sessionExpired();
      }
      
      // Llamar al servicio con el token obtenido
      return await _notificationService.markNotificationAsRead(notificationId, accessToken);
    } catch (e) {
      throw ExceptionHandler.handle(e);
    }
  }
}