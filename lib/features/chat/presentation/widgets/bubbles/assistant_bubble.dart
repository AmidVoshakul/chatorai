import 'package:chatorai/core/session/session_repository.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/continuation_suggestions.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/action_row.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/question_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/reasoning_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/task_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/text_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/todo_part_widget.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_result_part_widget.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

List<MessagePart> _groupConsecutiveParts(List<MessagePart> parts) {
  if (parts.isEmpty) return parts;

  final grouped = <MessagePart>[];
  MessagePart? current;

  for (final part in parts) {
    if (current == null) {
      current = part;
      continue;
    }

    if (part is ReasoningPart && current is ReasoningPart) {
      final durationMs = (current.durationMs != null && part.durationMs != null)
          ? current.durationMs! + part.durationMs!
          : null;
      current = ReasoningPart(
        content: '${current.content}\n${part.content}',
        title: current.title ?? part.title,
        isStreaming: current.isStreaming || part.isStreaming,
        startedAt: current.startedAt,
        durationMs: durationMs,
        isExpanded: current.isExpanded,
        synthetic: current.synthetic,
      );
      continue;
    }

    if (part is TextPart && current is TextPart) {
      current = TextPart(
        content: '${current.content}\n${part.content}',
        isStreaming: current.isStreaming || part.isStreaming,
        synthetic: current.synthetic,
      );
      continue;
    }

    grouped.add(current);
    current = part;
  }

  if (current != null) grouped.add(current);
  return grouped;
}

class AssistantMessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final String chatId;
  final String messageId;
  final String? agentName;
  final bool isCompactionSummary;
  final bool isLastMessage;
  final Future<void> Function(String)? onContinuationSelected;
  final VoidCallback? onMessageDeleted;
  final VoidCallback? onMessageRegenerate;
  final int? cumulativeTokens;
  final int? contextLength;
  final bool expandReasoningByDefault;
  final bool reasoningEnabled;
  final void Function(String? sessionId)? onTaskTap;
  final SessionRepository sessionRepository;

  const AssistantMessageBubble({
    super.key,
    required this.message,
    required this.chatId,
    required this.messageId,
    this.agentName,
    this.isCompactionSummary = false,
    this.isLastMessage = false,
    this.onContinuationSelected,
    this.onMessageDeleted,
    this.onMessageRegenerate,
    this.cumulativeTokens,
    this.contextLength,
    this.expandReasoningByDefault = true,
    this.reasoningEnabled = true,
    this.onTaskTap,
    required this.sessionRepository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final visibleParts = assistantVisibleParts(
      message.parts,
      reasoningEnabled: reasoningEnabled,
    );
    if (visibleParts.isEmpty) return const SizedBox.shrink();

    final textContent = visibleParts
        .whereType<TextPart>()
        .map((p) => p.content)
        .join('\n');

    final mergedParts = _groupConsecutiveParts(visibleParts);

    List<Widget> widgetParts = [];
    for (final part in mergedParts) {
      if (part is ReasoningPart) {
        widgetParts.add(
          ReasoningPartWidget(
            part: part,
            expandByDefault: expandReasoningByDefault,
          ),
        );
      } else {
        widgetParts.add(
          _buildPart(
            part,
            context,
            reasoningEnabled: reasoningEnabled,
            expandReasoningByDefault: expandReasoningByDefault,
            onTaskTap: onTaskTap,
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompactionSummary)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    localizations.compactionAgentName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.5,
                      ),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
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
            children: widgetParts,
          ),
        ),
        ActionRow(
          isUser: false,
          isLastMessage: isLastMessage && message.isStreaming,
          content: textContent,
          chatId: chatId,
          messageId: messageId,
          sessionRepository: sessionRepository,
          onEdit: null,
          onMessageDeleted: onMessageDeleted,
          onMessageRegenerate: onMessageRegenerate,
          onContinuationSelected: onContinuationSelected,
          cumulativeTokens: cumulativeTokens,
          contextLength: contextLength,
          agentName: agentName,
          isCompactionSummary: isCompactionSummary,
          model: message.model,
          timestamp: message.timestamp,
        ),
        if (!message.isStreaming && message.continuationSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ContinuationSuggestions(
              suggestions: message.continuationSuggestions,
              onSuggestionTap: onContinuationSelected ?? (String _) {},
            ),
          ),
      ],
    );
  }

  Widget _buildPart(
    MessagePart part,
    BuildContext context, {
    required bool reasoningEnabled,
    required bool expandReasoningByDefault,
    required void Function(String? sessionId)? onTaskTap,
  }) {
    return switch (part) {
      TextPart p => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: TextPartWidget(part: p),
      ),
      ReasoningPart p => ReasoningPartWidget(
        part: p,
        expandByDefault: expandReasoningByDefault,
      ),
      ToolResultPart p => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.sm),
        child: ToolResultPartWidget(part: p),
      ),
      TaskPart p => TaskPartWidget(
        part: p,
        onTap: onTaskTap != null ? () => onTaskTap(p.sessionId) : null,
      ),
      QuestionPart p => QuestionPartWidget(part: p),
      TodoPart p => TodoPartWidget(part: p),
      MessagePart() => const SizedBox.shrink(),
    };
  }
}

/// Filters parts that should be rendered inside the assistant bubble.
///
/// The `question` tool records both a [QuestionPart] (the question card with
/// the parsed answer) and a redundant [ToolResultPart] holding the raw JSON
/// tool response. The latter is hidden so the answer is not duplicated under
/// the question widget.
List<MessagePart> assistantVisibleParts(
  List<MessagePart> parts, {
  required bool reasoningEnabled,
}) {
  return parts.where((p) {
    if (p.synthetic) return false;
    if (p is ReasoningPart && !reasoningEnabled) return false;
    if (p is ToolResultPart && p.toolName.toLowerCase() == 'question') {
      return false;
    }
    return true;
  }).toList();
}
