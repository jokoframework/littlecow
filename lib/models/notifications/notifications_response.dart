import 'package:littlecow/models/base_response.dart';
import 'package:littlecow/models/notifications/notification_model.dart';

class NotificationsMetadata {
  final int total;
  final DateTime timestamp;

  NotificationsMetadata({
    required this.total,
    required this.timestamp,
  });

  factory NotificationsMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationsMetadata(
      total: json['total'] ?? 0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}

class NotificationsResponse extends JokoBaseResponse {
  final List<NotificationModel> notifications;
  final NotificationsMetadata? metadata;

  NotificationsResponse({
    required super.success,
    super.errorCode,
    super.message,
    this.notifications = const [],
    this.metadata,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = JokoBaseResponse.fromJson(json);
    
    final notificationsList = (json['data'] as List?)
        ?.map((notificationJson) => NotificationModel.fromJson(notificationJson))
        .toList() ?? [];

    final metadataJson = json['metadata'] as Map<String, dynamic>?;
    final metadata = metadataJson != null 
        ? NotificationsMetadata.fromJson(metadataJson) 
        : null;

    return NotificationsResponse(
      success: baseResponse.success,
      errorCode: baseResponse.errorCode,
      message: baseResponse.message,
      notifications: notificationsList,
      metadata: metadata,
    );
  }
}