import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:path/path.dart' as p;
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

  static TextSpan _tooltipMessage(Map<String, McpServerStatus> statuses) {
    final tooltipStyle =
        TextStyle(color: ChatoraiColors.gray, fontSize: ChatoraiFontSizes.md);
    return TextSpan(
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
                      style: tooltipStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMcpChip(
    BuildContext context,
    Map<String, McpServerStatus> statuses,
  ) {
    final connected = statuses.values
        .where((s) => s.status == McpConnectionStatus.connected)
        .length;
    final color = mcpColor(statuses);

    return Tooltip(
      preferBelow: false,
      richMessage: _tooltipMessage(statuses),
      child: _StatusChip(
        icon: null,
        label: 'MCP: $connected/${statuses.length}',
        color: color,
      ),
    );
  }

  Widget _buildLoadingChip() {
    return _StatusChip(
      icon: SizedBox(
        width: 12,
        height: 12,
        child: SpinKitCircle(size: 12, color: ChatoraiColors.gray),
      ),
      label: 'MCP…',
      color: ChatoraiColors.gray,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(workingDirProvider);
    final branch = ref.watch(gitBranchProvider).value;
    final statuses = ref.watch(mcpStatusesProvider).value;
    final palette = ChatoraiSettingsWindow.of(context);

    final chips = <Widget>[];

    // Path chip
    chips.add(
      Tooltip(
        message: ref.watch(absoluteWorkingDirProvider),
        preferBelow: false,
        child: _StatusChip(
          icon: Icon(
            Icons.folder_outlined,
            size: ChatoraiIconSizes.xs,
            color: palette.textMuted,
          ),
          label: p.basename(dir),
          color: palette.textMuted,
        ),
      ),
    );

    // Branch chip
    if (branch != null && branch.isNotEmpty) {
      chips.add(
        _StatusChip(
          icon: null,
          label: '⎇ $branch',
          color: palette.textMuted,
        ),
      );
    }

    // MCP chip
    if (statuses != null && statuses.isNotEmpty) {
      chips.add(_buildMcpChip(context, statuses));
    } else {
      final loading = ref.watch(mcpStatusesProvider).isLoading;
      if (loading) {
        chips.add(_buildLoadingChip());
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: ChatoraiSpacing.xs,
        left: ChatoraiSpacing.lg,
        right: ChatoraiSpacing.lg,
      ),
      child: Wrap(
        spacing: ChatoraiSpacing.sm,
        runSpacing: 4,
        children: chips,
      ),
    );
  }
}

// ==== CHIP WIDGET ======================================================

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final Widget? icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = ChatoraiSettingsWindow.of(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: ChatoraiSpacing.xs),
        ],
        Text(
          label,
          style: TextStyle(color: color, fontSize: ChatoraiFontSizes.md),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.55),
          width: ChatoraiBorderWidth.thin,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.sm,
        vertical: 3,
      ),
      child: child,
    );
  }
}
