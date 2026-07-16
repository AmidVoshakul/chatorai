import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// CHAT SHIMMER TEXT — shared shimmer using the `shimmer_text` package technique
// (continuous left→right loop, text always visible) with a configurable weight.
// The package itself hardcodes FontWeight.bold and exposes no weight param, so
// the widget is implemented locally following the same approach.
// ===========================================================================

class ChatShimmerText extends StatefulWidget {
  final String text;
  final double? textSize;
  final Color? color;
  final FontWeight fontWeight;
  final Duration duration;

  const ChatShimmerText({
    super.key,
    required this.text,
    this.textSize,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ChatShimmerText> createState() => _ChatShimmerTextState();
}

class _ChatShimmerTextState extends State<ChatShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _shimmerPosition = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? Theme.of(context).colorScheme.primary;
    final highlight = Color.lerp(base, Colors.white, 0.6) ?? base;

    return AnimatedBuilder(
      animation: _shimmerPosition,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) {
          return LinearGradient(
            begin: const Alignment(-1, 0),
            end: const Alignment(1, 0),
            colors: [base, highlight, base],
            stops: [
              _shimmerPosition.value - 0.2,
              _shimmerPosition.value,
              _shimmerPosition.value + 0.2,
            ],
          ).createShader(rect);
        },
        child: child,
      ),
      child: RepaintBoundary(
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.textSize ?? ChatoraiFontSizes.md,
            fontWeight: widget.fontWeight,
          ),
        ),
      ),
    );
  }
}
