import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import '../l10n/app_localizations.dart';

/// Виджет для управления отображением SnackBar о состоянии сети
class NetworkAwareWidget extends StatefulWidget {
  final Widget child;

  const NetworkAwareWidget({
    super.key,
    required this.child,
  });

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNetworkListener();
    });
  }

  void _setupNetworkListener() {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    
    networkService.addListener(_onNetworkStatusChanged);
    _onNetworkStatusChanged(); // Проверяем начальное состояние
  }

  void _onNetworkStatusChanged() {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    
    if (!mounted) return;
    
    if (networkService.status == NetworkStatus.disconnected && 
        !networkService.userDismissed) {
      _showNetworkSnackBar();
    } else {
      _hideNetworkSnackBar();
    }
  }

  void _showNetworkSnackBar() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _NetworkSnackBar(
            message: AppLocalizations.of(context)!.noInternetConnection,
            onDismiss: () {
              final networkService = Provider.of<NetworkService>(context, listen: false);
              networkService.dismissSnackbar();
              _hideNetworkSnackBar();
            },
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideNetworkSnackBar() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    networkService.removeListener(_onNetworkStatusChanged);
    _hideNetworkSnackBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Специализированный SnackBar для уведомлений о сети
class _NetworkSnackBar extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _NetworkSnackBar({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_NetworkSnackBar> createState() => _NetworkSnackBarState();
}

class _NetworkSnackBarState extends State<_NetworkSnackBar> 
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    
    final glassColor = isDark 
        ? Colors.black.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.15)
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
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: isDesktop ? 8 : 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
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
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: iconSize,
                shadows: [
                  Shadow(
                    color: Colors.orange.withValues(alpha: 0.5),
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
              onPressed: _dismiss,
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
