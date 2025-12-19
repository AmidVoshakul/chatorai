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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 250),
    );
    
    // Smooth fade with slight bounce
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    
    // Slide with subtle bounce effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    // Start animation
    _controller.forward();
    
    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
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
    
    // Glass effect colors based on theme
    final glassColor = isDark 
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.85);
    
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            // Glass effect background
            color: glassColor,
            // Blur effect
            backgroundBlendMode: BlendMode.luminosity,
            // Rounded corners
            borderRadius: BorderRadius.circular(16),
            // Border for glass effect
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            // Multiple shadow layers for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 0),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with glow effect
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.backgroundColor,
                  size: 20,
                  shadows: [
                    Shadow(
                      color: widget.backgroundColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Message text
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              // Close button (optional)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  _controller.reverse().then((_) {
                    widget.onDismiss();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                splashRadius: 12,
              ),
            ],
          ),
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
      duration: duration,
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
      duration: duration,
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
      duration: duration,
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
      duration: duration,
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
      duration: duration,
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
      duration: duration ?? const Duration(seconds: 2),
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
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Приватный метод для создания стилизованного SnackBar
  static void _showStyledSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration? duration,
  }) {
    // Remove any existing overlays first
    _removeExistingOverlay(context);
    
    // Create overlay entry
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80, // Position below app bar
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSnackbar(
            message: message,
            icon: icon,
            backgroundColor: backgroundColor,
            duration: duration ?? const Duration(seconds: 2),
            onDismiss: () {
              _removeExistingOverlay(context);
            },
          ),
        ),
      ),
    );
    
    // Store the entry for removal
    _currentOverlayEntry = overlayEntry;
    overlayState.insert(overlayEntry);
    
    // Auto-remove after duration
    Future.delayed(duration ?? const Duration(seconds: 2), () {
      _removeExistingOverlay(context);
    });
  }

  static OverlayEntry? _currentOverlayEntry;

  static void _removeExistingOverlay(BuildContext context) {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    }
  }
}