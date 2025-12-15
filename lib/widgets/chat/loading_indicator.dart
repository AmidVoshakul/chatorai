import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Unified loading indicator for chat messages
/// Shows animated dots only
class ChatLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const ChatLoadingIndicator({
    super.key,
    this.size = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    final indicatorColor = color ?? (isDarkTheme ? Colors.white70 : Colors.black54);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 60,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SpinKitThreeBounce(
        color: indicatorColor,
        size: size,
      ),
    );
  }
}

/// Alternative loading indicator with dots animation (similar to ChatMessage)
class ChatTypingDotsIndicator extends StatelessWidget {
  final double dotSize;
  final Color? color;

  const ChatTypingDotsIndicator({
    super.key,
    this.dotSize = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.iconTheme.color?.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: _TypingDotsAnimation(
        dotSize: dotSize,
        color: indicatorColor,
      ),
    );
  }
}

/// Animated dots for typing indicator
class _TypingDotsAnimation extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const _TypingDotsAnimation({
    required this.dotSize,
    this.color,
  });

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
    return Row(
      children: [
        _buildDot(0),
        _buildDot(1),
        _buildDot(2),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final baseValue = index * 0.33;
        final opacity = _controller.value >= baseValue && _controller.value < baseValue + 0.33
            ? 1.0
            : 0.3;
        return Opacity(
          opacity: opacity,
          child: child,
        );
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