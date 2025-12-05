import 'package:flutter/material.dart';

/// Утилиты для создания унифицированных SnackBar
class SnackbarUtils {
  /// Успешное действие (зеленый)
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }

  /// Ошибка (красный)
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.error,
      backgroundColor: Colors.red,
      duration: duration,
    );
  }

  /// Предупреждение (оранжевый)
  static void showWarningSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.warning,
      backgroundColor: Colors.orange,
      duration: duration,
    );
  }

  /// Информация (голубой)
  static void showInfoSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.info,
      backgroundColor: Colors.blue,
      duration: duration,
    );
  }

  /// Вторичное действие (фиолетовый)
  static void showSecondarySnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.circle,
      backgroundColor: Colors.purple,
      duration: duration,
    );
  }

  /// Сообщение о копировании (серый)
  static void showCopySnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.copy,
      backgroundColor: Colors.grey[700]!,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  /// Сообщение о подключении (синий)
  static void showConnectionSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.link,
      backgroundColor: Colors.blue[600]!,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Приватный метод для создания стилизованного SnackBar
  static void _showStyledSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}