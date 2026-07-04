import 'package:dio/dio.dart';

/// Centralized error classification for ChatORAI.
///
/// Replaces scattered `_isRetryableError()` logic in ChatAiService
/// and `isRateLimitError()` in ChatErrorUtils with a single, testable,
/// sealed-class hierarchy.
///
/// Classification rules (aligned with OpenCode patterns):
/// - 429 → RateLimitError (retryable)
/// - 401/403 → AuthenticationError (not retryable)
/// - 5xx → ServerError (retryable)
/// - 4xx (other) → ServerError (not retryable)
/// - Dio timeouts / connection errors → NetworkError (retryable)
/// - Everything else → UnknownError (retryable by default)

/// Base class for all classified errors.
sealed class ClassifiedError {
  const ClassifiedError();

  /// Whether the operation that caused this error should be retried.
  bool get isRetryable;

  /// Human-readable error message.
  String get message;

  /// Optional HTTP status code associated with the error.
  int? get statusCode;

  /// Optional retry-after duration extracted from headers.
  Duration? get retryAfter;

  /// OpenCode-compatible upsell reason (free_tier_limit, account_rate_limit).
  String? get reason;

  /// Raw error message from API/error body, if available.
  String? get rawMessage;
}

/// Rate limit error (HTTP 429).
class RateLimitError extends ClassifiedError {
  @override
  final int? statusCode;

  @override
  final Duration? retryAfter;

  @override
  /// OpenCode-compatible reason for upsell / UI actions:
  /// "free_tier_limit", "account_rate_limit", or null.
  final String? reason;

  @override
  final String? rawMessage;

  const RateLimitError({
    this.statusCode = 429,
    this.retryAfter,
    this.reason,
    this.rawMessage,
  });

  @override
  bool get isRetryable => true;

  @override
  String get message =>
      'Rate limit exceeded'
      '${retryAfter != null ? ' — retry after ${retryAfter!.inSeconds}s' : ''}'
      '${reason != null ? ' [$reason]' : ''}';
}

/// Context overflow error — the request exceeded the model's token limit.
///
/// Not retryable. Should trigger compaction instead of a new LLM call.
class OverflowError extends ClassifiedError {
  @override
  final int? statusCode;

  final String? detail;

  @override
  final String? rawMessage;

  const OverflowError({this.statusCode, this.detail, this.rawMessage});

  @override
  Duration? get retryAfter => null;

  @override
  String? get reason => null;

  @override
  bool get isRetryable => false;

  @override
  String get message =>
      'Context overflow'
      '${statusCode != null ? ' ($statusCode)' : ''}'
      '${detail != null ? ': $detail' : ''}';
}

/// Authentication / authorization error (HTTP 401, 403).
class AuthenticationError extends ClassifiedError {
  @override
  final int? statusCode;

  final String? detail;

  @override
  final String? rawMessage;

  const AuthenticationError({this.statusCode, this.detail, this.rawMessage});

  @override
  Duration? get retryAfter => null;

  @override
  String? get reason => null;

  @override
  bool get isRetryable => false;

  @override
  String get message =>
      'Authentication failed'
      '${statusCode != null ? ' ($statusCode)' : ''}'
      '${detail != null ? ': $detail' : ''}';
}

/// Server error (HTTP 4xx/5xx).
class ServerError extends ClassifiedError {
  @override
  final int? statusCode;

  final String? detail;

  @override
  final String? rawMessage;

  const ServerError({this.statusCode, this.detail, this.rawMessage});

  @override
  Duration? get retryAfter => null;

  @override
  String? get reason => null;

  @override
  bool get isRetryable => statusCode != null && statusCode! >= 500;

  @override
  String get message =>
      'Server error'
      '${statusCode != null ? ' ($statusCode)' : ''}'
      '${detail != null ? ': $detail' : ''}';
}

/// Network-level error (timeouts, connection failures).
class NetworkError extends ClassifiedError {
  final String? detail;

  @override
  final String? rawMessage;

  const NetworkError({this.detail, this.rawMessage});

  @override
  Duration? get retryAfter => null;

