import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:littlecow/controller/bloc/notification_bloc.dart';
import 'package:littlecow/controller/events/notification_event.dart';
import 'package:littlecow/controller/states/notification_state.dart';
import 'package:littlecow/controller/bloc/auth_bloc.dart';
import 'package:littlecow/controller/events/auth_event.dart';
import 'package:littlecow/models/notifications/notification_model.dart';
import 'package:littlecow/models/user_model.dart';

class NotificationsScreen extends StatelessWidget {
  final User user;

  const NotificationsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    context.read<NotificationBloc>().add(FetchNotifications(userId: user.id!));
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          if (state.message == 'La sesión ha expirado' || state.message == 'Credenciales inválidas') {
            debugPrint(state.message);
            context.read<AuthBloc>().add(AuthTokenInvalidated());
            Navigator.of(context).popUntil((route) => route.isFirst);

          } else if (state.operationType != 'mark_read') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                          FetchNotifications(userId: user.id!),
                        );
                  },
                ),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            actions: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                            NotificationRefresh(userId: user.id!),
                          );
                    },
                  );
                }, 
              ),
            ],
          ),
          body: BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is NotificationLoaded) {
                final notifications = state.notifications;
                if (notifications.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes notificaciones',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<NotificationBloc>().add(
                          NotificationRefresh(userId: user.id!),
                        );
                  },
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _NotificationCard(
                        notification: notifications[index],
                        userId: user.id!,
                      );
                    },
                  ),
                );
              } 
              return const Center(
                child: Text(
                  'Cargando notificaciones...',
                  style: TextStyle(fontSize: 18),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String userId;

  const _NotificationCard({
    required this.notification,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification.isRead 
          ? Colors.white 
          : Colors.blue.shade50, // Color diferente para no leídas
      elevation: notification.isRead ? 1 : 3, // Elevación diferente para no leídas
      child: InkWell(
        onTap: () {
          // Si la notificación no está leída, marcamos como leída
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(
                  MarkNotificationAsRead(
                    notificationId: notification.id,
                    userId: userId,
                  ),
                );
          }
          _showNotificationDetails(context, notification);
        },
        child: ListTile(
          leading: Icon(
            notification.getIcon(),
            color: notification.getColor(),
            size: 28,
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: !notification.isRead 
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ) 
              : null,
          isThreeLine: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }
  
  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              notification.getIcon(),
              color: notification.getColor(),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}