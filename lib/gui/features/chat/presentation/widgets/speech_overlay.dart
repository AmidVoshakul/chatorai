import 'dart:math' as math;
import 'dart:ui';

import 'package:chatorai/gui/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SpeechOverlayWidget extends StatefulWidget {
  final SpeechUiState state;
  final String message;
  final double soundLevel;
  final String recognizedText;
  final double bottomInset;

  const SpeechOverlayWidget({
    super.key,
    required this.state,
    required this.message,
    required this.soundLevel,
    this.recognizedText = '',
    this.bottomInset = 0,
  });

  @override
  State<SpeechOverlayWidget> createState() => _SpeechOverlayWidgetState();
}

class _SpeechOverlayWidgetState extends State<SpeechOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late final AnimationController _fadeController;

  double _smoothedLevel = 0;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SpeechOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _smoothedLevel = (_smoothedLevel * 0.75) + (widget.soundLevel * 0.25);
    if (widget.recognizedText != oldWidget.recognizedText &&
        widget.recognizedText.isNotEmpty &&
        _fadeController.isCompleted) {
      _fadeController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == SpeechUiState.idle) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final speechColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: widget.bottomInset,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color:
                  (isDark ? ChatoraiColors.pureBlack : ChatoraiColors.pureWhite)
                      .withValues(alpha: 0.75),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: _AudioWaveAnimation(
                      level: _smoothedLevel,
                      color: speechColor,
                      animation: _waveController,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingDot(color: speechColor),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: speechColor.withValues(alpha: 0.8),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (widget.recognizedText.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeController,
                      child: SelectableText(
                        widget.recognizedText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? ChatoraiColors.pureWhite
                              : ChatoraiColors.pureBlack,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          painter: _WavePainter(
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

class _WavePainter extends CustomPainter {
  final double level;
  final Color color;
  final double animationValue;

  _WavePainter({
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
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.animationValue != animationValue;
  }
}

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
