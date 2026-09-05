import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/core/chat/chat_models.dart'
    as chat_models;
import 'package:chatorai/gui/shared/utils/message_action.dart';
import 'package:chatorai/gui/shared/utils/message_clipboard.dart' as clipboard;
import 'package:chatorai/gui/shared/utils/message_dialogs.dart';
import 'package:chatorai/gui/shared/utils/message_edit.dart' as edit;
import 'package:chatorai/gui/shared/utils/message_permissions.dart' as perm;
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/material.dart';

final _logger = LogTags.message;

class MessageUtils {
  static Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
    required SessionRepository sessionRepository,
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

      final sessionId = SessionID.fromString(
        chatId.startsWith('ses_') ? chatId : 'ses_$chatId',
      );
      await sessionRepository.appendEvent(
        MessageDeleted(
          sessionId: sessionId,
          messageId: messageId,
          timestamp: DateTime.now(),
        ),
      );

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
    required SessionRepository sessionRepository,
    required Function() onRegenerate,
    BuildContext? context,
  }) async {
    try {
      final sessionId = SessionID.fromString(
        chatId.startsWith('ses_') ? chatId : 'ses_$chatId',
      );
      await sessionRepository.appendEvent(
        MessageDeleted(
          sessionId: sessionId,
          messageId: messageId,
          timestamp: DateTime.now(),
        ),
      );
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
