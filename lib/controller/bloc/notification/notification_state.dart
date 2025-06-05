import 'package:equatable/equatable.dart';
import 'package:littlecow/models/notifications/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;

  const NotificationLoaded({required this.notifications});

  @override
  List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;
  final String? operationType;
  final String? notificationId;

  const NotificationError({
    required this.message,
    this.operationType,
    this.notificationId,
  });

  @override
  List<Object?> get props => [message, operationType, notificationId];
}
