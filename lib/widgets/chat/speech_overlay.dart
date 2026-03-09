import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chatorai/services/speech_to_text_service.dart';
import 'package:chatorai/themes/app_theme.dart';

// ===========================================================================
// SPEECH OVERLAY WIDGET
// ===========================================================================

class SpeechOverlayWidget extends StatefulWidget {
  final SpeechUiState state;
  final String message;
  final double soundLevel;

  const SpeechOverlayWidget({
    super.key,
    required this.state,
    required this.message,
    required this.soundLevel,
  });

  @override
  State<SpeechOverlayWidget> createState() => _SpeechOverlayWidgetState();
}

// ===========================================================================
// STATE
// ===========================================================================

class _SpeechOverlayWidgetState extends State<SpeechOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  double _smoothedLevel = 0;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();

    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SpeechOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _smoothedLevel = (_smoothedLevel * 0.75) + (widget.soundLevel * 0.25);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == SpeechUiState.idle) {
      return const SizedBox.shrink();
    }

    final overlayBackgroundColor = ChatoraiColors.speechOverlayBackgroundDark;
    final overlayTextColor = ChatoraiColors.speechOverlayTextDark;
    final waveColor = ChatoraiColors.speechOverlayWaveDark;

    return Stack(
      children: [
        // ===================================================================
        // GLASS BLUR BACKGROUND
        // ===================================================================
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: ChatoraiColors.speechOverlayBlur,
              sigmaY: ChatoraiColors.speechOverlayBlur,
            ),
            child: Container(
              color: overlayBackgroundColor.withValues(alpha: 0.75),
            ),
          ),
        ),

        // ===================================================================
        // CENTER CONTENT
        // ===================================================================
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===========================================================
                // SIRI STYLE WAVE
                // ===========================================================
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: _AudioWaveAnimation(
                    level: _smoothedLevel,
                    color: waveColor,
                    animation: _waveController,
                  ),
                ),

                const SizedBox(height: ChatoraiSpacing.lg),

                // ===========================================================
                // STATUS
                // ===========================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PulsingDot(color: overlayTextColor),
                    const SizedBox(width: ChatoraiSpacing.md),
                    Flexible(
                      child: _buildShimmerText(
                        widget.message,
                        overlayTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // SHIMMER TEXT
  // =======================================================================

  Widget _buildShimmerText(String text, Color textColor) {
    const shimmerColor = Colors.white60;
    const shimmerHighlight = Colors.white;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final progress = _shimmerAnimation.value;

            return LinearGradient(
              begin: Alignment(-1 + progress * 2, 0),
              end: Alignment(1 + progress * 2, 0),
              colors: const [shimmerColor, shimmerHighlight, shimmerColor],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.lg,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// AUDIO WAVE ANIMATION
// ===========================================================================

class _AudioWaveAnimation extends StatelessWidget {
  final double level;
  final Color color;
  final AnimationController animation;

  const _AudioWaveAnimation({
    required this.level,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _SiriWavePainter(
            level: level,
            color: color,
            animationValue: animation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// ===========================================================================
// SIRI STYLE WAVE PAINTER
// ===========================================================================

class _SiriWavePainter extends CustomPainter {
  final double level;
  final Color color;
  final double animationValue;

  _SiriWavePainter({
    required this.level,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final amplitude = (size.height * 0.35) * level + 6;

    _drawWave(canvas, size, amplitude, 1.0, 0.0, 0.9);
    _drawWave(canvas, size, amplitude * 0.8, 1.3, 0.6, 0.55);
    _drawWave(canvas, size, amplitude * 0.6, 1.7, 1.2, 0.35);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double amplitude,
    double frequency,
    double phase,
    double opacity,
  ) {
    final centerY = size.height / 2;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();

    for (double x = 0; x <= size.width; x++) {
      final progress = x / size.width;

      final fade = math.sin(progress * math.pi);

      final y =
          centerY +
          math.sin(
                (progress * frequency * math.pi * 2) +
                    animationValue * math.pi * 2 +
                    phase,
              ) *
              amplitude *
              fade;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SiriWavePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.animationValue != animationValue;
  }
}

// ===========================================================================
// PULSING DOT
// ===========================================================================

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
