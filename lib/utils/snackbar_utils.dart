import 'package:flutter/material.dart';

/// Анимированный снackbar для отображения сверху
class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AnimatedSnackbar({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    
    _controller.forward();
    
    Future.delayed(widget.duration, () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (mounted) widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    
    final glassColor = isDark 
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.85);
    
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    
    final padding = isDesktop 
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    
    final iconSize = isDesktop ? 18.0 : 20.0;
    final fontSize = isDesktop ? 11.0 : 12.0;
    final borderRadius = isDesktop ? 12.0 : 16.0;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: glassColor,
          backgroundBlendMode: BlendMode.luminosity,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: isDesktop ? 8 : 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: widget.backgroundColor.withValues(alpha: 0.3),
              blurRadius: isDesktop ? 12 : 20,
              offset: const Offset(0, 0),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: widget.backgroundColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                widget.icon,
                color: widget.backgroundColor,
                size: iconSize,
                shadows: [
                  Shadow(
                    color: widget.backgroundColor.withValues(alpha: 0.5),
                    blurRadius: 3,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: isDesktop ? 1 : 2,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: isDesktop ? 14 : 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () {
                _controller.reverse().then((_) {
                  widget.onDismiss();
                });
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isDesktop ? 20 : 24,
                minHeight: isDesktop ? 20 : 24,
              ),
              splashRadius: isDesktop ? 10 : 12,
            ),
          ],
        ),
      ),
    );
  }
}

/// Утилиты для создания унифицированных SnackBar
class SnackbarUtils {
  /// Успешное действие (зеленый)
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.check_circle,
      backgroundColor: Colors.green,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Ошибка (красный)
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.error,
      backgroundColor: Colors.red,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Предупреждение (оранжевый)
  static void showWarningSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.warning,
      backgroundColor: Colors.orange,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Информация (голубой)
  static void showInfoSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.info,
      backgroundColor: Colors.blue,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Вторичное действие (фиолетовый)
  static void showSecondarySnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.circle,
      backgroundColor: Colors.purple,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Сообщение о копировании (серый)
  static void showCopySnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.copy,
      backgroundColor: Colors.grey[700]!,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Сообщение о подключении (синий)
  static void showConnectionSnackBar({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: message,
      icon: icon ?? Icons.link,
      backgroundColor: Colors.blue[600]!,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Предупреждение о том, что модель не поддерживает изображения/файлы (оранжевый)
  static void showModelNotSupportsMediaSnackBar({
    required BuildContext context,
    required String modelName,
    Duration? duration,
  }) {
    _showStyledSnackBar(
      context: context,
      message: 'Модель $modelName не поддерживает изображения и файлы',
      icon: Icons.image_not_supported,
      backgroundColor: Colors.orange,
      duration: duration ?? const Duration(seconds: 6),
    );
  }

  /// Приватный метод для создания стилизованного SnackBar
  static void _showStyledSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    _removeExistingOverlay(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: isDesktop ? 40 : 20,
        left: isDesktop ? null : 20,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 400 : screenWidth - 40,
            ),
            child: _AnimatedSnackbar(
              message: message,
              icon: icon,
              backgroundColor: backgroundColor,
              duration: duration,
              onDismiss: () => _removeExistingOverlay(context),
            ),
          ),
        ),
      ),
    );
    
    _currentOverlayEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  static OverlayEntry? _currentOverlayEntry;

  static void _removeExistingOverlay(BuildContext context) {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }
  }
}