  @override
  String? get reason => null;

  @override
  bool get isRetryable => true;

  @override
  int? get statusCode => null;

  @override
  String get message =>
      'Network error'
      '${detail != null ? ': $detail' : ''}';
}

/// Unknown / unclassified error.
class UnknownError extends ClassifiedError {
  final Object? original;

  @override
  final String? rawMessage;

  const UnknownError({this.original, this.rawMessage});

  @override
  Duration? get retryAfter => null;

  @override
  String? get reason => null;

  @override
  bool get isRetryable => true;

  @override
  int? get statusCode => null;

  @override
  String get message =>
      'Unknown error'
      '${original != null ? ': $original' : ''}';
}

/// Centralized error classifier.
///
/// Takes any error object and returns a typed [ClassifiedError].
class ErrorClassifier {
  const ErrorClassifier();

  /// Classify an arbitrary error into a typed [ClassifiedError].
  ClassifiedError classify(Object error) {
    // 1. Already classified
    if (error is ClassifiedError) return error;

    // 2. DioException — inspect status code and headers
    if (error is DioException) {
      return _classifyDioException(error);
    }

    // 3. String-based heuristic matching
    return _classifyByString(error.toString());
  }

  ClassifiedError _classifyDioException(DioException e) {
    final response = e.response;
    final rawMessage = _extractRawMessage(e);

    if (response != null) {
      final statusCode = response.statusCode;

      // Check Retry-After headers
      final retryAfter = _extractRetryAfter(response.headers);

      if (statusCode == 429) {
        final reason = _classifyRateLimitReason(e);
        return RateLimitError(
          statusCode: statusCode,
          retryAfter: retryAfter,
          reason: reason,
          rawMessage: rawMessage,
        );
      }

      if (statusCode == 401 || statusCode == 403) {
        return AuthenticationError(statusCode: statusCode, rawMessage: rawMessage);
      }

      // Detect context overflow from error response body (400-level)
      if (statusCode == 400 && _isOverflowError(e)) {
        return OverflowError(
          statusCode: statusCode,
          detail: _extractOverflowDetail(e),
          rawMessage: rawMessage,
        );
      }

      if (statusCode != null && statusCode >= 400) {
        return ServerError(statusCode: statusCode, rawMessage: rawMessage);
      }
    }

    // Connection-level errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkError(detail: e.type.name, rawMessage: rawMessage);
    }

    // String-based overflow check as fallback
    if (e.message != null && _isOverflowString(e.message!)) {
      return OverflowError(detail: e.message, rawMessage: rawMessage);
    }

