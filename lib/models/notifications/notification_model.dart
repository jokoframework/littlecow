import 'package:flutter/material.dart';

enum NotificationType {
  warning,
  info,
  success,
  error
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
      message: json['body'] ?? '', // API uses 'body' for message content
      type: mapCategory(json['category']), // API uses 'category' instead of 'type'
      isRead: json['read'] ?? false, // API uses 'read' instead of 'isRead'
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
      'body': message, // Map to API structure
      'category': _categoryFromType(), // Convert type to category string
      'read': isRead,
      'timestamp': createdAt.toIso8601String(),
      'channel': channel,
    };
  }

  // Helper method to convert NotificationType to API category
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
    }
  }

  // Helper method to get appropriate icon based on notification type
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
    }
  }

  // Helper method to get appropriate color based on notification type
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
    }
  }
}