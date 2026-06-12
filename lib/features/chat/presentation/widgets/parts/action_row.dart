import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/message_utils.dart';

/// Action row displayed below each message bubble.
/// Shows edit/share/copy/delete/regenerate/continue buttons.
class ActionRow extends StatelessWidget {
  final bool isUser;
  final bool isLastMessage;
  final String? content;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;

  const ActionRow({
    super.key,
    required this.isUser,
    required this.isLastMessage,
    this.content,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color?.withValues(
      alpha: ChatoraiIconOpacity.medium,
    );
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User message: Edit
        if (isUser && onEdit != null)
          IconButton(
            icon: Icon(
              Icons.edit,
              size: ChatoraiIconSizes.actionIcon,
              color: iconColor,
            ),
            onPressed: onEdit,
            splashRadius: 20,
            tooltip: localizations.edit,
          ),

        // Assistant message: Share
        if (!isUser)
          IconButton(
            icon: Icon(
              Icons.share,
              size: ChatoraiIconSizes.actionIcon,
              color: iconColor,
            ),
            onPressed: content != null
                ? () => MessageUtils.shareMessage(
                    content: content!,
                    context: context,
                  )
                : null,
            splashRadius: 20,
            tooltip: localizations.share,
          ),

        // All messages: Copy
        IconButton(
          icon: Icon(
            Icons.copy_all,
            size: ChatoraiIconSizes.actionIcon,
            color: theme.iconTheme.color?.withValues(alpha: 0.8),
          ),
          onPressed: content != null
              ? () => MessageUtils.copyMessage(
                  content: content!,
                  context: context,
                )
              : null,
          splashRadius: 24,
          hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          focusColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          tooltip: localizations.copyMessage,
        ),

        // All messages: Delete
        IconButton(
          icon: Icon(
            Icons.delete,
            size: ChatoraiIconSizes.actionIcon,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          onPressed: () async {
            FocusScope.of(context).unfocus();
            final deleted = await MessageUtils.deleteMessage(
              chatId: chatId,
              messageId: messageId,
              chatStorageService: chatStorageService,
              context: context,
            );
            if (deleted) {
              onMessageDeleted?.call();
            }
          },
          splashRadius: 20,
          tooltip: localizations.delete,
        ),

        // Assistant only: Regenerate
        if (!isUser)
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: ChatoraiIconSizes.actionIcon,
              color: iconColor,
            ),
            onPressed: () async {
              await MessageUtils.regenerateMessage(
                chatId: chatId,
                messageId: messageId,
                chatStorageService: chatStorageService,
                onRegenerate: () => onMessageRegenerate?.call(),
              );
            },
            splashRadius: 20,
            tooltip: localizations.regenerate,
          ),

        // Assistant only: Continue (conditional)
        if (!isUser &&
            isLastMessage &&
            content != null &&
            content!.isNotEmpty &&
            (content!.endsWith('...') || content!.split(' ').length > 30))
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              size: ChatoraiIconSizes.actionIcon,
              color: theme.colorScheme.primary.withValues(
                alpha: ChatoraiIconOpacity.medium,
              ),
            ),
            onPressed: onContinuationSelected != null
                ? () => onContinuationSelected!(content!)
                : null,
            splashRadius: 20,
            tooltip: localizations.continueResponse,
          ),
      ],
    );
  }
}
