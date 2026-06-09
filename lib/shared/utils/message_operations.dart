import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart'
    as chat_models;
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/message_action.dart';
import 'package:chatorai/shared/utils/message_dialogs.dart';
import 'package:chatorai/shared/utils/message_clipboard.dart' as clipboard;
import 'package:chatorai/shared/utils/message_edit.dart' as edit;
import 'package:chatorai/shared/utils/message_permissions.dart' as perm;

final _logger = LogTags.message;

class MessageUtils {
  static Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
    required ChatStorageService chatStorageService,
    BuildContext? context,
  }) async {
    final AppLocalizations? localizations = context != null
        ? AppLocalizations.of(context)
        : null;

    try {
      if (context != null && localizations != null) {
        final bool shouldDelete =
            await showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return KeyboardHandlerDialog(
                  onEnter: () => Navigator.of(dialogContext).pop(true),
                  onEscape: () => Navigator.of(dialogContext).pop(false),
                  child: AlertDialog(
                    title: const Icon(Icons.warning, color: Colors.orange),
                    content: Text(
                      localizations.areYouSureYouWantToDeleteThisMessage,
                    ),
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
                  ),
                );
              },
            ) ??
            false;

        if (!shouldDelete) {
          return false;
        }
      }

      await chatStorageService.deleteMessageFromChat(chatId, messageId);

      if (context != null && context.mounted && localizations != null) {
        SnackbarUtils.showSuccessSnackBar(
          context: context,
          message: localizations.messageDeletedSuccessfully,
          icon: Icons.delete,
        );
      }

      return true;
    } catch (e) {
      if (context != null && context.mounted && localizations != null) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: localizations.failedToDeleteMessage,
          icon: Icons.error,
        );
      }

      return false;
    }
  }

  static Future<EditMessageResult> editMessage({
    required String currentContent,
    required BuildContext context,
  }) => edit.editMessage(currentContent: currentContent, context: context);

  static Future<EditMessageResultWithContent> editMessageWithResult({
    required String currentContent,
    required BuildContext context,
  }) => edit.editMessageWithResult(
    currentContent: currentContent,
    context: context,
  );

  static Future<void> copyMessage({
    required String content,
    required BuildContext context,
    String? senderName,
  }) => clipboard.copyMessage(
    content: content,
    context: context,
    senderName: senderName,
  );

  static Future<void> shareMessage({
    required String content,
    required BuildContext context,
  }) => clipboard.shareMessage(content: content, context: context);

  static Future<void> copyChat({
    required List<chat_models.Message> messages,
    required String chatTitle,
    required BuildContext context,
  }) => clipboard.copyChat(
    messages: messages,
    chatTitle: chatTitle,
    context: context,
  );

  static bool canDeleteMessage(chat_models.Message message) =>
      perm.canDeleteMessage(message);

  static bool canEditMessage(chat_models.Message message) =>
      perm.canEditMessage(message);

  static bool canRegenerateMessage(chat_models.Message message) =>
      perm.canRegenerateMessage(message);

  static Future<bool> regenerateMessage({
    required String chatId,
    required String messageId,
    required ChatStorageService chatStorageService,
    required Function() onRegenerate,
    BuildContext? context,
  }) async {
    try {
      await chatStorageService.deleteMessageFromChat(chatId, messageId);
      onRegenerate();
      return true;
    } catch (e) {
      _logger.logError('[MessageUtils] Error regenerating message: $e');
      return false;
    }
  }

  static List<MessageAction> getMessageActions(chat_models.Message message) =>
      perm.getMessageActions(message);
}
