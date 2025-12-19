import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';
import 'package:gen_ui_chat_ai/models/chat_models.dart' as chat_models;
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';


// Initialize logger for this utility
final _logger = LogTags.message;

/// Утилиты для управления сообщениями
class MessageUtils {
  /// Удалить сообщение
  static Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
    required ChatStorageService chatStorageService,
    BuildContext? context,
  }) async {
    // Сохраняем локализации до любых асинхронных операций
    final AppLocalizations? localizations = context != null ? AppLocalizations.of(context) : null;

    try {
      // Если context предоставлен, показываем подтверждение удаления
      if (context != null && localizations != null) {
        final bool shouldDelete = await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Icon(Icons.warning, color: Colors.orange),
              content: Text(localizations.areYouSureYouWantToDeleteThisMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: Text(localizations.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(
                    localizations.delete,
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
      if (context != null && localizations != null) {
        SnackbarUtils.showSuccessSnackBar(
          context: context,
          message: localizations.messageDeletedSuccessfully,
          icon: Icons.delete,
        );
      }

      return true;
    } catch (e) {
      // Показываем уведомление об ошибке
      if (context != null && localizations != null) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: localizations.failedToDeleteMessage,
          icon: Icons.error,
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
    // Сохраняем локализации до асинхронной операции
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final EditMessageResult? result = await showDialog<EditMessageResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.edit),
          content: TextField(
            controller: controller,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: localizations.enterYourMessage,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.cancelled);
              },
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.saved);
              },
              child: Text(localizations.save),
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
              child: Text(localizations.saveAndSend),
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
    // Сохраняем локализации до асинхронной операции
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    final EditMessageResult? result = await showDialog<EditMessageResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.edit),
          content: TextField(
            controller: controller,
            maxLines: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: localizations.enterYourMessage,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.cancelled);
              },
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(EditMessageResult.saved);
              },
              child: Text(localizations.save),
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
              child: Text(localizations.saveAndSend),
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
      // Сохраняем локализации до асинхронной операции
      final AppLocalizations localizations = AppLocalizations.of(context)!;

      // Форматируем контент в markdown с указанием отправителя
      final String formattedContent = senderName != null 
          ? '### $senderName\n\n$content'
          : content;

      // Копируем в буфер обмена
      await Clipboard.setData(ClipboardData(text: formattedContent));
      
      // Показываем краткое сообщение об успехе
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.messageCopied,
        icon: Icons.copy,
        duration: const Duration(seconds: 1),
      );
      
      _logger.logInfo('[MessageUtils] Message copied to clipboard');
    } catch (e) {
      _logger.logError('[MessageUtils] Error copying message: $e');

      // Сохраняем локализации до асинхронной операции
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToCopyMessage,
        icon: Icons.error,
      );
    }
  }

  /// Поделиться сообщением
  static Future<void> shareMessage({
    required String content,
    required BuildContext context,
  }) async {
    // Сохраняем локализации до асинхронной операции
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    // Здесь должна быть логика分享
    // await Share.share(content);
    
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.messageShared,
      icon: Icons.share,
    );
  }

  /// Копировать весь чат в буфер обмена
  static Future<void> copyChat({
    required List<Message> messages,
    required String chatTitle,
    required BuildContext context,
  }) async {
    try {
      // Сохраняем локализации до асинхронной операции
      final AppLocalizations localizations = AppLocalizations.of(context)!;

      // Форматируем весь чат с заголовком и сообщениями
      final StringBuffer chatContent = StringBuffer();
      
      // Добавляем заголовок чата
      chatContent.writeln('# $chatTitle\n');
      chatContent.writeln('**Chat Date**: ${DateTime.now().toLocal().toString().split(' ').first}\n');
      chatContent.writeln('---\n\n');
      
      // Добавляем все сообщения
      for (final message in messages) {
        final String sender = message.role == chat_models.MessageRole.assistant
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
        message: localizations.copyChat,
        icon: Icons.copy_all,
      );
      
      _logger.logInfo('[MessageUtils] Chat copied to clipboard (${messages.length} messages)');
    } catch (e) {
      _logger.logError('[MessageUtils] Error copying chat: $e');

      // Сохраняем локализации до асинхронной операции
      final AppLocalizations localizations = AppLocalizations.of(context)!;
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.failedToCopyChat,
        icon: Icons.error,
      );
    }
  }

  /// Проверить, может ли сообщение быть удалено
  static bool canDeleteMessage(Message message) {
    // Системные сообщения нельзя удалять
    if (message.role == chat_models.MessageRole.system) {
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
    return message.role == chat_models.MessageRole.user;
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
    if (message.role != chat_models.MessageRole.system) {
      actions.add(MessageAction(
        icon: Icons.copy_all,
        label: 'Copy',
        localizedLabel: {'en': 'Copy', 'ru': 'Копировать'},
        action: MessageActionType.copy,
        color: Colors.grey,
      ));
    }

    // Шаринг доступен для всех сообщений, кроме system
    if (message.role != chat_models.MessageRole.system) {
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

  /// Get localized label for the current locale
  String getLocalizedLabel(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    // Try to get the localized label from the map, fallback to default label
    return localizedLabel[localizations.localeName] ?? label;
  }
}

/// Получить список доступных действий для чата
List<MessageAction> getChatActions(BuildContext context) {
  final AppLocalizations localizations = AppLocalizations.of(context)!;

  return [
    MessageAction(
      icon: Icons.copy_all,
      label: localizations.copyChat,
      localizedLabel: {'en': 'Copy Chat', 'ru': 'Копировать чат'},
      action: MessageActionType.copyChat,
      color: Colors.green,
    ),
    MessageAction(
      icon: Icons.share,
      label: localizations.shareChat,
      localizedLabel: {'en': 'Share', 'ru': 'Поделиться'},
      action: MessageActionType.share,
      color: Colors.blue,
    ),
    MessageAction(
      icon: Icons.edit,
      label: localizations.renameChat,
      localizedLabel: {'en': 'Rename', 'ru': 'Переименовать'},
      action: MessageActionType.edit,
      color: Colors.orange,
    ),
    MessageAction(
      icon: Icons.delete,
      label: localizations.deleteChat,
      localizedLabel: {'en': 'Delete', 'ru': 'Удалить'},
      action: MessageActionType.delete,
      color: Colors.red,
    ),
  ];
}