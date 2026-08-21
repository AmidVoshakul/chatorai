import 'dart:async';
import 'dart:math';

import 'package:chatorai/core/context/background_compaction_service.dart';
import 'package:chatorai/core/mcp/mcp_status_provider.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/features/chat/data/providers/session_context_usage_provider.dart';
import 'package:chatorai/features/chat/presentation/widgets/workspace_dialog.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/project_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart' as p;

class ChatInputStatusBar extends ConsumerWidget {
  const ChatInputStatusBar({super.key, this.onCompact});

  final Future<void> Function()? onCompact;

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
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: ChatoraiSpacing.xs,
              runSpacing: 2,
              children: chips,
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.xs),
          _ContextRingChip(onCompact: onCompact),
        ],
      ),
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

// ==== CONTEXT RING CHIP ====================================================

class _SegmentedProgressBar extends StatelessWidget {
  final double usedRatio;
  final double freeRatio;
  final double bufferRatio;

  const _SegmentedProgressBar({
    required this.usedRatio,
    required this.freeRatio,
    required this.bufferRatio,
  });

  @override
  Widget build(BuildContext context) {
    const height = 6.0;
    return CustomPaint(
      size: const Size(double.infinity, height),
      painter: _SegmentedProgressPainter(
        usedRatio: usedRatio,
        freeRatio: freeRatio,
        bufferRatio: bufferRatio,
      ),
    );
  }
}

class _SegmentedProgressPainter extends CustomPainter {
  final double usedRatio;
  final double freeRatio;
  final double bufferRatio;

  _SegmentedProgressPainter({
    required this.usedRatio,
    required this.freeRatio,
    required this.bufferRatio,
  });

