import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:littlecow/controller/events/notification_event.dart';
import 'package:littlecow/controller/states/notification_state.dart';
import 'package:littlecow/data/notifications_repository.dart';
import 'package:littlecow/models/notifications/notification_model.dart';
import 'package:watch_it/watch_it.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final  _notificationsRepository = di<NotificationsRepository>();

  NotificationBloc() :  super(NotificationInitial()) {
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
      final response = await _notificationsRepository.getUserNotifications(event.userId);
      if (response.success) {
        emit(NotificationLoaded(notifications: response.notifications));
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
      final response = await _notificationsRepository.getUserNotifications(event.userId);
      
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
        await _notificationsRepository.markNotificationAsRead(event.notificationId, event.userId);        
      }
    } catch (e) {
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final revertedNotifications = currentState.notifications.map((notification) {
          if (notification.id == event.notificationId) {
            return NotificationModel(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              type: notification.type,
              isRead: false, 
              createdAt: notification.createdAt,
              channel: notification.channel,
            );
          }
          return notification;
        }).toList();
        emit(NotificationLoaded(notifications: revertedNotifications));
        emit(NotificationError(
          message: 'Error al marcar la notificación como leída',
          operationType: 'mark_read',
          notificationId: event.notificationId,
        ));
      }
    }
  }
}