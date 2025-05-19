import 'package:flutter/material.dart';

class BadgeNotificationIcon extends StatelessWidget {
  final bool hasNotification; 
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const BadgeNotificationIcon({
    super.key,
    required this.hasNotification, 
    this.icon = Icons.notifications,
    required this.onPressed,
    this.tooltip = 'Notificaciones',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
        if (hasNotification) 
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10, 
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle, 
              ),
            ),
          ),
      ],
    );
  }
}