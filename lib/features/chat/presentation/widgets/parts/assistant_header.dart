import 'package:chatorai/shared/utils/format_time_utils.dart';
import 'package:flutter/material.dart';

/// Header widget showing model name and timestamp
/// displayed at the bottom of an assistant message bubble.
class AssistantHeader extends StatelessWidget {
  final String model;
  final DateTime timestamp;

  const AssistantHeader({
    super.key,
    required this.model,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime = formatMessageTime(timestamp, context: context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$model · $formattedTime',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
