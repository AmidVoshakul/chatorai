import 'package:chatorai/core/chat/chat_models.dart' as chat_models;
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

final _logger = LogTags.message;

Future<void> copyMessage({
  required String content,
  required BuildContext context,
  String? senderName,
}) async {
  try {
    final localizations = AppLocalizations.of(context)!;

    final String formattedContent = senderName != null
        ? '### $senderName\n\n$content'
        : content;

    await Clipboard.setData(ClipboardData(text: formattedContent));

    if (!context.mounted) return;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.messageCopied,
      icon: Icons.copy,
      duration: const Duration(seconds: 1),
    );

    _logger.logInfo('[MessageUtils] Message copied to clipboard');
  } catch (e) {
    _logger.logError('[MessageUtils] Error copying message: $e');

    final localizations = AppLocalizations.of(context)!;
    if (!context.mounted) return;
    SnackbarUtils.showErrorSnackBar(
      context: context,
      message: localizations.failedToCopyMessage,
      icon: Icons.error,
    );
  }
}

Future<void> shareMessage({
  required String content,
  required BuildContext context,
}) async {
  final localizations = AppLocalizations.of(context)!;

  try {
    await Share.share(content);
  } catch (e) {
    if (!context.mounted) return;
    SnackbarUtils.showErrorSnackBar(
      context: context,
      message: localizations.failedToShareMessage,
    );
  }
}

Future<void> copyChat({
  required List<chat_models.Message> messages,
  required String chatTitle,
  required BuildContext context,
}) async {
  try {
    final localizations = AppLocalizations.of(context)!;

    final StringBuffer chatContent = StringBuffer();

    chatContent.writeln('# $chatTitle\n');
    chatContent.writeln(
      '**Chat Date**: ${DateTime.now().toLocal().toString().split(' ').first}\n',
    );
    chatContent.writeln('---\n\n');

    for (final message in messages) {
      final String sender = message.role == chat_models.MessageRole.assistant
          ? (message.model ?? 'AI')
          : 'You';

      chatContent.writeln('### $sender');
      chatContent.writeln('');
      chatContent.writeln(message.content);
      chatContent.writeln('');

      final String timeString = message.timestamp
          .toLocal()
          .toString()
          .split(' ')
          .last
          .split('.')
          .first;
      chatContent.writeln('_Sent at: $timeString');
      chatContent.writeln('');
      chatContent.writeln('---');
      chatContent.writeln('');
    }

    final String formattedChat = chatContent.toString().trim();

    await Clipboard.setData(ClipboardData(text: formattedChat));

    if (!context.mounted) return;
    SnackbarUtils.showSuccessSnackBar(
      context: context,
      message: localizations.copyChat,
      icon: Icons.copy_all,
    );

    _logger.logInfo(
      '[MessageUtils] Chat copied to clipboard (${messages.length} messages)',
    );
  } catch (e) {
    _logger.logError('[MessageUtils] Error copying chat: $e');

    final localizations = AppLocalizations.of(context)!;
    if (!context.mounted) return;
    SnackbarUtils.showErrorSnackBar(
      context: context,
      message: localizations.failedToCopyChat,
      icon: Icons.error,
    );
  }
}
