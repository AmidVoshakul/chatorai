import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/models/chat_message.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';

class ReasoningPartWidget extends StatefulWidget {
  final ReasoningPart part;

  const ReasoningPartWidget({super.key, required this.part});

  @override
  State<ReasoningPartWidget> createState() => _ReasoningPartWidgetState();
}

class _ReasoningPartWidgetState extends State<ReasoningPartWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  late final AnimationController _dotsController;

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
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.part.isStreaming && widget.part.content.isEmpty) {
      _shimmerController.repeat();
      _dotsController.repeat();
    }
  }

  @override
  void didUpdateWidget(ReasoningPartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isReasoningPhase =
        widget.part.isStreaming && widget.part.content.isEmpty;
    if (isReasoningPhase) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
      if (!_dotsController.isAnimating) _dotsController.repeat();
    } else if (!widget.part.isStreaming) {
      _shimmerController.stop();
      _shimmerController.value = 0;
      _dotsController.stop();
      _dotsController.value = 0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _dotsController.dispose();
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
        padding: const EdgeInsets.all(ChatoraiSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
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
    );
  }

  Widget _buildContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: MarkdownBody(
          data: widget.part.content,
          styleSheet: ChatoraiMarkdownStyles.getMarkdownStyles(context),
          selectable: true,
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? localizations, ThemeData theme) {
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey.shade700;
    final headerText = localizations?.reasoning ?? 'Reasoning';

    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerAnimation, _dotsController]),
      builder: (context, child) {
        final isStreaming = widget.part.isStreaming;
        final String dotsText;
        if (isStreaming) {
          final dotIndex = (_dotsController.value * 3).floor() % 4;
          dotsText = '.' * dotIndex;
        } else {
          dotsText = '';
        }

        Widget header = GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: ChatoraiIconSizes.md,
                  color: textColor,
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.xs),
              Expanded(
                child: Text(
                  '$headerText$dotsText',
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.sm,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );

        if (isStreaming) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 + _shimmerAnimation.value, 0),
                end: Alignment(1 + _shimmerAnimation.value, 0),
                colors: [
                  textColor.withValues(alpha: 0.35),
                  textColor,
                  textColor.withValues(alpha: 0.35),
                ],
                stops: const [0.25, 0.5, 0.75],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: header,
          );
        }
        return header;
      },
    );
  }
}
