import 'package:flutter/material.dart';

enum SnackBarType { error, success, info }

class AppSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required SnackBarType type,
    Duration? duration,
  }) {
    final IconData icon;
    final Color backgroundColor;
    final Duration snackBarDuration;
    
    switch (type) {
      case SnackBarType.error:
        icon = Icons.error_outline;
        backgroundColor = Colors.red[700]!;
        snackBarDuration = duration ?? const Duration(seconds: 4);
        break;
      case SnackBarType.success:
        icon = Icons.check_circle_outline;
        backgroundColor = Colors.green[700]!;
        snackBarDuration = duration ?? const Duration(seconds: 3);
        break;
      case SnackBarType.info:
        icon = Icons.info_outline;
        backgroundColor = Colors.blue[700]!;
        snackBarDuration = duration ?? const Duration(seconds: 3);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: snackBarDuration,
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {}, 
        ),
      ),
    );
  }

  /// Método simplificado para mostrar errores
  static void showError({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
    );
  }

  /// Método simplificado para mostrar mensajes de éxito
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
    );
  }

  /// Método simplificado para mostrar información
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration? duration,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
    );
  }
}