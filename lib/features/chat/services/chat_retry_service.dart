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
  final int? maxAttempts;

  static const Duration defaultBaseDelay = Duration(milliseconds: 500);
  static const Duration defaultMaxDelay = Duration(hours: 24);
  static const double defaultFactor = 2.0;

  const RetryPolicy({
    this.baseDelay = defaultBaseDelay,
    this.maxDelay = defaultMaxDelay,
    this.factor = defaultFactor,
    this.maxAttempts,
  });

  static const RetryPolicy defaults = RetryPolicy();
}

/// OpenCode-compatible bounded exponential backoff retry engine.
///
/// Infinite retries for retryable errors; stop only when
/// `ClassifiedError.isRetryable == false`.
class ChatRetryService {
  final RetryPolicy policy;
  final ChatCancellation cancellation;

  static const _errorClassifier = ErrorClassifier();

  StreamController<double>? _retryCountdownController;
  StreamController<String>? _retryMessageController;

  bool _retryCancelled = false;
  bool isRetrying = false;

  ChatRetryService({
    this.policy = RetryPolicy.defaults,
    required this.cancellation,
  }) {
    _retryCountdownController = StreamController<double>.broadcast();
    _retryMessageController = StreamController<String>.broadcast();
  }

  Stream<double> get retryCountdown {
    final c = _retryCountdownController!;
    return c.stream;
  }

  Stream<String> get retryMessageStream {
    final c = _retryMessageController!;
    return c.stream;
  }

  void _resetRetryState() {
    isRetrying = false;
    _emit(null, '');
  }

  void dispose() {
    _retryCountdownController?.close();
    _retryMessageController?.close();
    _retryCountdownController = null;
    _retryMessageController = null;
  }

  void _emit(double? progress, String? message) {
    final rc = _retryCountdownController;
    final mc = _retryMessageController;
    if (progress != null && rc != null && !rc.isClosed) {
      try {
        rc.add(progress);
      } catch (_) {}
    }
    if (message != null && mc != null && !mc.isClosed) {
      try {
        mc.add(message);
      } catch (_) {}
    }
  }

