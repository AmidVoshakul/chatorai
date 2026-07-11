import 'dart:math';

import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// CHAT LOADING INDICATOR — shimmer text
// ===========================================================================

class ChatLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const ChatLoadingIndicator({
    super.key,
    this.size = ChatoraiSizes.chatLoadingIndicatorDefaultSize,
    this.color,
  });

  @override
  State<ChatLoadingIndicator> createState() => _ChatLoadingIndicatorState();
}

class _ChatLoadingIndicatorState extends State<ChatLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;
  late final int _messageIndex;

  @override
  void initState() {
    super.initState();
    _messageIndex = Random().nextInt(5);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    final messages = [
      l10n.loadingMsg1,
      l10n.loadingMsg2,
      l10n.loadingMsg3,
      l10n.loadingMsg4,
      l10n.loadingMsg5,
    ];

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + _shimmerAnimation.value, 0),
              end: Alignment(1 + _shimmerAnimation.value, 0),
              colors: [
                color.withValues(alpha: 0.35),
                color,
                color.withValues(alpha: 0.35),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            messages[_messageIndex],
            style: TextStyle(
              fontSize: ChatoraiFontSizes.md,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.4,
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// CHAT TYPING DOTS INDICATOR
// ===========================================================================

class ChatTypingDotsIndicator extends StatelessWidget {
  final double dotSize;
  final Color? color;

  const ChatTypingDotsIndicator({
    super.key,
    this.dotSize = ChatoraiSizes.chatTypingDotsDefaultSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor =
        color ??
        theme.iconTheme.color?.withValues(alpha: ChatoraiIconOpacity.medium);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.md,
        vertical: ChatoraiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        boxShadow: ChatoraiShadows.cardShadow,
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: ChatoraiBorderWidth.thinBold,
        ),
      ),
      child: _TypingDotsAnimation(dotSize: dotSize, color: indicatorColor),
    );
  }
}

// ===========================================================================
// PRIVATE: TYPING DOTS ANIMATION
// ===========================================================================

class _TypingDotsAnimation extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const _TypingDotsAnimation({required this.dotSize, this.color});

  @override
  __TypingDotsAnimationState createState() => __TypingDotsAnimationState();
}

class __TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [_buildDot(0), _buildDot(1), _buildDot(2)]);
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final baseValue = index * 0.33;
        final opacity =
            _controller.value >= baseValue &&
                _controller.value < baseValue + 0.33
            ? 1.0
            : 0.3;
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.dotSize / 2),
        ),
      ),
    );
  }
}
