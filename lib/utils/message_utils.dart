import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart' as ChatModels;
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';

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
  static Future<EditMessageResult> editMessage({
    required String currentContent,
    required BuildContext context,
  }) async {
    final TextEditingController controller = TextEditingController(text: currentContent);
    final String currentLanguage = _getCurrentLanguage(context);
    final String titleText = currentLanguage == 'en' ? 'Edit Message' : 'Редактировать сообщение';
    final String saveText = currentLanguage == 'en' ? 'Save' : 'Сохранить';
    final String saveAndSendText = currentLanguage == 'en' ? 'Save and Send' : 'Сохранить и отправить';
    final String cancelText = currentLanguage == 'en' ? 'Cancel' : 'Отмена';

    final EditMessageResult? result = await showDialog<EditMessageResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titleText),
          content: TextField(
            controller: controller,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: currentLanguage == 'en' ? 'Enter new message content' : 'Введите новое содержание сообщения',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.cancelled);
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.saved);
              },
              child: Text(saveText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.savedAndSent);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(saveAndSendText),
            ),
          ],
        );
      },
    );

    return result ?? EditMessageResult.cancelled;
  }

  /// Редактировать сообщение и получить новый контент
  static Future<EditMessageResultWithContent> editMessageWithResult({
    required String currentContent,
    required BuildContext context,
  }) async {
    final TextEditingController controller = TextEditingController(text: currentContent);
    final String currentLanguage = _getCurrentLanguage(context);
    final String titleText = currentLanguage == 'en' ? 'Edit Message' : 'Редактировать сообщение';
    final String saveText = currentLanguage == 'en' ? 'Save' : 'Сохранить';
    final String saveAndSendText = currentLanguage == 'en' ? 'Save and Send' : 'Сохранить и отправить';
    final String cancelText = currentLanguage == 'en' ? 'Cancel' : 'Отмена';

    final EditMessageResult? result = await showDialog<EditMessageResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titleText),
          content: TextField(
            controller: controller,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: currentLanguage == 'en' ? 'Enter new message content' : 'Введите новое содержание сообщения',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.cancelled);
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.saved);
              },
              child: Text(saveText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.savedAndSent);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(saveAndSendText),
            ),
          ],
        );
      },
    );

    return EditMessageResultWithContent(
      result: result ?? EditMessageResult.cancelled,
      newContent: controller.text,
    );
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
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: currentLanguage == 'en' 
            ? 'Copied to clipboard' 
            : 'Скопировано в буфер',
        icon: Icons.copy,
        duration: const Duration(seconds: 1),
      );
      
      print('[MessageUtils] ✅ Message copied to clipboard');
    } catch (e) {
      print('[MessageUtils] ❌ Error copying message: $e');
      
      final String currentLanguage = _getCurrentLanguage(context);
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: currentLanguage == 'en' ? 'Failed to copy message' : 'Не удалось скопировать сообщение',
        icon: Icons.error,
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

  /// Копировать весь чат в буфер обмена
  static Future<void> copyChat({
    required List<Message> messages,
    required String chatTitle,
    required BuildContext context,
  }) async {
    try {
      final String currentLanguage = _getCurrentLanguage(context);
      
      // Форматируем весь чат с заголовком и сообщениями
      final StringBuffer chatContent = StringBuffer();
      
      // Добавляем заголовок чата
      chatContent.writeln('# $chatTitle\n');
      chatContent.writeln('**Chat Date**: ${DateTime.now().toLocal().toString().split(' ').first}\n');
      chatContent.writeln('---\n\n');
      
      // Добавляем все сообщения
      for (final message in messages) {
        final String sender = message.role == ChatModels.MessageRole.assistant 
            ? (message.model ?? 'AI') 
            : 'You';
        
        chatContent.writeln('### $sender');
        chatContent.writeln('');
        chatContent.writeln(message.content);
        chatContent.writeln('');
        
        // Добавляем временную метку
        final String timeString = message.timestamp.toLocal().toString().split(' ').last.split('.').first;
        chatContent.writeln('_Sent at: $timeString');
        chatContent.writeln('');
        chatContent.writeln('---');
        chatContent.writeln('');
      }
      
      final String formattedChat = chatContent.toString().trim();
      
      // Копируем в буфер обмена
      await Clipboard.setData(ClipboardData(text: formattedChat));
      
      // Показываем успешное сообщение
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: currentLanguage == 'en' 
            ? 'Chat copied to clipboard' 
            : 'Чат скопирован в буфер',
        icon: Icons.copy_all,
      );
      
      print('[MessageUtils] ✅ Chat copied to clipboard (${messages.length} messages)');
    } catch (e) {
      print('[MessageUtils] ❌ Error copying chat: $e');
      
      final String currentLanguage = _getCurrentLanguage(context);
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: currentLanguage == 'en' ? 'Failed to copy chat' : 'Не удалось скопировать чат',
        icon: Icons.error,
      );
    }
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
  copyChat, // Добавляем действие для копирования всего чата
}

/// Результат редактирования сообщения
enum EditMessageResult {
  cancelled,
  saved,
  savedAndSent
}

/// Результат редактирования сообщения с текстом
class EditMessageResultWithContent {
  final EditMessageResult result;
  final String? newContent;

  EditMessageResultWithContent({
    required this.result,
    this.newContent,
  });
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

/// Получить список доступных действий для чата
List<MessageAction> getChatActions() {
  return [
    MessageAction(
      icon: Icons.copy_all,
      label: 'Copy Chat',
      localizedLabel: {'en': 'Copy Chat', 'ru': 'Копировать чат'},
      action: MessageActionType.copyChat,
      color: Colors.green,
    ),
    MessageAction(
      icon: Icons.share,
      label: 'Share',
      localizedLabel: {'en': 'Share', 'ru': 'Поделиться'},
      action: MessageActionType.share,
      color: Colors.blue,
    ),
    MessageAction(
      icon: Icons.edit,
      label: 'Rename',
      localizedLabel: {'en': 'Rename', 'ru': 'Переименовать'},
      action: MessageActionType.edit,
      color: Colors.orange,
    ),
    MessageAction(
      icon: Icons.delete,
      label: 'Delete',
      localizedLabel: {'en': 'Delete', 'ru': 'Удалить'},
      action: MessageActionType.delete,
      color: Colors.red,
    ),
  ];
}