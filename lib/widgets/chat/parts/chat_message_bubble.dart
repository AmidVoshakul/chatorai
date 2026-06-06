import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/utils/format_time.dart';
import 'package:chatorai/widgets/chat/parts/text_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/reasoning_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/tool_call_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/tool_result_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/task_part_widget.dart';
import 'package:chatorai/widgets/chat/parts/question_part_widget.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return switch (message) {
      UserMessage m => _userBubble(m, context),
      AssistantMessage m => _assistantBubble(m, context),
      SystemMessage m => _systemBubble(m, context),
      ErrorMessage m => _errorBubble(m, context),
    };
  }

  Widget _userBubble(UserMessage m, BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.md,
            vertical: ChatoraiSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.files.isNotEmpty)
                ...m.files.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: ChatoraiIconSizes.sm),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            f,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SelectableText(m.content, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assistantBubble(AssistantMessage m, BuildContext context) {
    if (m.parts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.md,
            vertical: ChatoraiSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            boxShadow: ChatoraiShadows.cardShadow,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: ChatoraiBorderWidth.thinBold,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.model != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.model!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: ChatoraiSpacing.sm),
                    Text(
                      _formatTime(m.timestamp, context),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              if (m.model != null) const SizedBox(height: ChatoraiSpacing.sm),
              ...m.parts.map((part) => _buildPart(part, context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPart(MessagePart part, BuildContext context) {
    return switch (part) {
      TextPart p => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextPartWidget(part: p),
      ),
      ReasoningPart p => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ReasoningPartWidget(part: p),
      ),
      ToolCallPart p => ToolCallPartWidget(part: p),
      ToolResultPart p => ToolResultPartWidget(part: p),
      TaskPart p => TaskPartWidget(part: p),
      QuestionPart p => QuestionPartWidget(part: p),
    };
  }

  String _formatTime(DateTime dt, BuildContext context) {
    return formatMessageTime(dt, context: context);
  }

  Widget _systemBubble(SystemMessage m, BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatoraiSpacing.lg,
          vertical: ChatoraiSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.full),
        ),
        child: Text(
          m.content,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _errorBubble(ErrorMessage m, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            size: ChatoraiIconSizes.md,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: ChatoraiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                if (m.code != null)
                  Text(
                    m.code!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
