import 'dart:async';
import 'dart:io';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      (_) => _checkConnection(),
    );
  }

  Future<void> _checkInitialConnection() async {
    _logger.logInfo('Checking initial connection');
    await _checkConnection();
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
      _checkConnection();
    } else {
      _updateStatus(NetworkStatus.disconnected);
    }
  }

  Future<void> _checkConnection() async {
    try {
      final hosts = ['google.com', 'cloudflare.com', 'openrouter.ai'];
      for (final host in hosts) {
        if (await _canReachHost(host)) {
          _updateStatus(NetworkStatus.connected);
          return;
        }
      }
      _updateStatus(NetworkStatus.disconnected);
    } catch (e) {
      _logger.logError('Error checking connection: $e');
      _updateStatus(NetworkStatus.disconnected);
    }
  }

  Future<bool> _canReachHost(String host) async {
    try {
      final result = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.logDebug('Cannot reach host $host: $e');
      return false;
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
    await _checkConnection();
  }
}

final networkServiceProvider = NotifierProvider<NetworkNotifier, NetworkState>(
  NetworkNotifier.new,
);
