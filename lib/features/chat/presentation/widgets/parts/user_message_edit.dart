import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/action_row.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserMessageEdit extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onSaveAndSend;
  final String? content;
  final String chatId;
  final String messageId;
  final SessionRepository sessionRepository;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;
  final int? cumulativeTokens;
  final int? contextLength;

  const UserMessageEdit({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    required this.onSaveAndSend,
    this.content,
    required this.chatId,
    required this.messageId,
    required this.sessionRepository,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
    this.cumulativeTokens,
    this.contextLength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: localizations.enterYourMessage,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
            style: TextStyle(
              fontSize: ChatoraiFontSizes.base,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                onPressed: onCancel,
                tooltip: localizations.cancel,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              )
            else
              TextButton(
                onPressed: onCancel,
                child: Text(localizations.cancel),
              ),
            const Spacer(),
            if (isMobile) ...[
              IconButton(
                icon: const Icon(Icons.check, size: 20, color: Colors.green),
                onPressed: onSave,
                tooltip: localizations.save,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.send,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                onPressed: onSaveAndSend,
                tooltip: localizations.saveAndSend,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ] else ...[
              TextButton(onPressed: onSave, child: Text(localizations.save)),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSaveAndSend,
                child: Text(localizations.saveAndSend),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ActionRow(
          isUser: true,
          isLastMessage: false,
          content: controller.text,
          chatId: chatId,
          messageId: messageId,
          sessionRepository: sessionRepository,
          onEdit: null,
          onMessageDeleted: onMessageDeleted,
          onMessageRegenerate: onMessageRegenerate,
          onContinuationSelected: onContinuationSelected,
          cumulativeTokens: cumulativeTokens,
          contextLength: contextLength,
          agentName: null,
          model: null,
          timestamp: null,
        ),
      ],
    );
  }
}
