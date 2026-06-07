import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/themes/app_theme.dart';

class TodoPartWidget extends StatelessWidget {
  final TodoPart part;
  final ValueChanged<int>? onToggle;

  const TodoPartWidget({super.key, required this.part, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < part.todos.length; i++)
            _TodoItemRow(
              item: part.todos[i],
              index: i,
              onToggle: onToggle != null ? () => onToggle!(i) : null,
            ),
        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _isCompleted,
            onChanged: onToggle != null ? (_) => onToggle!() : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: theme.colorScheme.outline, width: 1),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: _isCompleted ? TextDecoration.lineThrough : null,
                color: _isCompleted
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
