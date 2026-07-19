import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_title.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/format_utils.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Hover state per task part, kept in a provider so it survives widget rebuilds
/// (e.g. when the child session streams new tool results) without flicker.
class _TaskHoverState extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void set(String id, bool value) => state = {...state, id: value};
}

final _taskHoverProvider =
    NotifierProvider<_TaskHoverState, Map<String, bool>>(_TaskHoverState.new);

class TaskPartWidget extends ConsumerWidget {
  final TaskPart part;
  final VoidCallback? onTap;

  const TaskPartWidget({super.key, required this.part, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final part = this.part;
    final isRunning = part.status == TaskStatus.running;
    final isCompleted = part.status == TaskStatus.completed;
    final hasError = part.error != null && part.error!.isNotEmpty;
    final hoverKey = part.sessionId ?? '${part.agent}:${part.description}';
    final isHovered = ref.watch(_taskHoverProvider)[hoverKey] ?? false;

    // Live current tool: source it from the child session (like opencode,
    // which reads tool parts directly from the delegated session) so the
    // header updates in place as the subagent runs different tools.
    String? liveCurrentTool;
    String? liveCurrentTitle;
    // `part.sessionId` is resolved to the delegated child session id (see
    // session_to_chat_converter), so we can read the sub-agent's live tool
    // results directly from that session — like opencode, which sources tool
    // parts from the delegated session. The header then updates in place with
    // the sub-agent's current tool, e.g.
    // "Read test/test_task_abort.dart [offset=148, limit=45]", rendered
    // through the same toolTitle() formatter used for ordinary tool calls.
    if (part.sessionId != null) {
      // [TaskTrace] Widget reads live child tools. WHAT=render live header
      // WHERE=task_part_widget WHEN=${DateTime.now()} WHY=part.sessionId resolved
      // to child session → read its tool results.
      LogTags.chatScreen.logInfo(
        '[TaskTrace] build READ LIVE sessionId=${part.sessionId} '
        'agent=${part.agent} desc=${part.description}',
      );
      final results = ref.watch(
        childSessionToolResultsProvider(part.sessionId!),
      );
      final list = results.value ?? const <dynamic>[];
      if (list.isNotEmpty) {
        ToolResult? active;
        for (final r in list.reversed) {
          final t = r as ToolResult;
          if (t.status == 'running' || t.status == 'success') {
            active = t;
            break;
          }
        }
        active ??= list.last as ToolResult;
        liveCurrentTool = active.toolName;
        liveCurrentTitle = toolTitle(active.toolName, active.input);
      }
    }
    if (part.sessionId == null) {
      LogTags.chatScreen.logInfo(
        '[TaskTrace] build NO LIVE agent=${part.agent} desc=${part.description} '
        'currentTool=${part.currentTool} WHY=part.sessionId == null → widget uses fallback currentTool',
      );
    }
    final currentTool = liveCurrentTool ?? part.currentTool;
    final currentToolTitle = liveCurrentTitle ?? part.currentToolTitle;

    return MouseRegion(
      onEnter: (_) =>
          ref.read(_taskHoverProvider.notifier).set(hoverKey, true),
      onExit: (_) =>
          ref.read(_taskHoverProvider.notifier).set(hoverKey, false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
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
              opacity: isHovered ? 1.0 : ChatoraiOpacity.low,
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
                    currentTool != null &&
                    currentTool.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      '  ↳ ${currentToolTitle ?? _capitalize(currentTool)}'
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

    switch (part.status) {
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
