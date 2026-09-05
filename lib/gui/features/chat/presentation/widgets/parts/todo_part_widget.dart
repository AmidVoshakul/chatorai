import 'package:chatorai/core/chat/chat/chat_message.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TodoPartWidget extends StatelessWidget {
  final TodoPart part;
  final ValueChanged<int>? onToggle;

  const TodoPartWidget({super.key, required this.part, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(ChatoraiSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white38,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '# Todos',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white24 : Colors.black26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (int i = 0; i < part.todos.length; i++)
            _TodoItemRow(
              item: part.todos[i],
              index: i,
              isDark: isDark,
              theme: theme,
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
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onToggle;

  const _TodoItemRow({
    required this.item,
    required this.index,
    required this.isDark,
    required this.theme,
    this.onToggle,
  });

  bool get _isCompleted =>
      item.status == TodoStatus.completed ||
      item.status == TodoStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final accentColor = theme.colorScheme.primary.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Transform.translate(
            offset: const Offset(0, 2),
            child: _buildIcon(mutedColor, accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: _isCompleted ? TextDecoration.lineThrough : null,
                color: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(Color mutedColor, Color accentColor) {
    if (_isCompleted) {
      return Text('✓', style: TextStyle(color: accentColor));
    }

    if (item.status == TodoStatus.inProgress) {
      return Text('●', style: TextStyle(color: accentColor));
    }

    return Text('○', style: TextStyle(color: mutedColor));
  }
}
