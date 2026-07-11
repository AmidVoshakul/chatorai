import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ReasoningPartWidget extends StatefulWidget {
  final ReasoningPart part;
  final String? partKey;
  final bool expandByDefault;

  const ReasoningPartWidget({
    super.key,
    required this.part,
    this.partKey,
    this.expandByDefault = true,
  });

  @override
  State<ReasoningPartWidget> createState() => _ReasoningPartWidgetState();
}

class _ReasoningPartWidgetState extends State<ReasoningPartWidget>
    with TickerProviderStateMixin {
  late bool _isExpanded;

  Duration? _thoughtDuration;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    if (widget.part.isStreaming) {
      _shimmerController.repeat();
    }
    _isExpanded = widget.expandByDefault;
  }

  @override
  void didUpdateWidget(ReasoningPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.part.isStreaming) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
    } else {
      _shimmerController.stop();
      _shimmerController.value = 0;

      if (oldWidget.part.isStreaming &&
          widget.part.startedAt != null &&
          _thoughtDuration == null) {
        _thoughtDuration = DateTime.now().difference(widget.part.startedAt!);
      }
    }

    if (oldWidget.expandByDefault != widget.expandByDefault) {
      setState(() => _isExpanded = widget.expandByDefault);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(ChatoraiSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        ),
        child: Opacity(
          opacity: ChatoraiOpacity.low,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(localizations, theme),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: ChatoraiSpacing.sm),
                  child: _buildContent(),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    return DefaultTextStyle(
      style: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
      child: MarkdownBody(
        data: widget.part.content,
        styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
        selectable: true,
      ),
    );
  }

  String? get _displayDuration {
    if (widget.part.durationMs != null) {
      return formatDurationMs(widget.part.durationMs!);
    }
    if (_thoughtDuration != null) return formatDuration(_thoughtDuration!);
    return null;
  }

  Widget _buildHeader(AppLocalizations? localizations, ThemeData theme) {
    final isStreaming = widget.part.isStreaming;
    final orange = theme.colorScheme.primary;

    if (isStreaming) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Row(
              children: [
                SpinKitCircle(color: orange, size: 16),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1 + _shimmerAnimation.value, 0),
                      end: Alignment(1 + _shimmerAnimation.value, 0),
                      colors: [
                        orange.withValues(alpha: 0.35),
                        orange,
                        orange.withValues(alpha: 0.35),
                      ],
                      stops: const [0.25, 0.5, 0.75],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    'Thinking',
                    style: TextStyle(
                      fontSize: ChatoraiFontSizes.sm,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: orange,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    final durationStr = _displayDuration;
    final thoughtLabel = durationStr != null
        ? 'Thought: $durationStr'
        : 'Thought:';

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AnimatedRotation(
            turns: _isExpanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.chevron_right, size: 14, color: orange),
          ),
          const SizedBox(width: 8),
          Text(
            thoughtLabel,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.sm,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: orange,
            ),
          ),
        ],
      ),
    );
  }
}
