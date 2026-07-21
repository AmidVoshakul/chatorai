import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/repositories/chat_storage_service.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/action_row.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserMessageBubble extends StatelessWidget {
  final UserMessage message;
  final String chatId;
  final String messageId;
  final ChatStorageService chatStorageService;
  final VoidCallback? onEdit;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final Future<void> Function(String)? onContinuationSelected;
  final int? cumulativeTokens;
  final int? contextLength;
  final DateTime? timestamp;
  final double maxWidth;

  const UserMessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.messageId,
    required this.chatStorageService,
    this.onEdit,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.onContinuationSelected,
    this.cumulativeTokens,
    this.contextLength,
    this.timestamp,
    this.maxWidth = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMaxWidth = maxWidth > 1.0
            ? maxWidth
            : constraints.maxWidth * maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatoraiSpacing.md,
                    vertical: ChatoraiSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ChatoraiBorderRadius.md,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.files.isNotEmpty)
                        ...message.files.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              f,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      Text(message.content, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
            ActionRow(
              isUser: true,
              isLastMessage: false,
              content: message.content,
              chatId: chatId,
              messageId: messageId,
              chatStorageService: chatStorageService,
              onEdit: onEdit,
              onMessageDeleted: onMessageDeleted,
              onMessageRegenerate: onMessageRegenerate,
              onContinuationSelected: onContinuationSelected,
              cumulativeTokens: cumulativeTokens,
              contextLength: contextLength,
              agentName: null,
              model: null,
              timestamp: timestamp,
            ),
          ],
        );
      },
    );
  }
}
