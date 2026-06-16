import 'dart:async';
import 'dart:math';

import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:dio/dio.dart';

import 'chat_cancellation.dart';

/// Human-readable retry information for UI display.
class RichRetryInfo {
  /// Description of the error (e.g. "Rate limit exceeded", "Overloaded").
  final String message;

  /// Zero-based attempt number.
  final int attempt;

  /// Delay in ms before the next attempt.
  final int nextDelayMs;

  /// Optional user-facing action label (e.g. "Check API key").
  final String? action;

  const RichRetryInfo({
    required this.message,
    required this.attempt,
    required this.nextDelayMs,
    this.action,
  });
}

/// Retry policy configuration for AI service requests.
///
/// OpenCode-style defaults: baseDelay=2000ms, factor=2.0, maxDelay=30s.
class RetryPolicy {
  final Duration baseDelay;
  final Duration maxDelay;
  final double factor;

  static const Duration defaultBaseDelay = Duration(milliseconds: 2000);
  static const Duration defaultMaxDelay = Duration(seconds: 30);
  static const double defaultFactor = 2.0;

  const RetryPolicy({
    this.baseDelay = defaultBaseDelay,
    this.maxDelay = defaultMaxDelay,
    this.factor = defaultFactor,
  });

  static const RetryPolicy defaults = RetryPolicy();
}

/// OpenCode-style unbounded exponential backoff retry engine.
///
/// Retries on transient errors forever until success or cancellation.
/// Emits progress via [retryCountdown] stream during backoff waits.
/// Calls [onRetry] with [RichRetryInfo] before each retry attempt.
class ChatRetryService {
  final RetryPolicy policy;
  final ChatCancellation cancellation;

  static const _errorClassifier = ErrorClassifier();

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
  /// [onRetry] is called with [RichRetryInfo] before each retry attempt
  /// (not before the first).
  Future<T> execute<T>(
    Future<T> Function() operation, {
    void Function(RichRetryInfo info)? onRetry,
  }) async {
    _retryCancelled = false;
    final rng = Random();
    int attempt = 0;
    while (true) {
      try {
        LogTags.chatService.logDebug(
          'ChatRetryService.execute attempt $attempt starting',
        );
        final result = await operation();
        LogTags.chatService.logDebug(
          'ChatRetryService.execute attempt $attempt succeeded',
        );
        return result;
      } catch (e) {
        LogTags.chatService.logWarning(
          'ChatRetryService.execute attempt $attempt caught: ${e.runtimeType}: $e',
        );
        if (!_isRetryable(e)) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: error NOT retryable, rethrowing',
          );
          rethrow;
        }
        if (_retryCancelled || cancellation.isCancelled) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: cancelled, aborting',
          );
          _ensureRetryController.close();
          throw Exception('cancelled');
        }
        isRetrying = true;
        final currentDelay = _nextDelay(attempt, e, rng);
        final info = _buildRetryInfo(e, attempt, currentDelay);
        onRetry?.call(info);
        LogTags.chatService.logInfo(
          'ChatRetryService.execute attempt $attempt: '
          'retrying after ${currentDelay.inMilliseconds}ms — ${info.message}',
        );
        final rc = _ensureRetryController;
        final totalMs = currentDelay.inMilliseconds.toDouble();
        final startTime = DateTime.now().millisecondsSinceEpoch;
        await for (final _ in Stream.periodic(
          const Duration(milliseconds: 50),
        )) {
          if (_retryCancelled || cancellation.isCancelled) {
            LogTags.chatService.logWarning(
              'ChatRetryService.execute attempt $attempt: cancelled during wait',
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
      UnknownError() => 'Retrying',
    };
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

  Duration _nextDelay(int attempt, Object error, Random rng) {
    // Honour retry-after if the API sent one
    if (error is RateLimitError && error.retryAfter != null) {
      final d = error.retryAfter!;
      _lastRetryAfter = null;
      return d > policy.maxDelay ? policy.maxDelay : d;
    }
    if (_lastRetryAfter != null) {
      final d = _lastRetryAfter!;
      _lastRetryAfter = null;
      return d > policy.maxDelay ? policy.maxDelay : d;
    }

    // Try HTTP-date from error string
    final fromDate = _parseHttpDateFromError(error);
    if (fromDate != null) {
      return fromDate > policy.maxDelay ? policy.maxDelay : fromDate;
    }

    final exponential = policy.baseDelay * pow(policy.factor, attempt);
    final capped = exponential > policy.maxDelay
        ? policy.maxDelay
        : exponential;
    final jitter = capped * rng.nextDouble() * 0.3;
    return Duration(
      milliseconds: (capped.inMilliseconds + jitter.inMilliseconds).round(),
    );
  }

  /// Parse HTTP-date format `Retry-After: Wed, 21 Oct 2015 07:28:00 GMT`
  /// from a DioException response header, falling back to string matching.
  Duration? _parseHttpDateFromError(Object error) {
    if (error is DioException) {
      final retryAfter = error.response?.headers.value('retry-after');
      if (retryAfter != null) {
        final parsed = DateTime.tryParse(retryAfter);
        if (parsed != null) {
          final ms =
              parsed.millisecondsSinceEpoch -
              DateTime.now().millisecondsSinceEpoch;
          if (ms > 0) return Duration(milliseconds: ms);
        }
      }
    }
    return null;
  }

  /// Flags the current retry loop as cancelled.
  void cancelRetry() {
    _retryCancelled = true;
  }
}
