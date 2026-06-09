import 'dart:async';
import 'dart:math';

import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/shared/utils/logger.dart';

import 'chat_cancellation.dart';

/// Retry policy configuration for AI service requests.
class RetryPolicy {
  final Duration baseDelay;
  final Duration maxDelay;
  final double factor;

  static const Duration defaultBaseDelay = Duration(milliseconds: 500);
  static const Duration defaultMaxDelay = Duration(seconds: 30);
  static const double defaultFactor = 1.5;

  const RetryPolicy({
    this.baseDelay = defaultBaseDelay,
    this.maxDelay = defaultMaxDelay,
    this.factor = defaultFactor,
  });

  /// Returns the defaults used by [ChatRetryService].
  static const RetryPolicy defaults = RetryPolicy();
}

/// OpenCode-style unbounded exponential backoff retry engine.
///
/// Retries on transient errors forever until success or cancellation.
/// Emits progress via [retryCountdown] stream during backoff waits.
class ChatRetryService {
  final RetryPolicy policy;
  final ChatCancellation cancellation;

  static const _errorClassifier = ErrorClassifier();

  /// Stream of retry progress: 1.0 → 0.0 during backoff wait.
  StreamController<double>? _retryController;

  bool _retryCancelled = false;
  Duration? _lastRetryAfter;

  /// Whether a retry backoff is currently in progress.
  bool isRetrying = false;

  ChatRetryService({
    this.policy = RetryPolicy.defaults,
    required this.cancellation,
  });

  /// Retry countdown stream. Emits 1.0 → 0.0 during backoff.
  Stream<double> get retryCountdown => _ensureRetryController.stream;

  StreamController<double> get _ensureRetryController {
    if (_retryController == null || _retryController!.isClosed) {
      _retryController = StreamController<double>.broadcast();
    }
    return _retryController!;
  }

  /// Wraps [operation] with unbounded exponential backoff retry.
  ///
  /// [onRetry] is called before each retry attempt (not before the first).
  Future<T> execute<T>(
    Future<T> Function() operation, {
    void Function(int attempt, Object error)? onRetry,
  }) async {
    _retryCancelled = false;
    final delay = policy.baseDelay;
    final rng = Random();
    int attempt = 0;
    while (true) {
      try {
        LogTags.chatService.logDebug('_retry attempt $attempt starting');
        final result = await operation();
        LogTags.chatService.logDebug('_retry attempt $attempt succeeded');
        return result;
      } catch (e) {
        LogTags.chatService.logWarning(
          '_retry attempt $attempt caught: ${e.runtimeType}: $e',
        );
        if (!_isRetryable(e)) {
          LogTags.chatService.logWarning(
            '_retry attempt $attempt: error NOT retryable, rethrowing',
          );
          rethrow;
        }
        if (_retryCancelled || cancellation.isCancelled) {
          LogTags.chatService.logWarning(
            '_retry attempt $attempt: cancelled, aborting',
          );
          _ensureRetryController.close();
          throw Exception('cancelled');
        }
        isRetrying = true;
        onRetry?.call(attempt, e);
        final currentDelay = _nextDelay(delay, attempt, rng);
        LogTags.chatService.logInfo(
          '_retry attempt $attempt: retrying after ${currentDelay.inMilliseconds}ms',
        );
        final rc = _ensureRetryController;
        final totalMs = currentDelay.inMilliseconds.toDouble();
        final startTime = DateTime.now().millisecondsSinceEpoch;
        await for (final _ in Stream.periodic(
          const Duration(milliseconds: 50),
        )) {
          if (_retryCancelled || cancellation.isCancelled) {
            LogTags.chatService.logWarning(
              '_retry attempt $attempt: cancelled during wait',
            );
            _ensureRetryController.close();
            throw Exception('cancelled');
          }
          final elapsed =
              (DateTime.now().millisecondsSinceEpoch - startTime) / totalMs;
          final progress = 1.0 - elapsed.clamp(0.0, 1.0);
          if (!rc.isClosed) {
            rc.add(progress);
          }
          if (progress <= 0.0) break;
        }
        isRetrying = false;
        attempt++;
      }
    }
  }

  bool _isRetryable(Object e) {
    final classified = _errorClassifier.classify(e);

    if (classified is RateLimitError && classified.retryAfter != null) {
      _lastRetryAfter = classified.retryAfter!;
    }

    LogTags.chatService.logDebug(
      '_isRetryableError: $e → ${classified.runtimeType} retryable=${classified.isRetryable}',
    );
    return classified.isRetryable;
  }

  Duration _nextDelay(Duration baseDelay, int attempt, Random rng) {
    if (_lastRetryAfter != null) {
      final d = _lastRetryAfter!;
      _lastRetryAfter = null;
      return d > policy.maxDelay ? policy.maxDelay : d;
    }
    final exponential = baseDelay * pow(policy.factor, attempt);
    final capped = exponential > policy.maxDelay
        ? policy.maxDelay
        : exponential;
    final jitter = capped * rng.nextDouble() * 0.3;
    return Duration(
      milliseconds: (capped.inMilliseconds + jitter.inMilliseconds).round(),
    );
  }

  /// Flags the current retry loop as cancelled.
  void cancelRetry() {
    _retryCancelled = true;
  }
}
