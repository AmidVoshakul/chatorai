import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/widgets/chat/parts/_tool_icon.dart';
import 'package:chatorai/widgets/chat/parts/_tool_title.dart';

class ToolResultPartWidget extends StatefulWidget {
  final ToolResultPart part;

  const ToolResultPartWidget({super.key, required this.part});

  @override
  State<ToolResultPartWidget> createState() => _ToolResultPartWidgetState();
}

class _ToolResultPartWidgetState extends State<ToolResultPartWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final part = widget.part;
    final isError = part.error != null;
    final isRunning = part.state == ToolState.running;
    final isCompleted = part.state == ToolState.completed;

    return GestureDetector(
      onTap: () {
        if (isCompleted || isError) {
          setState(() => _isExpanded = !_isExpanded);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isError
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
          border: Border.all(
            color: isError
                ? theme.colorScheme.error.withValues(alpha: 0.3)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isRunning)
                  _RunningSpinner(color: theme.colorScheme.primary)
                else if (isCompleted)
                  Icon(Icons.check, size: 14, color: theme.colorScheme.primary)
                else if (isError)
                  Icon(Icons.close, size: 14, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                ToolIcon(toolName: part.toolName),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    toolTitle(part.toolName, part.input ?? {}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isError
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_isExpanded && (isCompleted || isError))
              _buildBody(theme, isError),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isError) {
    final body = isError ? widget.part.error! : widget.part.result!;
    if (body.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            body,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: ChatoraiFontSizes.sm,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _RunningSpinner extends StatelessWidget {
  final Color color;
  const _RunningSpinner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
