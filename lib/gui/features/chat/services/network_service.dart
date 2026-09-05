import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Probes a single host for reachability inside a separate isolate.
///
/// `InternetAddress.lookup` can block the calling event loop on some Android
/// configurations when DNS hangs (observed ~17s stalls). Running it in an
/// isolate keeps the UI/main isolate responsive so the first frame (and the
/// Welcome questions) paints immediately instead of after the lookup resolves.
Future<bool> _probeHost(String host) async {
  try {
    final result = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on Object {
    return false;
  }
}

final _logger = LogTags.network;

enum NetworkStatus { connected, disconnected, checking }

class NetworkState {
  final NetworkStatus status;
  final bool isSnackbarVisible;
  final bool userDismissed;

  const NetworkState({
    this.status = NetworkStatus.checking,
    this.isSnackbarVisible = false,
    this.userDismissed = false,
  });

  bool get isConnected => status == NetworkStatus.connected;

  NetworkState copyWith({
    NetworkStatus? status,
    bool? isSnackbarVisible,
    bool? userDismissed,
  }) {
    return NetworkState(
      status: status ?? this.status,
      isSnackbarVisible: isSnackbarVisible ?? this.isSnackbarVisible,
      userDismissed: userDismissed ?? this.userDismissed,
    );
  }
}

class NetworkNotifier extends Notifier<NetworkState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _checkTimer;

  @override
  NetworkState build() {
    _initialize();
    ref.onDispose(() {
      _logger.logInfo('Disposing NetworkService');
      _connectivitySubscription?.cancel();
      _checkTimer?.cancel();
    });
    return const NetworkState();
  }

  void _initialize() {
    _logger.logInfo('Initializing NetworkService');
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    _checkInitialConnection();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refineConnection(),
    );
  }

  Future<void> _checkInitialConnection() async {
    _logger.logInfo('Checking initial connection');
    await _refineConnection();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _logger.logInfo('Connectivity changed: $results');
    final hasConnectivity = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.other,
    );
    if (hasConnectivity) {
      // Surface connectivity immediately from the platform (no DNS probe) so
      // the UI never waits on a potentially-hanging lookup. The DNS-based
      // `_checkConnection` still runs in the background to refine the status,
      // but it can no longer block the first frame / Welcome questions.
      _updateStatus(NetworkStatus.connected);
      _refineConnection();
    } else {
      _updateStatus(NetworkStatus.disconnected);
    }
  }

  /// DNS-based reachability refinement. Runs the (potentially slow)
  /// `InternetAddress.lookup` inside a separate isolate so a hanging DNS
  /// resolver on the device cannot stall the main isolate / UI thread.
  Future<void> _refineConnection() async {
    try {
      final hosts = ['google.com', 'cloudflare.com', 'openrouter.ai'];
      final results = await Future.wait(
        hosts.map((h) => Isolate.run(() => _probeHost(h))),
        eagerError: false,
      );
      if (results.any((r) => r)) {
        _updateStatus(NetworkStatus.connected);
      } else {
        _updateStatus(NetworkStatus.disconnected);
      }
    } catch (e) {
      _logger.logError('Error checking connection: $e');
      // Leave the connectivity-based status intact on probe failure.
    }
  }

  void _updateStatus(NetworkStatus newStatus) {
    if (state.status == newStatus) return;
    final oldStatus = state.status;
    state = state.copyWith(status: newStatus);
    _logger.logInfo('Network status changed from $oldStatus to $newStatus');
    if (newStatus == NetworkStatus.connected) {
      state = state.copyWith(userDismissed: false, isSnackbarVisible: false);
    }
  }

  void dismissSnackbar() {
    state = state.copyWith(userDismissed: true, isSnackbarVisible: false);
    _logger.logInfo('User dismissed network snackbar');
  }

  void showSnackbar() {
    if (state.status == NetworkStatus.disconnected && !state.userDismissed) {
      state = state.copyWith(isSnackbarVisible: true);
    }
  }

  void hideSnackbar() {
    state = state.copyWith(isSnackbarVisible: false);
  }

  Future<void> checkConnection() async {
    await _refineConnection();
  }
}

final networkServiceProvider = NotifierProvider<NetworkNotifier, NetworkState>(
  NetworkNotifier.new,
);
