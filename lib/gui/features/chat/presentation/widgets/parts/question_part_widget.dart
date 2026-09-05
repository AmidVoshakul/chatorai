import 'package:chatorai/core/chat/chat/chat_message.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class QuestionPartWidget extends StatelessWidget {
  final QuestionPart part;

  const QuestionPartWidget({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasAnswer = part.answer != null && part.answer!.isNotEmpty;
    final displayAnswer = part.parsedAnswer;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white38,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '# Question',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasAnswer)
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  part.question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ],
          ),
          if (hasAnswer && displayAnswer != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.sm,
                vertical: ChatoraiSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      displayAnswer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black,
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
