import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Премиум-минималистичный визуальный слой splash-экрана.
///
/// Компонент **не знает** про конкретный заголовок: он принимает готовый
/// [title]-виджет снаружи, поэтому заголовок (или его эффекты) можно
/// заменить, не трогая сияние, виньетку и grain.
///
/// Принцип: «эффекты внутри [SplashVisual], а заголовок снаружи».
class SplashVisual extends StatelessWidget {
  const SplashVisual({
    super.key,
    required this.title,
    required this.textColor,
    required this.glowOpacity,
    required this.vignetteOpacity,
    this.glowColor = const Color(0xFF9E9E9E),
    this.titleMaxSize = 380,
    this.grainOpacity = 0.045,
    this.grainSeed = 42,
  });

  final Widget title;
  final Color textColor;

  // Управляет «дышащим» bloom.
  final Animation<double> glowOpacity;

  // Лёгкая виньетка по краям (минимал).
  final double vignetteOpacity;

  // Нейтральный цвет сияния (без брендового оранжевого).
  final Color glowColor;

  // Чтобы контейнер сияния не «дёргался».
  final double titleMaxSize;

  // Прозрачность grain.
  final double grainOpacity;

  // Стабильный seed для одинакового «рисунка».
  final int grainSeed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Виньетка: меньше «шума», больше премиума.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.15),
                  radius: 0.9,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: vignetteOpacity),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Soft bloom: без «жирного» неона.
        AnimatedBuilder(
          animation: glowOpacity,
          builder: (context, _) {
            return Opacity(
              opacity: glowOpacity.value,
              child: Center(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    width: titleMaxSize,
                    height: titleMaxSize,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.52,
                        colors: [glowColor, glowColor.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Grain: статичный, чтобы не жечь CPU и не ломать reduceMotion.
        Positioned.fill(
          child: _GrainOverlay(opacity: grainOpacity, seed: grainSeed),
        ),

        // Тайтл (принимается снаружи).
        Center(
          child: DefaultTextStyle(
            style: TextStyle(color: textColor),
            child: title,
          ),
        ),
      ],
    );
  }
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay({required this.opacity, required this.seed});

  final double opacity;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(
          opacity: opacity,
          seed: seed,
          // «Шум» дешевле: меньше точек = минималистичный premium grain.
          densityDivisor: 18000,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.opacity,
    required this.seed,
    required this.densityDivisor,
  });

  final double opacity;
  final int seed;
  final int densityDivisor;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(seed);

    final count = (size.width * size.height / densityDivisor)
        .clamp(450, 1400)
        .toInt();

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: opacity)
      ..blendMode = BlendMode.overlay;

    for (int i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final r = 0.5 + rand.nextDouble() * 1.1;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
