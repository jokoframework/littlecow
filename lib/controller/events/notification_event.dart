import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotifications extends NotificationEvent {
  final String userId;

  const FetchNotifications({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class NotificationRefresh extends NotificationEvent {
  final String userId;

  const NotificationRefresh({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;
  final String userId;

  const MarkNotificationAsRead({
    required this.notificationId,
    required this.userId,
  });

  @override
  List<Object?> get props => [notificationId, userId];
}