  Future<T> execute<T>(
    Future<T> Function({void Function()? onChunkReceived}) operation, {
    void Function(RichRetryInfo info)? onRetry,
    bool Function()? isStillValid,
  }) async {
    _retryCancelled = false;
    int attempt = 0;
    var chunkReceived = false;

    while (true) {
      try {
        LogTags.chatService.logDebug(
          'ChatRetryService.execute attempt $attempt starting',
        );
        final result = await operation(
          onChunkReceived: () {
            chunkReceived = true;
          },
        );
        LogTags.chatService.logDebug(
          'ChatRetryService.execute attempt $attempt succeeded',
        );
        _resetRetryState();
        return result;
      } catch (e) {
        LogTags.chatService.logWarning(
          'ChatRetryService.execute attempt $attempt caught: ${e.runtimeType}: $e',
        );

        if (chunkReceived) {
          attempt = 0;
          chunkReceived = false;
        }

        final classified = _errorClassifier.classify(e);

        if (!classified.isRetryable) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: error NOT retryable (${classified.runtimeType}), rethrowing',
          );
          _resetRetryState();
          rethrow;
        }

        if (_retryCancelled || cancellation.isCancelled) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: cancelled, aborting',
          );
          _resetRetryState();
          throw Exception('cancelled');
        }

        if (isStillValid != null && !isStillValid()) {
          LogTags.chatService.logWarning(
            'ChatRetryService.execute attempt $attempt: superseded by newer generation, aborting',
          );
          _resetRetryState();
          throw Exception('cancelled');
        }

        final delay = classified.retryAfter ?? _nextDelay(attempt);
        final info = _buildRetryInfo(classified, attempt, delay);
        onRetry?.call(info);

        LogTags.chatService.logInfo(
          'ChatRetryService.execute attempt $attempt: '
          'retrying after ${delay.inMilliseconds}ms — ${info.message}',
        );

        isRetrying = true;
        await _sleep(delay, message: info.message, isStillValid: isStillValid);
        isRetrying = false;

        attempt++;
      }
    }
  }

  RichRetryInfo _buildRetryInfo(
    ClassifiedError error,
    int attempt,
    Duration delay,
  ) {
    final displayAttempt = attempt + 1;
    final message = _retryMessage(error, displayAttempt);
    final action = _retryAction(error);
    return RichRetryInfo(
      message: message,
      attempt: attempt,
      nextDelayMs: delay.inMilliseconds,
      action: action,
    );
  }

  String _retryMessage(ClassifiedError error, int displayAttempt) {
    final rawMessage = switch (error) {
      RateLimitError(:final rawMessage) when rawMessage != null &&
          rawMessage.isNotEmpty => rawMessage,
      ServerError(:final rawMessage) when rawMessage != null &&
          rawMessage.isNotEmpty => rawMessage,
      NetworkError(:final rawMessage) when rawMessage != null &&
          rawMessage.isNotEmpty => rawMessage,
      UnknownError(:final rawMessage) when rawMessage != null &&
          rawMessage.isNotEmpty => rawMessage,
      _ => null,
    };

    if (rawMessage != null) {
      return '$rawMessage [attempt #$displayAttempt]';
    }

    return switch (error) {
      RateLimitError(:final reason) => _rateLimitTemplate(
        reason,
        displayAttempt,
      ),
      AuthenticationError() => 'Auth error [attempt #$displayAttempt]',
      ServerError(:final statusCode) =>
        (statusCode != null && statusCode >= 500)
            ? 'Server error ($statusCode) [attempt #$displayAttempt]'
            : 'Request error ($statusCode) [attempt #$displayAttempt]',
      NetworkError() => 'Network error [attempt #$displayAttempt]',
      OverflowError() => 'Context overflow [attempt #$displayAttempt]',
      UnknownError() => 'Retrying [attempt #$displayAttempt]',
    };
  }

  String _rateLimitTemplate(String? reason, int displayAttempt) {
    final title = switch (reason) {
      'free_tier_limit' => 'Free tier limit reached',
      'account_rate_limit' => 'Usage limit reached',
      _ => 'Too Many Requests',
    };
    return '$title: [attempt #$displayAttempt]';
  }

  String _injectCountdown(String template, Duration remaining) {
    final secs = remaining.inSeconds;
    final countdown = secs <= 1
        ? 'retrying now…'
        : secs < 60
        ? 'retrying in ${secs}s'
        : 'retrying in ${(secs / 60).ceil()}min';
    return template.replaceFirst('[attempt #', '[$countdown attempt #');
  }

  String? _retryAction(ClassifiedError error) {
    if (error is! RateLimitError) return null;
    return error.reason;
  }

  Duration _nextDelay(int attempt) {
    final exponential =
        policy.baseDelay * pow(policy.factor, attempt.toDouble());
    final capped = exponential > policy.maxDelay
        ? policy.maxDelay
        : exponential;
    return Duration(milliseconds: capped.inMilliseconds.round());
  }

  Future<void> _sleep(
    Duration duration, {
    required String message,
    required bool Function()? isStillValid,
  }) async {
    final rc = _retryCountdownController!;
    final msgController = _retryMessageController!;
    final totalMs = duration.inMilliseconds.toDouble();

    if (totalMs <= 0) {
      rc.add(0.0);
      _emit(0.0, message);
      _resetRetryState();
      return;
    }

    final startTime = DateTime.now().millisecondsSinceEpoch;
    var lastProgress = -1.0;

    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 50));

      if (_retryCancelled || cancellation.isCancelled) {
        LogTags.chatService.logWarning(
          'ChatRetryService: cancelled during wait',
        );
        _resetRetryState();
        throw Exception('cancelled');
      }

      if (isStillValid != null && !isStillValid()) {
        LogTags.chatService.logWarning(
          'ChatRetryService: superseded during wait, aborting',
        );
        _resetRetryState();
        throw Exception('cancelled');
      }

      final elapsed =
          (DateTime.now().millisecondsSinceEpoch - startTime) / totalMs;
      final progress = 1.0 - elapsed.clamp(0.0, 1.0);

      if (progress != lastProgress) {
        lastProgress = progress;

        final remainingMs = (progress * totalMs).round();
        final remainingDuration = Duration(milliseconds: remainingMs);
        final dynamicMessage = _injectCountdown(message, remainingDuration);

        if (!rc.isClosed) rc.add(progress);
        if (!msgController.isClosed) msgController.add(dynamicMessage);
      }

      if (progress <= 0.0) break;
    }

    _resetRetryState();
  }

  void cancelRetry() {
    _retryCancelled = true;
  }
}
