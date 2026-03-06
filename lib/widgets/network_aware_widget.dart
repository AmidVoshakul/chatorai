import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart' show networkServiceProvider;

/// Widget for managing network status SnackBar display
class NetworkAwareWidget extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkAwareWidget({super.key, required this.child});

  @override
  ConsumerState<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends ConsumerState<NetworkAwareWidget> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNetworkListener();
    });
  }

  void _setupNetworkListener() {
    final networkService = ref.read(networkServiceProvider);
    networkService.addListener(_onNetworkStatusChanged);
    _onNetworkStatusChanged();
  }

  void _onNetworkStatusChanged() {
    final networkService = ref.read(networkServiceProvider);

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
              final networkService = ref.read(networkServiceProvider);
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
    final networkService = ref.read(networkServiceProvider);
    networkService.removeListener(_onNetworkStatusChanged);
    _hideNetworkSnackBar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Specialized SnackBar for network notifications
class _NetworkSnackBar extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _NetworkSnackBar({required this.message, required this.onDismiss});

  @override
  State<_NetworkSnackBar> createState() => _NetworkSnackBarState();
}

class _NetworkSnackBarState extends State<_NetworkSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  onPressed: widget.onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
