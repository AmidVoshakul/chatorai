import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';

IconData toolIcon(String toolName) {
  switch (toolName.toLowerCase()) {
    case 'read':
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
      return Icons.public;
    case 'websearch':
      return Icons.travel_explore;
    case 'task':
      return Icons.person;
    default:
      return Icons.build;
  }
}

class ToolIcon extends StatelessWidget {
  final String toolName;
  final double size;

  const ToolIcon({
    super.key,
    required this.toolName,
    this.size = ChatoraiIconSizes.md,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(toolIcon(toolName), size: size);
  }
}