  Color _usedColor(double ratio) {
    if (ratio < 0.5) {
      return Color.lerp(
        ChatoraiColors.success,
        ChatoraiColors.warning,
        ratio * 2,
      )!;
    } else if (ratio < 0.7) {
      return Color.lerp(
        ChatoraiColors.warning,
        ChatoraiColors.orange,
        (ratio - 0.5) * 5,
      )!;
    } else if (ratio < 0.9) {
      return Color.lerp(
        ChatoraiColors.orange,
        ChatoraiColors.error,
        (ratio - 0.7) * 5,
      )!;
    } else {
      return ChatoraiColors.error;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final usedWidth = size.width * usedRatio.clamp(0.0, 1.0);
    final bufferWidth = size.width * bufferRatio.clamp(0.0, 1.0);
    final freeWidth = max(0.0, size.width - usedWidth - bufferWidth);

    final usedPaint = Paint()..color = _usedColor(usedRatio);
    final freePaint = Paint()
      ..color = ChatoraiColors.gray.withValues(alpha: 0.3);

    if (usedWidth > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, usedWidth, height), usedPaint);
    }
    if (freeWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(usedWidth, 0, freeWidth, height),
        freePaint,
      );
    }
    if (bufferWidth > 0) {
      final bufferRect = Rect.fromLTWH(
        usedWidth + freeWidth,
        0,
        bufferWidth,
        height,
      );
      final bufferPaint = Paint()
        ..color = ChatoraiColors.warning.withValues(alpha: 0.25);
      canvas.drawRect(bufferRect, bufferPaint);

      canvas.save();
      canvas.clipRect(bufferRect);
      final hatchPaint = Paint()
        ..color = ChatoraiColors.warning.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      for (
        double i = bufferRect.left - height;
        i < bufferRect.left + bufferRect.width + height;
        i += 5
      ) {
        canvas.drawLine(
          Offset(i, bufferRect.top),
          Offset(i + height, bufferRect.bottom),
          hatchPaint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressPainter old) {
    return old.usedRatio != usedRatio ||
        old.freeRatio != freeRatio ||
        old.bufferRatio != bufferRatio;
  }
}

class _ContextRingChip extends StatefulWidget {
  const _ContextRingChip({this.onCompact});

  final Future<void> Function()? onCompact;

  @override
  State<_ContextRingChip> createState() => _ContextRingChipState();
}

class _ContextRingChipState extends State<_ContextRingChip> {
  OverlayEntry? _popupEntry;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _popupEntry?.remove();
    super.dispose();
  }

  void _showPopup(BuildContext context) {
    if (_popupEntry != null) return;
    _popupEntry = _ContextPopup(
      onCompact: widget.onCompact,
      onClose: () {
        _popupEntry?.remove();
        _popupEntry = null;
        if (mounted) setState(() {});
      },
      onHoverEnter: () {
        _hoverTimer?.cancel();
      },
      onHoverExit: _scheduleHide,
    ).createOverlayEntry();
    Overlay.of(context).insert(_popupEntry!);
  }

  void _scheduleHide() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 300), () {
      _popupEntry?.remove();
      _popupEntry = null;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final usage = ref.watch(sessionContextUsageProvider);
        final selectedModel = ref.watch(modelProvider).selectedModelObject;
        final isMobile = MediaQuery.of(context).size.width < 600;

        if (selectedModel == null) {
          return const SizedBox.shrink();
        }

        final ratio = usage.contextLength > 0
            ? usage.totalTokens / usage.contextLength
            : 0.0;
        final thresholds = BackgroundCompactionThresholds();
        final usableRatio = usage.contextLength > 0
            ? ((usage.contextLength - usage.buffer) / usage.contextLength)
                  .clamp(0.0, 1.0)
            : 1.0;
        final color = _ringColor(
          ratio,
          BackgroundCompactionThresholds(
            warningRatio: thresholds.warningRatio * usableRatio,
            hardRatio: thresholds.hardRatio * usableRatio,
          ),
        );

        const ringSize = 14.0;
        const strokeWidth = 2.0;

        return MouseRegion(
          onEnter: isMobile
              ? null
              : (_) {
                  _hoverTimer?.cancel();
                  _showPopup(context);
                },
          onExit: isMobile ? null : (_) => _scheduleHide(),
          child: GestureDetector(
            onTap: isMobile
                ? () {
                    _showPopup(context);
                  }
                : null,
            child: Container(
              width: ringSize,
              height: ringSize,
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(ringSize, ringSize),
                painter: _RingPainter(
                  progress: ratio.clamp(0.0, 1.0),
                  color: color,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _ringColor(double ratio, BackgroundCompactionThresholds thresholds) {
    if (ratio < thresholds.warningRatio) return ChatoraiColors.success;
    if (ratio < thresholds.hardRatio) return ChatoraiColors.warning;
    return ChatoraiColors.error;
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = ChatoraiColors.gray.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress || old.color != color;
  }
}

class _ContextPopup {
  const _ContextPopup({
    required this.onCompact,
    required this.onClose,
    this.onHoverEnter,
    this.onHoverExit,
  });

  final Future<void> Function()? onCompact;
  final VoidCallback onClose;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  OverlayEntry createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return _ContextPopupContent(
          onCompact: onCompact,
          onClose: onClose,
          onHoverEnter: onHoverEnter,
          onHoverExit: onHoverExit,
        );
      },
    );
  }
}

class _ContextPopupContent extends StatelessWidget {
  const _ContextPopupContent({
    required this.onCompact,
    required this.onClose,
    this.onHoverEnter,
    this.onHoverExit,
  });

  final Future<void> Function()? onCompact;
  final VoidCallback onClose;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final usage = ref.watch(sessionContextUsageProvider);
        final l10n = AppLocalizations.of(context)!;
        final percent = usage.contextLength > 0
            ? (usage.totalTokens / usage.contextLength * 100)
                  .clamp(0, 100)
                  .toStringAsFixed(0)
            : '0';
        final autoCompactPercent =
            (BackgroundCompactionThresholds().warningRatio * 100)
                .toStringAsFixed(0);

        final popupWidth = 280.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final rightMargin = ChatoraiSpacing.lg;
        final left = screenWidth - popupWidth - rightMargin;
        final effectiveLeft = left < 0 ? null : left;
        final effectiveRight = left < 0 ? rightMargin : null;

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Transparent barrier to detect outside taps
              Positioned.fill(
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Popup card
              Positioned(
                left: effectiveLeft,
                right: effectiveRight,
                bottom: 36,
                child: MouseRegion(
                  onEnter: (_) => onHoverEnter?.call(),
                  onExit: (_) => onHoverExit?.call(),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: popupWidth,
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: ChatoraiColors.premiumSurfaceRaised,
                        borderRadius: BorderRadius.circular(
                          ChatoraiBorderRadius.md,
                        ),
                        border: Border.all(
                          color: ChatoraiColors.premiumBorder,
                          width: ChatoraiBorderWidth.thinBold,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              ChatoraiSpacing.md,
                              ChatoraiSpacing.md,
                              ChatoraiSpacing.md,
                              ChatoraiSpacing.xs,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.contextMessages(
                                    percent,
                                    usage.contextLength.toString(),
                                    usage.totalTokens.toString(),
                                  ),
                                  style: TextStyle(
                                    fontSize: ChatoraiFontSizes.sm,
                                    color: ChatoraiColors.premiumText,
                                  ),
                                ),
                                const SizedBox(height: ChatoraiSpacing.xs),
                                _SegmentedProgressBar(
                                  usedRatio: usage.contextLength > 0
                                      ? (usage.totalTokens /
                                                usage.contextLength)
                                            .clamp(0.0, 1.0)
                                      : 0.0,
                                  freeRatio: usage.contextLength > 0
                                      ? ((usage.contextLength -
                                                    usage.totalTokens -
                                                    usage.buffer) /
                                                usage.contextLength)
                                            .clamp(0.0, 1.0)
                                      : 0.0,
                                  bufferRatio: usage.contextLength > 0
                                      ? (usage.buffer / usage.contextLength)
                                            .clamp(0.0, 1.0)
                                      : 0.0,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              ChatoraiSpacing.md,
                              0,
                              ChatoraiSpacing.md,
                              ChatoraiSpacing.xs,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                l10n.contextAutoCompactAt(
                                  usage.buffer.toString(),
                                  autoCompactPercent,
                                ),
                                style: TextStyle(
                                  fontSize: ChatoraiFontSizes.xs,
                                  color: ChatoraiColors.premiumTextMuted,
                                ),
                              ),
                            ),
                          ),
                          if (usage.sources.isNotEmpty) ...[
                            Divider(
                              height: 1,
                              thickness: ChatoraiBorderWidth.thin,
                              color: ChatoraiColors.premiumBorderSoft,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ChatoraiSpacing.md,
                                vertical: ChatoraiSpacing.xs,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.contextInstructions,
                                    style: TextStyle(
                                      fontSize: ChatoraiFontSizes.xs,
                                      color: ChatoraiColors.premiumTextMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: ChatoraiSpacing.xs),
                                  ...usage.sources.map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s.name,
                                              style: TextStyle(
                                                fontSize: ChatoraiFontSizes.xs,
                                                color:
                                                    ChatoraiColors.premiumText,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: ChatoraiSpacing.sm,
                                          ),
                                          Text(
                                            '${s.estimatedTokens} tokens',
                                            style: TextStyle(
                                              fontSize: ChatoraiFontSizes.xs,
                                              color: ChatoraiColors
                                                  .premiumTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Divider(
                            height: 1,
                            thickness: ChatoraiBorderWidth.thin,
                            color: ChatoraiColors.premiumBorderSoft,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ChatoraiSpacing.md,
                              vertical: ChatoraiSpacing.xs,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.contextUsageBreakdown,
                                  style: TextStyle(
                                    fontSize: ChatoraiFontSizes.xs,
                                    color: ChatoraiColors.premiumTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: ChatoraiSpacing.xs),
                                _UsageRow(
                                  label: l10n.contextPromptTokens,
                                  value: usage.usedTokens.toString(),
                                ),
                                _UsageRow(
                                  label: l10n.contextOutputTokens,
                                  value: usage.outputTokens.toString(),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: ChatoraiBorderWidth.thin,
                                  color: ChatoraiColors.premiumBorderSoft,
                                ),
                                _UsageRow(
                                  label: l10n.contextToolTokens,
                                  value: usage.toolTokens.toString(),
                                ),
                                if (usage.toolCallsCount > 0)
                                  _UsageRow(
                                    label: 'Tool calls',
                                    value: usage.toolCallsCount.toString(),
                                  ),
                                if (usage.cacheReadTokens > 0)
                                  _UsageRow(
                                    label: l10n.contextCacheRead,
                                    value: usage.cacheReadTokens.toString(),
                                  ),
                                if (usage.cacheWriteTokens > 0)
                                  _UsageRow(
                                    label: l10n.contextCacheWrite,
                                    value: usage.cacheWriteTokens.toString(),
                                  ),
                              ],
                            ),
                          ),
                          if (usage.spentUsd != null) ...[
                            Divider(
                              height: 1,
                              thickness: ChatoraiBorderWidth.thin,
                              color: ChatoraiColors.premiumBorderSoft,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ChatoraiSpacing.md,
                                vertical: ChatoraiSpacing.xs,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.contextSpentLabel,
                                    style: TextStyle(
                                      fontSize: ChatoraiFontSizes.xs,
                                      color: ChatoraiColors.premiumTextMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: ChatoraiSpacing.sm),
                                  Text(
                                    '\$${usage.spentUsd!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: ChatoraiFontSizes.sm,
                                      color: ChatoraiColors.orange,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (onCompact != null && usage.usedTokens > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                ChatoraiSpacing.md,
                                0,
                                ChatoraiSpacing.md,
                                ChatoraiSpacing.md,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: _CompactButton(
                                  onCompact: onCompact!,
                                  onClose: onClose,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.xs,
                color: ChatoraiColors.premiumText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.xs,
              color: ChatoraiColors.premiumTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactButton extends StatefulWidget {
  const _CompactButton({required this.onCompact, required this.onClose});

  final Future<void> Function() onCompact;
  final VoidCallback onClose;

  @override
  State<_CompactButton> createState() => _CompactButtonState();
}

class _CompactButtonState extends State<_CompactButton> {
  bool _isCompacting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: _isCompacting
          ? null
          : () async {
              setState(() => _isCompacting = true);
              try {
                await widget.onCompact();
              } finally {
                if (mounted) {
                  setState(() => _isCompacting = false);
                  widget.onClose();
                }
              }
            },
      icon: _isCompacting
          ? SizedBox(
              width: 16,
              height: 16,
              child: SpinKitCircle(
                size: 14,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.compress_outlined, size: 16),
      label: Text(
        _isCompacting ? l10n.contextCompacting : l10n.contextCompactSession,
      ),
      style: FilledButton.styleFrom(
        backgroundColor: ChatoraiColors.orange,
        foregroundColor: ChatoraiColors.pureWhite,
        padding: const EdgeInsets.symmetric(
          horizontal: ChatoraiSpacing.md,
          vertical: ChatoraiSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        ),
      ),
    );
  }
}
