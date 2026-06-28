import 'dart:async';
import 'dart:math';

import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/shared/utils/logger.dart';

import 'chat_cancellation.dart';

/// Human-readable retry information for UI display.
class RichRetryInfo {
  final String message;
  final int attempt;
  final int nextDelayMs;
  final String? action;

  const RichRetryInfo({
    required this.message,
    required this.attempt,
    required this.nextDelayMs,
    this.action,
  });
}

/// Retry policy — OpenCode-compatible defaults.
class RetryPolicy {
  final Duration baseDelay;
  final Duration maxDelay;
  final double factor;
  final int maxAttempts;

  static const Duration defaultBaseDelay = Duration(milliseconds: 500);
  static const Duration defaultMaxDelay = Duration(seconds: 10);
  static const double defaultFactor = 2.0;
  static const int defaultMaxAttempts = 3;

  const RetryPolicy({
    this.baseDelay = defaultBaseDelay,
    this.maxDelay = defaultMaxDelay,
    this.factor = defaultFactor,
    this.maxAttempts = defaultMaxAttempts,
  });

  static const RetryPolicy defaults = RetryPolicy();
}

/// Bounded exponential backoff retry engine — OpenCode-compatible.
///
/// Only retries on known transient errors (network, 5xx). Does NOT retry
/// rate limits (429), auth errors (401/403), or client errors (4xx).
class ChatRetryService {
  final RetryPolicy policy;
  final ChatCancellation cancellation;

  static const _errorClassifier = ErrorClassifier();

  StreamController<double>? _retryController;
  bool _retryCancelled = false;
  bool isRetrying = false;

  ChatRetryService({
    this.policy = RetryPolicy.defaults,
    required this.cancellation,
  });

  Stream<double> get retryCountdown => _ensureRetryController.stream;

  StreamController<double> get _ensureRetryController {
    if (_retryController == null || _retryController!.isClosed) {
      _retryController = StreamController<double>.broadcast();
    }
    return _retryController!;
  }

  Future<T> execute<T>(
    Future<T> Function() operation, {
    void Function(RichRetryInfo info)? onRetry,
    bool Function()? isStillValid,
  }) async {
    _retryCancelled = false;
    int attempt = 0;

    while (attempt < policy.maxAttempts) {
      try {
        LogTags.chatService.logDebug(
          'ChatRetryService.execute attempt $attempt starting',
        );
        final result = await operation();
        LogTags.chatService.logDebug(
          'ChatRetryService.execute attempt $attempt succeeded',
        );
        _ensureRetryController.close();
        return result;
      } catch (e) {
        LogTags.chatService.logWarning(
          'ChatRetryService.execute attempt $attempt caught: ${e.runtimeType}: $e',
        );

        if (!_isRetryable(e)) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: error NOT retryable, rethrowing',
          );
          _ensureRetryController.close();
          rethrow;
        }

        if (_retryCancelled || cancellation.isCancelled) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: cancelled, aborting',
          );
          _ensureRetryController.close();
          throw Exception('cancelled');
        }

        if (isStillValid != null && !isStillValid()) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: superseded by newer generation, aborting',
          );
          _ensureRetryController.close();
          throw Exception('cancelled');
        }

        if (attempt >= policy.maxAttempts - 1) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: max attempts (${policy.maxAttempts}) reached, rethrowing',
          );
          _ensureRetryController.close();
          rethrow;
        }

        final delay = _nextDelay(attempt);
        final info = _buildRetryInfo(e, attempt, delay);
        onRetry?.call(info);

        LogTags.chatService.logInfo(
          'ChatRetryService.execute attempt $attempt: '
          'retrying after ${delay.inMilliseconds}ms — ${info.message}',
        );

        isRetrying = true;
        await _sleep(delay, isStillValid: isStillValid);
        isRetrying = false;

        attempt++;
      }
    }

    _ensureRetryController.close();
    throw Exception('Max retry attempts exceeded');
  }

  RichRetryInfo _buildRetryInfo(Object error, int attempt, Duration delay) {
    final classified = _errorClassifier.classify(error);
    final message = _retryMessage(classified);
    return RichRetryInfo(
      message: message,
      attempt: attempt,
      nextDelayMs: delay.inMilliseconds,
    );
  }

  String _retryMessage(ClassifiedError error) {
    return switch (error) {
      RateLimitError() => 'Rate limit exceeded',
      AuthenticationError() => 'Auth error',
      ServerError(:final statusCode) =>
        statusCode != null && statusCode >= 500
            ? 'Server error ($statusCode)'
            : 'Request error ($statusCode)',
      NetworkError() => 'Network error',
      OverflowError() => 'Context overflow',
      UnknownError() => 'Retrying',
    };
  }

  bool _isRetryable(Object e) {
    final classified = _errorClassifier.classify(e);
    LogTags.chatService.logDebug(
      '_isRetryableError: $e → ${classified.runtimeType} retryable=${classified.isRetryable}',
    );
    return classified.isRetryable;
  }

  Duration _nextDelay(int attempt) {
    final exponential = policy.baseDelay * pow(policy.factor, attempt);
    final capped = exponential > policy.maxDelay
        ? policy.maxDelay
        : exponential;
    return Duration(milliseconds: capped.inMilliseconds.round());
  }

  Future<void> _sleep(
    Duration duration, {
    required bool Function()? isStillValid,
  }) async {
    final rc = _ensureRetryController;
    final totalMs = duration.inMilliseconds.toDouble();
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final interval = const Duration(milliseconds: 50);

    while (true) {
      await Future<void>.delayed(interval);

      if (_retryCancelled || cancellation.isCancelled) {
        LogTags.chatService.logWarning(
          'ChatRetryService: cancelled during wait',
        );
        _ensureRetryController.close();
        throw Exception('cancelled');
      }

      if (isStillValid != null && !isStillValid()) {
        LogTags.chatService.logWarning(
          'ChatRetryService: superseded during wait, aborting',
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
  }

  void cancelRetry() {
    _retryCancelled = true;
  }
}
