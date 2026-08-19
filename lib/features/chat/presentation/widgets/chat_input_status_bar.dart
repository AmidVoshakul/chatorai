import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/features/chat/presentation/widgets/workspace_dialog.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart' as p;

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
    final tooltipStyle = TextStyle(
      color: ChatoraiColors.gray,
      fontSize: ChatoraiFontSizes.md,
    );
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
    final labelColor = color == ChatoraiColors.gray
        ? color
        : color.withValues(alpha: ChatoraiOpacity.low);

    return Tooltip(
      preferBelow: false,
      richMessage: _tooltipMessage(statuses),
      child: _StatusChip(
        icon: null,
        label: 'MCP: $connected/${statuses.length}',
        color: labelColor,
      ),
    );
  }

  Widget _buildLoadingChip() {
    return _StatusChip(
      icon: SizedBox(
        width: 12,
        height: 12,
        child: SpinKitCircle(size: 10, color: ChatoraiColors.gray),
      ),
      label: 'MCP…',
      color: ChatoraiColors.gray,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dir = ref.watch(workingDirProvider);
    final branch = ref.watch(gitBranchProvider).value;
    final mcpAsync = ref.watch(mcpStatusesProvider);
    final statuses = mcpAsync.value;

    final chips = <Widget>[];

    // Path chip
    chips.add(
      Tooltip(
        message: l10n.changeWorkingDirectory,
        preferBelow: false,
        child: _StatusChip(
          icon: Icon(
            Icons.folder_outlined,
            size: ChatoraiIconSizes.xxs,
            color: ChatoraiColors.gray,
          ),
          label: p.basename(dir),
          color: ChatoraiColors.gray,
          onTap: () => showWorkspaceDialog(context, ref),
        ),
      ),
    );

    // Branch chip
    if (branch != null && branch.isNotEmpty) {
      chips.add(
        _StatusChip(
          icon: null,
          label: '⎇ $branch',
          color: ChatoraiColors.gray,
          maxLabelWidth: 140,
        ),
      );
    }

    // MCP chip
    if (statuses != null && statuses.isNotEmpty) {
      chips.add(_buildMcpChip(context, statuses));
    } else if (mcpAsync.isLoading) {
      chips.add(_buildLoadingChip());
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: ChatoraiSpacing.xs,
        left: ChatoraiSpacing.lg,
        right: ChatoraiSpacing.lg,
      ),
      child: Wrap(spacing: ChatoraiSpacing.xs, runSpacing: 2, children: chips),
    );
  }
}

// ==== CHIP WIDGET ======================================================

class _StatusChip extends StatefulWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    this.maxLabelWidth,
    this.onTap,
  });

  final Widget? icon;
  final String label;
  final Color color;
  final double? maxLabelWidth;
  final VoidCallback? onTap;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = ChatoraiSettingsWindow.of(context);
    Widget textChild = Text(
      widget.label,
      style: TextStyle(color: widget.color, fontSize: ChatoraiFontSizes.sm),
    );
    if (widget.maxLabelWidth != null) {
      textChild = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxLabelWidth!),
        child: Text(
          widget.label,
          style: TextStyle(color: widget.color, fontSize: ChatoraiFontSizes.sm),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          const SizedBox(width: ChatoraiSpacing.xs),
        ],
        textChild,
      ],
    );

    final baseColor = palette.surface.withValues(alpha: 0.5);
    final hoverColor = palette.chipHover;

    return MouseRegion(
      onHover: (_) {
        if (!_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: ChatoraiDurations.fast,
          decoration: BoxDecoration(
            color: _hovered ? hoverColor : baseColor,
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xs),
            border: Border.all(
              color: palette.border.withValues(alpha: 0.55),
              width: ChatoraiBorderWidth.thin,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.xs,
            vertical: 2,
          ),
          child: child,
        ),
      ),
    );
  }
}
