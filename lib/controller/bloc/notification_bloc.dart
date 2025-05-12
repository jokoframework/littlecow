import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/events/notification_event.dart';
import 'package:littlecow/controller/states/notification_state.dart';
import 'package:littlecow/models/notifications/notification_model.dart';
import 'package:littlecow/services/notification_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;

  NotificationBloc({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService(),
        super(NotificationInitial()) {
    on<FetchNotifications>(_onFetchNotifications);
    on<NotificationRefresh>(_onNotificationRefresh);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
  }
  /// 
  Future<void> _onFetchNotifications(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    try {
      final response = await _notificationService.getUserNotifications(event.userId);
      
      if (response.success) {
        emit(NotificationLoaded(notifications: response.notifications));
      } else {
        emit(NotificationError(message: response.message));
      }
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onNotificationRefresh(
    NotificationRefresh event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await _notificationService.getUserNotifications(event.userId);
      
      if (response.success) {
        emit(NotificationLoaded(notifications: response.notifications));
      } else {
        emit(NotificationError(message: response.message));
      }
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final updatedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return NotificationModel(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              isRead: true,
              createdAt: notification.createdAt,
              channel: notification.channel,
            );
          }
          return notification;
        }).toList();
        
        emit(NotificationLoaded(notifications: updatedNotifications));        
        await _notificationService.markNotificationAsRead(event.notificationId);        
      }
    } catch (e) {
      // Si hay un error, no recargamos todas las notificaciones
      // Simplemente mantenemos el estado actual para no confundir al usuario
    }
  }
}