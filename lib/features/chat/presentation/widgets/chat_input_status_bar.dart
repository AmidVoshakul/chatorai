import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Compact status line rendered beneath the chat input:
/// `<cwd>  ⎇ <branch>   mcp: <connected>/<total>`.
///
/// The path and branch are muted gray; the MCP segment is colored:
/// red when any server is `failed`/`needsAuth`/`needsClientRegistration`,
/// green when at least one server is `connected`, otherwise gray (e.g. all
/// disabled). The MCP segment is hidden when no servers are configured.
class ChatInputStatusBar extends ConsumerWidget {
  const ChatInputStatusBar({super.key});

  static Color mcpColor(Map<String, McpServerStatus> statuses) {
    final hasError = statuses.values.any(
      (s) =>
          s.status == McpConnectionStatus.failed ||
          s.status == McpConnectionStatus.needsAuth ||
          s.status == McpConnectionStatus.needsClientRegistration,
    );
    if (hasError) return ChatoraiColors.error;
    final connected = statuses.values
        .where((s) => s.status == McpConnectionStatus.connected)
        .length;
    if (connected > 0) return ChatoraiColors.success;
    return ChatoraiColors.gray;
  }

  static String _statusLabel(McpConnectionStatus status) {
    return switch (status) {
      McpConnectionStatus.connected => 'connected',
      McpConnectionStatus.disabled => 'disabled',
      McpConnectionStatus.failed => 'failed',
      McpConnectionStatus.needsAuth => 'needs auth',
      McpConnectionStatus.needsClientRegistration => 'needs registration',
    };
  }

  static Color _statusDotColor(McpConnectionStatus status) {
    return switch (status) {
      McpConnectionStatus.connected => ChatoraiColors.success,
      McpConnectionStatus.disabled => ChatoraiColors.gray,
      McpConnectionStatus.failed ||
      McpConnectionStatus.needsAuth ||
      McpConnectionStatus.needsClientRegistration => ChatoraiColors.error,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(workingDirProvider);
    final branch = ref.watch(gitBranchProvider).value;
    final statuses = ref.watch(mcpStatusesProvider).value;
    final theme = Theme.of(context);

    final spans = <InlineSpan>[
      TextSpan(
        text: dir,
        style: const TextStyle(color: ChatoraiColors.gray, fontSize: 12),
      ),
    ];

    if (branch != null && branch.isNotEmpty) {
      spans.add(
        TextSpan(
          text: '  ⎇ $branch',
          style: const TextStyle(color: ChatoraiColors.gray, fontSize: 12),
        ),
      );
    }

    if (statuses != null && statuses.isNotEmpty) {
      final connected = statuses.values
          .where((s) => s.status == McpConnectionStatus.connected)
          .length;
      final tooltipStyle =
          theme.tooltipTheme.textStyle ?? theme.textTheme.bodySmall;
      final tooltipMessage = TextSpan(
        children: [
          for (final entry in statuses.entries) ...[
            if (statuses.keys.first != entry.key) const TextSpan(text: '\n'),
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6.0),
                          decoration: BoxDecoration(
                            color: _statusDotColor(entry.value.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      TextSpan(text: '${entry.key}: ', style: tooltipStyle),
                      TextSpan(
                        text: _statusLabel(entry.value.status),
                        style: tooltipStyle?.copyWith(
                          color: ChatoraiColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Tooltip(
            preferBelow: false,
            richMessage: tooltipMessage,
            child: Text(
              '   MCP: $connected/${statuses.length}',
              style: TextStyle(color: mcpColor(statuses), fontSize: 12),
            ),
          ),
        ),
      );
    } else {
      final loading = ref.watch(mcpStatusesProvider).isLoading;
      if (loading) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: ChatoraiSpacing.sm),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: SpinKitCircle(size: 12, color: ChatoraiColors.gray),
                ),
                const SizedBox(width: ChatoraiSpacing.xs),
                const Text(
                  'MCP…',
                  style: TextStyle(color: ChatoraiColors.gray, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: ChatoraiSpacing.xs,
        left: ChatoraiSpacing.lg,
        right: ChatoraiSpacing.lg,
      ),
      child: Text.rich(
        TextSpan(children: spans),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
      ),
    );
  }
}
