import 'package:flutter/material.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/themes/app_theme.dart';

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class ReasoningMessage extends StatefulWidget {
  final String reasoning;
  final bool isStreaming;

  const ReasoningMessage({
    super.key,
    required this.reasoning,
    this.isStreaming = false,
  });

  @override
  State<ReasoningMessage> createState() => _ReasoningMessageState();
}

// ===========================================================================
// STATE CLASS
// ===========================================================================

class _ReasoningMessageState extends State<ReasoningMessage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  static const _bubbleWidthRatio = 0.65;

  bool _isExpanded = false;
  bool _controllersInitialized = false;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  late final AnimationController _dotsController;

  // =======================================================================
  // LIFECYCLE
  // =======================================================================

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

    _controllersInitialized = true;

    if (widget.isStreaming) {
      _shimmerController.repeat();
      _dotsController.repeat();
    }
  }

  @override
  void didUpdateWidget(ReasoningMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_controllersInitialized) {
      return;
    }

    final isReasoningPhase = widget.isStreaming && widget.reasoning.isEmpty;

    if (isReasoningPhase) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
      if (!_dotsController.isAnimating) _dotsController.repeat();
    } else if (!widget.isStreaming) {
      if (_shimmerController.isAnimating) {
        _shimmerController.stop();
        _shimmerController.value = 0;
      }
      if (_dotsController.isAnimating) {
        _dotsController.stop();
        _dotsController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: _bubbleWidthRatio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(ChatoraiSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(localizations, theme),
              if (_isExpanded) ...[
                const SizedBox(height: ChatoraiSpacing.sm),
                _buildExpandedContent(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // HELPER WIDGETS
  // =======================================================================

  Widget _buildExpandedContent(ThemeData theme) {
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey.shade700;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Text(
          widget.reasoning,
          style: TextStyle(
            fontSize: ChatoraiFontSizes.sm,
            height: 1.4,
            color: textColor,
          ),
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
        final isStreaming = widget.isStreaming;

        final String dotsText;
        if (isStreaming) {
          final dotIndex = (_dotsController.value * 3).floor() % 4;
          dotsText = '.' * dotIndex;
        } else {
          dotsText = '';
        }

        Widget header = Row(
          children: [
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
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: ChatoraiIconSizes.md,
                color: textColor,
              ),
            ),
          ],
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
