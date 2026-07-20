import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

IconData toolIcon(String toolName) {
  switch (toolName.toLowerCase()) {
    case 'read':
      return Icons.visibility;
    case 'question':
    case 'skill':
      return Icons.attachment_outlined;
    case 'edit':
      return Icons.edit_note;
    case 'write':
      return Icons.arrow_back;
    case 'bash':
      return Icons.terminal;
    case 'glob':
      return Icons.manage_search_rounded;
    case 'grep':
      return Icons.find_in_page;
    case 'webfetch':
      return Icons.read_more;
    case 'apply_patch':
      return Icons.public;
    case 'websearch':
      return Icons.travel_explore;
    case 'task':
      return Icons.more_horiz;
    case 'todowrite':
      return Icons.wrap_text;
    default:
      return Icons.settings_suggest_sharp;
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
