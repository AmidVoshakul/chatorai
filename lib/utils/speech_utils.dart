import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';

/// Утилита для отображения статуса голосового ввода
class SpeechUtils {
  /// Получение иконки в зависимости от состояния
  static IconData getIcon(bool isListening, bool isAvailable) {
    if (!isAvailable) return Icons.mic_off;
    if (isListening) return Icons.stop;
    return Icons.mic;
  }

  /// Получение цвета в зависимости от состояния
  static Color getColor(ThemeData theme, bool isListening, bool isAvailable) {
    if (!isAvailable) return Colors.grey;
    if (isListening) return Colors.red;
    return theme.iconTheme.color ?? Colors.black;
  }

  /// Получение подсказки (tooltip)
  static String getTooltip(
    BuildContext context, 
    bool isListening, 
    bool isAvailable,
    bool hasText,
    bool hasAttachment,
  ) {
    final localizations = AppLocalizations.of(context)!;
    
    if (!isAvailable) return localizations.micUnavailable;
    if (hasText || hasAttachment) return localizations.sendMessage;
    if (isListening) return localizations.stopListening;
    return localizations.startListening;
  }

  /// Получение текста для отображения под полем ввода
  static String getStatusText(
    BuildContext context,
    bool isListening,
    bool isAvailable,
    bool hasError,
    String? errorMessage,
  ) {
    final localizations = AppLocalizations.of(context)!;
    
    if (hasError && errorMessage != null) return errorMessage;
    if (!isAvailable) return localizations.micUnavailable;
    if (isListening) return localizations.listening;
    return '';
  }

  /// Вибрация при начале/остановке прослушивания
  static Future<void> vibrate({bool start = true}) async {
    try {
      // Вибрация доступна только на мобильных устройствах
      // Для Flutter можно использовать пакет vibration, но здесь используем стандартный способ
      if (start) {
        // Короткая вибрация при старте
        // await HapticFeedback.lightImpact();
      } else {
        // Еще более короткая при остановке
        // await HapticFeedback.selectionClick();
      }
    } catch (e) {
      // Игнорируем ошибки вибрации
    }
  }

  /// Форматирование времени прослушивания
  static String formatListeningTime(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  /// Проверка, можно ли показать микрофон
  static bool canShowMicrophone({
    required bool isStreaming,
    required bool hasText,
    required bool hasAttachment,
  }) {
    // Микрофон показывается только когда:
    // 1. Не идет стриминг
    // 2. Поле ввода пустое
    // 3. Нет прикрепленных файлов
    return !isStreaming && !hasText && !hasAttachment;
  }
}
