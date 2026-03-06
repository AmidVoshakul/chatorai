import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatorai/themes/app_theme.dart';

/// Unified loading indicator for chat messages
/// Shows animated dots only
class ChatLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const ChatLoadingIndicator({
    super.key,
    this.size = ChatoraiSizes.chatLoadingIndicatorDefaultSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    final indicatorColor =
        color ??
        (isDarkTheme ? ChatoraiColors.white70 : ChatoraiColors.mediumGray);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: ChatoraiSizes.loadingIndicatorMaxWidth,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.md,
        vertical: ChatoraiSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDarkTheme ? ChatoraiColors.darkGray : ChatoraiColors.lightGray,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xl),
        boxShadow: ChatoraiShadows.cardShadow,
      ),
      child: SpinKitThreeBounce(color: indicatorColor, size: size),
    );
  }
}

/// Alternative loading indicator with dots animation (similar to ChatMessage)
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

/// Animated dots for typing indicator
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
