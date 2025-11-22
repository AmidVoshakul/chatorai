import 'package:flutter/material.dart';

/// Универсальный класс для показа красивых сообщений в приложении
/// 
/// Примеры использования:
/// ```dart
/// // Успешное сообщение (зеленый)
/// UIHelper.showSuccessSnackBar(context, 'Модель успешно изменена!');
/// 
/// // Сообщение об ошибке (красный)
/// UIHelper.showErrorSnackBar(context, 'Ошибка загрузки: проверьте подключение');
/// 
/// // Информационное сообщение (синий)
/// UIHelper.showInfoSnackBar(context, 'Новая версия доступна для обновления');
/// 
/// // Предупреждающее сообщение (оранжевый)
/// UIHelper.showWarningSnackBar(context, 'Эта операция не может быть отменена');
/// ```
class UIHelper {
  /// Показ успешного сообщения в зеленых тонах
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF2D7D50) // Темно-зеленый для темной темы
            : const Color(0xFF4CAF50), // Стандартный зеленый для светлой темы
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF4CAF50).withAlpha(76) 
                : const Color(0xFF4CAF50).withAlpha(51),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 250),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Показ сообщения об ошибке in красных тонах
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF7D3C3C) // Темно-красный для темной темы
            : const Color(0xFFD32F2F), // Стандартный красный для светлой темы
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFD32F2F).withAlpha(76) 
                : const Color(0xFFD32F2F).withAlpha(51),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 250),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Показ информационного сообщения in синих тонах
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E4DB0) // Темно-синий для темной темы
            : const Color(0xFF2196F3), // Стандартный синий для светлой темы
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF2196F3).withAlpha(76) 
                : const Color(0xFF2196F3).withAlpha(51),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 250),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Показ предупреждающего сообщения in оранжевых тонах
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF8F5A0A) // Темно-оранжевый для темной темы
            : const Color(0xFFFF9800), // Стандартный оранжевый для светлой темы
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFFF9800).withAlpha(76) 
                : const Color(0xFFFF9800).withAlpha(51),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 250),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Показ сообщения о копировании
  static void showCopySnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF4A5568) // Темно-серый для темной темы
            : const Color(0xFF4A5568), // Серый для светлой темы
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF4A5568).withAlpha(76) 
                : const Color(0xFF4A5568).withAlpha(51),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 2),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 250),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Показ сообщения о подключении
  static void showConnectionSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.link, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF2F80ED) // Темно-синий для темной темы
            : const Color(0xFF3B82F6), // Стандартный синий для светлой темы
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF3B82F6).withAlpha(76) 
                : const Color(0xFF3B82F6).withAlpha(51),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 250),
          ),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
}