import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

// Initialize logger for this service
final _logger = LogTags.network;

/// Состояние интернет-соединения
enum NetworkStatus { connected, disconnected, checking }

/// Централизованный сервис для проверки интернет-соединения
class NetworkService extends ChangeNotifier {
  NetworkService() {
    _initialize();
  }

  NetworkStatus _status = NetworkStatus.checking;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _checkTimer;
  bool _isSnackbarVisible = false;
  bool _userDismissed = false;

  /// Текущий статус сети
  NetworkStatus get status => _status;

  /// Есть ли подключение к интернету
  bool get isConnected => _status == NetworkStatus.connected;

  /// Виден ли SnackBar об отсутствии сети
  bool get isSnackbarVisible => _isSnackbarVisible;

  /// Скрыл ли пользователь SnackBar
  bool get userDismissed => _userDismissed;

  /// Инициализация сервиса
  void _initialize() {
    _logger.logInfo('Initializing NetworkService');

    // Подписка на изменения состояния подключения
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Первоначальная проверка
    _checkInitialConnection();

    // Периодическая проверка каждые 30 секунд
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnection(),
    );
  }

  /// Проверка начального состояния подключения
  Future<void> _checkInitialConnection() async {
    _logger.logInfo('Checking initial connection');
    await _checkConnection();
  }

  /// Обработка изменений состояния подключения
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _logger.logInfo('Connectivity changed: $results');

    // Проверяем, есть ли подключение
    final hasConnectivity = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.other,
    );

    if (hasConnectivity) {
      // Если есть подключение, проверяем реальный доступ к интернету
      _checkConnection();
    } else {
      // Если нет подключения, сразу устанавливаем статус
      _updateStatus(NetworkStatus.disconnected);
    }
  }

  /// Проверка реального доступа к интернету
  Future<void> _checkConnection() async {
    try {

      // Проверяем несколько хостов для надежности
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

  /// Проверка доступности хоста
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

  /// Обновление статуса сети
  void _updateStatus(NetworkStatus newStatus) {
    if (_status == newStatus) return;

    final oldStatus = _status;
    _status = newStatus;

    _logger.logInfo('Network status changed from $oldStatus to $newStatus');

    // Сбрасываем флаг отклонения пользователем при восстановлении соединения
    if (newStatus == NetworkStatus.connected) {
      _userDismissed = false;
      _isSnackbarVisible = false;
    }

    notifyListeners();
  }

  /// Пользователь скрыл SnackBar
  void dismissSnackbar() {
    _userDismissed = true;
    _isSnackbarVisible = false;
    _logger.logInfo('User dismissed network snackbar');
    notifyListeners();
  }

  /// Показать SnackBar (вызывается из UI)
  void showSnackbar() {
    if (_status == NetworkStatus.disconnected && !_userDismissed) {
      _isSnackbarVisible = true;
      notifyListeners();
    }
  }

  /// Скрыть SnackBar
  void hideSnackbar() {
    _isSnackbarVisible = false;
    notifyListeners();
  }

  /// Принудительная проверка соединения
  Future<void> checkConnection() async {
    await _checkConnection();
  }

  /// Очистка ресурсов
  void dispose() {
    _logger.logInfo('Disposing NetworkService');
    _connectivitySubscription?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
}
