import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chatorai/services/speech_to_text_service.dart';

/// Оверлей для отображения статуса голосового ввода
/// Появляется поверх чата с затемнением и шиммер-эффектом на тексте
class SpeechOverlayWidget extends StatefulWidget {
  final SpeechUiState state;
  final String message;

  const SpeechOverlayWidget({
    super.key,
    required this.state,
    required this.message,
  });

  @override
  State<SpeechOverlayWidget> createState() => _SpeechOverlayWidgetState();
}

class _SpeechOverlayWidgetState extends State<SpeechOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == SpeechUiState.idle) return const SizedBox.shrink();

    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Stack(
      children: [
        // Затемнение фона с размытием
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
            ),
          ),
        ),
        
        // Центральный контент
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Маленький индикатор загрузки
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Текст с шиммер-эффектом
              _buildShimmerText(widget.message, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerText(String text, bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                isDark ? Colors.white70 : Colors.black54,
                isDark ? Colors.white : Colors.black87,
                isDark ? Colors.white70 : Colors.black54,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
        );
      },
    );
  }
}
