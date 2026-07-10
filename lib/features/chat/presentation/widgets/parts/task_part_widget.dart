import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TaskPartWidget extends StatefulWidget {
  final TaskPart part;
  final VoidCallback? onTap;

  const TaskPartWidget({super.key, required this.part, this.onTap});

  @override
  State<TaskPartWidget> createState() => _TaskPartWidgetState();
}

class _TaskPartWidgetState extends State<TaskPartWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final part = widget.part;
    final isRunning = part.status == TaskStatus.running;
    final isCompleted = part.status == TaskStatus.completed;
    final hasError = part.error != null && part.error!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          ),
          child: Opacity(
            opacity: _isHovered ? 1.0 : ChatoraiOpacity.low,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _statusIcon(theme, isRunning: isRunning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${part.agent} Task — ${part.description}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (isRunning &&
                    part.currentTool != null &&
                    part.currentTool!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      '  ↳ ${_capitalize(part.currentTool!)} ${part.currentToolTitle ?? ""}'
                          .trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: ChatoraiFontSizes.xs,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (isRunning && hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      '  ↳ Retrying${part.retryAttempt != null ? " (attempt #${part.retryAttempt})" : ""} · ${part.error}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: ChatoraiFontSizes.xs,
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (isCompleted) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '└ ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: ChatoraiFontSizes.xs,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${part.toolCallsCount} toolcall${part.toolCallsCount == 1 ? "" : "s"} • ${formatDurationMs(part.durationMs)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: ChatoraiFontSizes.xs,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _statusIcon(ThemeData theme, {required bool isRunning}) {
    if (isRunning) {
      return SizedBox(
        width: 16,
        height: 16,
        child: SpinKitCircle(size: 16, color: theme.colorScheme.onSurface),
      );
    }

    switch (widget.part.status) {
      case TaskStatus.completed:
        return Text(
          '│',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: ChatoraiFontSizes.xs,
            fontWeight: FontWeight.w500,
          ),
        );
      case TaskStatus.error:
        return Icon(Icons.error, size: 16, color: theme.colorScheme.error);
      case TaskStatus.running:
        return SizedBox(
          width: 16,
          height: 16,
          child: SpinKitCircle(size: 16, color: theme.colorScheme.onSurface),
        );
    }
  }
}