    return UnknownError(original: e, rawMessage: rawMessage);
  }

  String? _extractRawMessage(DioException e) {
    final data = e.response?.data;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      final msg = data['error']?['message'] ?? data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    final statusMessage = e.response?.statusMessage;
    if (statusMessage != null && statusMessage.isNotEmpty) return statusMessage;
    final message = e.message;
    if (message != null && message.isNotEmpty) return message;
    return null;
  }

  bool _isOverflowError(DioException e) {
    final message = e.message?.toLowerCase() ?? '';
    final responseStr = e.response?.statusMessage?.toLowerCase() ?? '';
    return _isOverflowString('$message $responseStr');
  }

  String? _extractOverflowDetail(DioException e) {
    final body = e.response?.data;
    if (body is Map) {
      final errorMsg = body['error']?['message'] ?? body['message'];
      if (errorMsg is String) return errorMsg;
    }
    return e.response?.statusMessage;
  }

  ClassifiedError _classifyByString(String errStr) {
    final lower = errStr.toLowerCase();

    // Rate limit patterns
    if (lower.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('too many requests')) {
      final reason = lower.contains('free') && lower.contains('limit')
          ? 'free_tier_limit'
          : lower.contains('go limit') || lower.contains('account')
          ? 'account_rate_limit'
          : null;
      return RateLimitError(reason: reason, rawMessage: errStr);
    }

    // Auth patterns
    if (lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden')) {
      final code = _extractStatusCode(lower);
      return AuthenticationError(statusCode: code, rawMessage: errStr);
    }

    // Server error patterns (5xx)
    if (lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('gateway timeout')) {
      final code = _extractStatusCode(lower);
      return ServerError(statusCode: code, rawMessage: errStr);
    }

    // Client error patterns (4xx, non-429)
    if (lower.contains('400') ||
        lower.contains('404') ||
        lower.contains('422') ||
        lower.contains('bad request') ||
        lower.contains('not found') ||
        lower.contains('unprocessable')) {
      final code = _extractStatusCode(lower);
      return ServerError(statusCode: code, rawMessage: errStr);
    }

    // Network patterns
    if (lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('connection reset') ||
        lower.contains('socket') ||
        lower.contains('econnreset') ||
        lower.contains('etimedout')) {
      return NetworkError(detail: errStr, rawMessage: errStr);
    }

    // Context overflow patterns (before UnknownError fallback)
    if (_isOverflowString(errStr)) {
      return OverflowError(detail: errStr, rawMessage: errStr);
    }

    return UnknownError(original: errStr, rawMessage: errStr);
  }

  /// Extract Retry-After duration from response headers.
  ///
  /// Supports:
  /// - `Retry-After-Ms` header (milliseconds, e.g. Anthropic)
  /// - `Retry-After` header as seconds (integer)
  /// - `Retry-After` header as HTTP-date (RFC 7231)
  Duration? _extractRetryAfter(Headers headers) {
    // Prefer retry-after-ms (milliseconds)
    final retryAfterMs = headers.value('retry-after-ms');
    if (retryAfterMs != null) {
      final ms = int.tryParse(retryAfterMs);
      if (ms != null) return Duration(milliseconds: ms);
    }

    // Fall back to retry-after (seconds or HTTP-date)
    final retryAfter = headers.value('retry-after');
    if (retryAfter != null) {
      // Try parsing as a number of seconds first
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) return Duration(seconds: seconds);

      // Try parsing as HTTP-date (RFC 7231)
      final parsedDate = DateTime.tryParse(retryAfter);
      if (parsedDate != null) {
        final delta = parsedDate.difference(DateTime.now());
        if (delta.isNegative) return Duration.zero;
        return delta;
      }
    }

    return null;
  }

  /// Detect OpenCode-style rate-limit sub-reasons from response body.
  ///
  /// Returns:
  /// - "free_tier_limit"       → FreeUsageLimitError found in body
  /// - "account_rate_limit"    → GoUsageLimitError found in body
  /// - null                    → no specific reason
  String? _classifyRateLimitReason(DioException e) {
    final body = e.response?.data;
    String? bodyStr;
    if (body is String) {
      bodyStr = body;
    } else if (body is Map) {
      final errorMsg = body['error']?['message'] ?? body['message'];
      if (errorMsg is String) bodyStr = errorMsg;
      final raw = body.toString();
      bodyStr = '$bodyStr $raw';
    }

    if (bodyStr == null || bodyStr.isEmpty) return null;
    final lower = bodyStr.toLowerCase();

    if (lower.contains('freeusagelimiterror') ||
        lower.contains('free_usage_limit') ||
        lower.contains('free tier limit')) {
      return 'free_tier_limit';
    }

    if (lower.contains('gousagelimiterror') ||
        lower.contains('go_usage_limit') ||
        lower.contains('go limit')) {
      return 'account_rate_limit';
    }

    return null;
  }

  /// Extract HTTP status code from error string.
  int? _extractStatusCode(String errStr) {
    final match = RegExp(r'\b(\d{3})\b').firstMatch(errStr);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static const _overflowPatterns = <String>[
    'context_length_exceeded',
    'maximum context length',
    'too many tokens',
    'context window',
    'token limit',
    'reduce the length',
    'prompt is too long',
    'context length',
    'context overflow',
    'token count exceeded',
    'maximum tokens',
    'input too long',
    'prompt length',
    'exceeds token limit',
    'too many tokens in prompt',
    'reduce prompt length',
    'message too long',
  ];

  bool _isOverflowString(String s) {
    final lower = s.toLowerCase();
    return _overflowPatterns.any(lower.contains);
  }
}
