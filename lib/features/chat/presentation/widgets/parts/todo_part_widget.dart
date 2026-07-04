import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

class TodoPartWidget extends StatelessWidget {
  final TodoPart part;
  final ValueChanged<int>? onToggle;

  const TodoPartWidget({super.key, required this.part, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      ),
      child: Opacity(
        opacity: 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '# Todos',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (int i = 0; i < part.todos.length; i++)
              _TodoItemRow(
                item: part.todos[i],
                index: i,
                onToggle: onToggle != null ? () => onToggle!(i) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _TodoItemRow extends StatelessWidget {
  final TodoItem item;
  final int index;
  final VoidCallback? onToggle;

  const _TodoItemRow({required this.item, required this.index, this.onToggle});

  bool get _isCompleted =>
      item.status == TodoStatus.completed ||
      item.status == TodoStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = !_isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRunning)
            SizedBox(
              width: 16,
              height: 16,
              child: SpinKitCircle(
                size: 16,
                color: theme.colorScheme.onSurface,
              ),
            )
          else
            Checkbox(
              value: _isCompleted,
              onChanged: onToggle != null ? (_) => onToggle!() : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: theme.colorScheme.onSurface, width: 1),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: _isCompleted ? TextDecoration.lineThrough : null,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
