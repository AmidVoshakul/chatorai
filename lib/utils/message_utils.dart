import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart' as ChatModels;

/// Утилиты для управления сообщениями
class MessageUtils {
  /// Удалить сообщение
  static Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
    required ChatStorageService chatStorageService,
    BuildContext? context,
  }) async {
    try {
      // Если context предоставлен, показываем подтверждение удаления
      if (context != null) {
        final String currentLanguage = _getCurrentLanguage(context);
        final String confirmText = currentLanguage == 'en' 
            ? 'Are you sure you want to delete this message?' 
            : 'Вы уверены, что хотите удалить это сообщение?';
        final String deleteText = currentLanguage == 'en' ? 'Delete' : 'Удалить';
        final String cancelText = currentLanguage == 'en' ? 'Cancel' : 'Отмена';
        
        final bool shouldDelete = await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Icon(Icons.warning, color: Colors.orange),
              content: Text(confirmText),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: Text(cancelText),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(
                    deleteText,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ?? false;

        // Если пользователь не подтвердил удаление
        if (!shouldDelete) {
          return false;
        }
      }

      // Удаляем сообщение из базы данных
      await chatStorageService.deleteMessageFromChat(chatId, messageId);
      
      // Если context предоставлен, показываем уведомление об успешном удалении
      if (context != null) {
        final String currentLanguage = _getCurrentLanguage(context);
        final String successText = currentLanguage == 'en' 
            ? 'Message deleted successfully' 
            : 'Сообщение успешно удалено';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successText),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      // Показываем уведомление об ошибке
      if (context != null) {
        final String currentLanguage = _getCurrentLanguage(context);
        final String errorText = currentLanguage == 'en' 
            ? 'Failed to delete message: $e' 
            : 'Ошибка удаления сообщения: $e';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return false;
    }
  }

  /// Редактировать сообщение
  static Future<String?> editMessage({
    required String currentContent,
    required BuildContext context,
  }) async {
    final TextEditingController controller = TextEditingController(text: currentContent);
    final String currentLanguage = _getCurrentLanguage(context);
    final String titleText = currentLanguage == 'en' ? 'Edit Message' : 'Редактировать сообщение';
    final String saveText = currentLanguage == 'en' ? 'Save' : 'Сохранить';
    final String cancelText = currentLanguage == 'en' ? 'Cancel' : 'Отмена';

    final String? newContent = await showDialog<String?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titleText),
          content: TextField(
            controller: controller,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: currentLanguage == 'en' ? 'Enter new message content' : 'Введите новое содержание сообщения',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: Text(saveText),
            ),
          ],
        );
      },
    );

    return newContent;
  }

  /// Копировать сообщение в буфер обмена
  static Future<void> copyMessage({
    required String content,
    required BuildContext context,
    String? senderName, // Имя отправителя для форматирования
  }) async {
    try {
      final String currentLanguage = _getCurrentLanguage(context);
      
      // Форматируем контент в markdown с указанием отправителя
      final String formattedContent = senderName != null 
          ? '### $senderName\n\n$content'
          : content;

      // Копируем в буфер обмена
      await Clipboard.setData(ClipboardData(text: formattedContent));
      
      // Показываем краткое сообщение об успехе
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.copy, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                currentLanguage == 'en' 
                    ? 'Copied to clipboard' 
                    : 'Скопировано в буфер',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      print('[MessageUtils] ✅ Message copied to clipboard');
    } catch (e) {
      print('[MessageUtils] ❌ Error copying message: $e');
      
      final String currentLanguage = _getCurrentLanguage(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLanguage == 'en' ? 'Failed to copy message' : 'Не удалось скопировать сообщение',
            style: const TextStyle(fontSize: 14),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          elevation: 6,
        ),
      );
    }
  }

  

  /// Поделиться сообщением
  static Future<void> shareMessage({
    required String content,
    required BuildContext context,
  }) async {
    final String currentLanguage = _getCurrentLanguage(context);
    final String shareText = currentLanguage == 'en' ? 'Share Message' : 'Поделиться сообщением';
    
    // Здесь должна быть логика分享
    // await Share.share(content);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(shareText),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Получить текущий язык
  static String _getCurrentLanguage(BuildContext context) {
    // Здесь должна быть логика получения текущего языка
    // Пока возвращаем 'en' по умолчанию
    return 'en';
  }

  /// Проверить, может ли сообщение быть удалено
  static bool canDeleteMessage(Message message) {
    // Системные сообщения нельзя удалять
    if (message.role == ChatModels.MessageRole.system) {
      return false;
    }
    
    // Можно добавить другие ограничения, например:
    // - Нельзя удалять сообщения старше N минут
    // - и т.д.
    return true;
  }

  /// Проверить, может ли сообщение быть отредактировано
  static bool canEditMessage(Message message) {
    // Можно добавить логику, например:
    // - Можно редактировать только свои сообщения
    // - Можно редактировать только в течение N минут
    // - и т.д.
    return message.role == ChatModels.MessageRole.user;
  }

  /// Получить список доступных действий для сообщения
  static List<MessageAction> getMessageActions(Message message) {
    final List<MessageAction> actions = [];

    if (canDeleteMessage(message)) {
      actions.add(MessageAction(
        icon: Icons.delete,
        label: 'Delete',
        localizedLabel: {'en': 'Delete', 'ru': 'Удалить'},
        action: MessageActionType.delete,
        color: Colors.red,
      ));
    }

    // Редактирование доступно только для user сообщений
    if (canEditMessage(message)) {
      actions.add(MessageAction(
        icon: Icons.edit,
        label: 'Edit',
        localizedLabel: {'en': 'Edit', 'ru': 'Редактировать'},
        action: MessageActionType.edit,
        color: Colors.blue,
      ));
    }

    // Копирование доступно для всех сообщений, кроме system
    if (message.role != ChatModels.MessageRole.system) {
      actions.add(MessageAction(
        icon: Icons.copy_all,
        label: 'Copy',
        localizedLabel: {'en': 'Copy', 'ru': 'Копировать'},
        action: MessageActionType.copy,
        color: Colors.grey,
      ));
    }

    // Шаринг доступен для всех сообщений, кроме system
    if (message.role != ChatModels.MessageRole.system) {
      actions.add(MessageAction(
        icon: Icons.share,
        label: 'Share',
        localizedLabel: {'en': 'Share', 'ru': 'Поделиться'},
        action: MessageActionType.share,
        color: Colors.green,
      ));
    }

    return actions;
  }
}

/// Тип действия с сообщением
enum MessageActionType {
  delete,
  edit,
  copy,
  share,
}

/// Действие с сообщением
class MessageAction {
  final IconData icon;
  final String label;
  final Map<String, String> localizedLabel;
  final MessageActionType action;
  final Color color;

  MessageAction({
    required this.icon,
    required this.label,
    required this.localizedLabel,
    required this.action,
    required this.color,
  });

  String getLocalizedLabel(String language) {
    return localizedLabel[language] ?? label;
  }
}