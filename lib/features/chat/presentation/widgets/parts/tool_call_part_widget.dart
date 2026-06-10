import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_icon.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_title.dart';

class ToolCallPartWidget extends StatelessWidget {
  final ToolCallPart part;

  const ToolCallPartWidget({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinKitThreeBounce(color: muted, size: 10),
        const SizedBox(width: 6),
        ToolIcon(toolName: part.toolName, color: muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            toolTitle(part.toolName, part.input),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
