import 'package:flutter/material.dart';

enum NotificationType {
  warning,
  info,
  success,
  error,
  alert
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String channel;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    required this.channel,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Map API category to NotificationType
    NotificationType mapCategory(String? category) {
      switch (category?.toLowerCase()) {
        case 'alert':
          return NotificationType.alert;
        case 'warning':
          return NotificationType.warning;
        case 'info':
          return NotificationType.info;
        case 'success':
          return NotificationType.success;
        case 'error':
          return NotificationType.error;
        default:
          return NotificationType.info;
      }
    }

    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '', 
      type: mapCategory(json['category']), 
      isRead: json['read'] ?? false, 
      createdAt: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
      channel: json['channel'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': message, 
      'category': _categoryFromType(), 
      'read': isRead,
      'timestamp': createdAt.toIso8601String(),
      'channel': channel,
    };
  }

  String _categoryFromType() {
    switch (type) {
      case NotificationType.warning:
        return 'warning';
      case NotificationType.info:
        return 'info';
      case NotificationType.success:
        return 'success';
      case NotificationType.error:
        return 'error';
      case NotificationType.alert:
        return 'alert';
    }
  }

  IconData getIcon() {
    switch (type) {
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.alert:
        return Icons.notifications_active_rounded;
    }
  }

  Color getColor() {
    switch (type) {
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.alert:
        return Colors.purple;
    }
  }
}