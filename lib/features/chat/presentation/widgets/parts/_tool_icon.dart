import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

IconData toolIcon(String toolName) {
  switch (toolName.toLowerCase()) {
    case 'read':
    case 'question':
    case 'skill':
      return Icons.arrow_forward;
    case 'edit':
    case 'write':
      return Icons.arrow_back;
    case 'bash':
      return Icons.terminal;
    case 'glob':
    case 'grep':
      return Icons.search;
    case 'webfetch':
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
