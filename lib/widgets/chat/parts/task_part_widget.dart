import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/themes/app_theme.dart';

class TaskPartWidget extends StatelessWidget {
  final TaskPart part;
  final VoidCallback? onTap;

  const TaskPartWidget({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = part.subtaskCount > 0
        ? part.completedCount / part.subtaskCount
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      ),
      child: Row(
        children: [
          _statusIcon(theme),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  part.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  part.agent,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: ChatoraiFontSizes.xs,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (part.subtaskCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${part.completedCount}/${part.subtaskCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: ChatoraiFontSizes.xs,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(ThemeData theme) {
    switch (part.status) {
      case TaskStatus.running:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        );
      case TaskStatus.completed:
        return Icon(Icons.check_circle, size: 16, color: Colors.green);
      case TaskStatus.error:
        return Icon(Icons.error, size: 16, color: theme.colorScheme.error);
    }
  }
}
