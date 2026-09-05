import 'package:flutter/material.dart';

/// Shared shimmer mask matching the animation pattern used by
/// [ChatShimmerText]. Wraps an arbitrary child with a horizontal
/// left-to-right shimmer highlight.
class ShimmerMask extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;

  const ShimmerMask({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
  });

  @override
  State<ShimmerMask> createState() => _ShimmerMaskState();
}

class _ShimmerMaskState extends State<ShimmerMask>
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
    final base = widget.baseColor ?? Colors.grey;
    final highlight = Colors.white;

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
      child: RepaintBoundary(child: widget.child),
    );
  }
}
