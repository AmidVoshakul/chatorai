import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

IconData toolIcon(String toolName) {
  switch (toolName.toLowerCase()) {
    case 'read':
      return Icons.arrow_forward;
    case 'question':
    case 'skill':
      return Icons.arrow_forward;
    case 'edit':
      return Icons.arrow_back;
    case 'write':
      return Icons.arrow_back;
    case 'bash':
      return Icons.terminal;
    case 'glob':
      return Icons.shuffle;
    case 'grep':
      return Icons.search;
    case 'webfetch':
      return Icons.read_more;
    case 'apply_patch':
      return Icons.public;
    case 'websearch':
      return Icons.travel_explore;
    case 'task':
      return Icons.more_horiz;
    case 'todowrite':
      return Icons.check_circle;
    default:
      return Icons.build;
  }
}

IconData toolIconForState(String toolName, ToolState state) {
  if (state == ToolState.completed) return Icons.check;
  if (state == ToolState.error) return Icons.close;
  return toolIcon(toolName);
}

class ToolIcon extends StatelessWidget {
  final String toolName;
  final double size;
  final Color? color;

  const ToolIcon({
    super.key,
    required this.toolName,
    this.size = ChatoraiIconSizes.md,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      toolIcon(toolName),
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
