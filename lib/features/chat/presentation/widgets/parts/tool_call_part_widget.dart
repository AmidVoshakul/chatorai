import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_icon.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/_tool_title.dart';

class ToolCallPartWidget extends StatelessWidget {
  final ToolCallPart part;

  const ToolCallPartWidget({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpinKitThreeBounce(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            size: 10,
          ),
          const SizedBox(width: 6),
          ToolIcon(toolName: part.toolName),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              toolTitle(part.toolName, part.input),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
