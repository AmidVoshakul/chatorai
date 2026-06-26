import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:chatorai/core/error/error_classifier.dart';

void main() {
  const classifier = ErrorClassifier();

  // ── RateLimitError ─────────────────────────────────────────────────────

  group('ErrorClassifier.RateLimitError', () {
    test('classifies 429 DioException', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result, isA<RateLimitError>());
      expect(result.isRetryable, isTrue);
      expect(result.statusCode, equals(429));
    });

    test('extracts retry-after-ms header', () {
      final headers = Headers.fromMap({'retry-after-ms': ['5000']});
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
        headers: headers,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result.retryAfter, equals(const Duration(milliseconds: 5000)));
    });

    test('extracts retry-after header in seconds', () {
      final headers = Headers.fromMap({'retry-after': ['30']});
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
        headers: headers,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result.retryAfter, equals(const Duration(seconds: 30)));
    });

    test('retry-after-ms takes precedence over retry-after', () {
      final headers = Headers.fromMap({
        'retry-after-ms': ['2000'],
        'retry-after': ['60'],
      });
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 429,
        headers: headers,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result.retryAfter, equals(const Duration(milliseconds: 2000)));
    });

    test('classifies "rate limit" string', () {
      final result = classifier.classify(Exception('Rate limit exceeded'));
      expect(result, isA<RateLimitError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies "429" string', () {
      final result = classifier.classify('HTTP Error 429');
      expect(result, isA<RateLimitError>());
    });

    test('classifies "too many requests" string', () {
      final result = classifier.classify('Too many requests');
      expect(result, isA<RateLimitError>());
    });

    test('message includes retry-after when present', () {
      const error = RateLimitError(
        statusCode: 429,
        retryAfter: Duration(seconds: 30),
      );
      expect(error.message, contains('Rate limit exceeded'));
      expect(error.message, contains('30s'));
    });

    test('message without retry-after', () {
      const error = RateLimitError(statusCode: 429);
      expect(error.message, contains('Rate limit exceeded'));
      expect(error.message, isNot(contains('retry after')));
    });
  });

  // ── OverflowError ──────────────────────────────────────────────────────

  group('ErrorClassifier.OverflowError', () {
    test('classifies 400 DioException with overflow body', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
        statusMessage: 'context_length_exceeded',
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result, isA<OverflowError>());
      expect(result.isRetryable, isFalse);
      expect(result.statusCode, equals(400));
    });

    test('classifies string with "context_length_exceeded"', () {
      final result = classifier.classify('context_length_exceeded: too many tokens');
      expect(result, isA<OverflowError>());
      expect(result.isRetryable, isFalse);
    });

    test('classifies string with "token limit"', () {
      final result = classifier.classify('Token limit exceeded');
      expect(result, isA<OverflowError>());
    });

    test('classifies string with "prompt is too long"', () {
      final result = classifier.classify('prompt is too long');
      expect(result, isA<OverflowError>());
    });

    test('classifies string with "maximum context length"', () {
      final result = classifier.classify('maximum context length exceeded');
      expect(result, isA<OverflowError>());
    });

    test('extracts overflow detail from response body', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
        data: {
          'error': {'message': 'Token count exceeds model limit'},
        },
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        message: 'context_length_exceeded',
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error) as OverflowError;
      expect(result.detail, equals('Token count exceeds model limit'));
    });

    test('message includes status code and detail', () {
      const error = OverflowError(statusCode: 400, detail: 'too long');
      expect(error.message, contains('Context overflow'));
      expect(error.message, contains('400'));
      expect(error.message, contains('too long'));
    });

    test('message without status code or detail', () {
      const error = OverflowError();
      expect(error.message, equals('Context overflow'));
    });
  });

  // ── AuthenticationError ────────────────────────────────────────────────

  group('ErrorClassifier.AuthenticationError', () {
    test('classifies 401 DioException', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 401,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result, isA<AuthenticationError>());
      expect(result.isRetryable, isFalse);
      expect(result.statusCode, equals(401));
    });

    test('classifies 403 DioException', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 403,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result, isA<AuthenticationError>());
      expect(result.isRetryable, isFalse);
    });

    test('classifies "unauthorized" string', () {
      final result = classifier.classify('unauthorized access');
      expect(result, isA<AuthenticationError>());
    });

    test('classifies "forbidden" string', () {
      final result = classifier.classify('Access forbidden');
      expect(result, isA<AuthenticationError>());
    });
  });

  // ── ServerError ────────────────────────────────────────────────────────

  group('ErrorClassifier.ServerError', () {
    test('classifies 500 as retryable ServerError', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 500,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error);
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isTrue);
      expect(result.statusCode, equals(500));
    });

    test('classifies 502 as retryable', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 502,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error) as ServerError;
      expect(result.isRetryable, isTrue);
    });

    test('classifies 400 as non-retryable ServerError', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error) as ServerError;
      expect(result.isRetryable, isFalse);
    });

    test('classifies 404 as non-retryable ServerError', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 404,
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final result = classifier.classify(error) as ServerError;
      expect(result.isRetryable, isFalse);
    });

    test('classifies "internal server error" string', () {
      final result = classifier.classify('Internal Server Error');
      expect(result, isA<ServerError>());
    });

    test('classifies "service unavailable" string as ServerError', () {
      // "Service Unavailable" has no numeric status code → isRetryable=false
      final result = classifier.classify('Service Unavailable');
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isFalse); // null statusCode
    });

    test('classifies "503 service unavailable" as retryable', () {
      final result = classifier.classify('503 Service Unavailable');
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isTrue);
      expect(result.statusCode, equals(503));
    });

    test('classifies "bad request" string as non-retryable ServerError', () {
      final result = classifier.classify('Bad Request');
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isFalse);
    });
  });

  // ── NetworkError ───────────────────────────────────────────────────────

  group('ErrorClassifier.NetworkError', () {
    test('classifies connectionTimeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final result = classifier.classify(error);
      expect(result, isA<NetworkError>());
      expect(result.isRetryable, isTrue);
      expect(result.statusCode, isNull);
    });

    test('classifies receiveTimeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
      final result = classifier.classify(error);
      expect(result, isA<NetworkError>());
    });

    test('classifies sendTimeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );
      final result = classifier.classify(error);
      expect(result, isA<NetworkError>());
    });

    test('classifies connectionError', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final result = classifier.classify(error);
      expect(result, isA<NetworkError>());
    });

    test('classifies "timeout" string', () {
      final result = classifier.classify('Connection timeout');
      expect(result, isA<NetworkError>());
    });

    test('classifies "econnreset" string', () {
      final result = classifier.classify('ECONNRESET');
      expect(result, isA<NetworkError>());
    });

    test('classifies "socket" string', () {
      final result = classifier.classify('Socket closed');
      expect(result, isA<NetworkError>());
    });
  });

  // ── UnknownError ───────────────────────────────────────────────────────

  group('ErrorClassifier.UnknownError', () {
    test('classifies unhandled DioException type as UnknownError', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      final result = classifier.classify(error);
      expect(result, isA<UnknownError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies unknown string as UnknownError', () {
      final result = classifier.classify('some random error');
      expect(result, isA<UnknownError>());
      expect(result.isRetryable, isTrue);
    });
  });

  // ── Passthrough ────────────────────────────────────────────────────────

  group('ErrorClassifier.passthrough', () {
    test('returns same object if already ClassifiedError', () {
      const original = RateLimitError(statusCode: 429);
      final result = classifier.classify(original);
      expect(identical(result, original), isTrue);
    });
  });

  // ── Overflow patterns ──────────────────────────────────────────────────

  group('ErrorClassifier.overflow patterns', () {
    const overflowStrings = [
      'context_length_exceeded',
      'maximum context length',
      'too many tokens',
      'context window exceeded',
      'token limit exceeded',
      'reduce the length of the messages',
      'prompt is too long',
      'context length exceeded',
      'context overflow detected',
      'token count exceeded',
      'maximum tokens reached',
      'input too long for model',
      'prompt length too large',
      'exceeds token limit',
      'too many tokens in prompt',
      'reduce prompt length',
      'message too long',
    ];

    for (final s in overflowStrings) {
      test('classifies "$s" as OverflowError', () {
        final result = classifier.classify(s);
        expect(result, isA<OverflowError>(), reason: '"$s" should be OverflowError');
      });
    }
  });

  // ── DioException with overflow in message ──────────────────────────────

  group('ErrorClassifier.DioException overflow detection', () {
    test('DioException with null response and overflow message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'context_length_exceeded: too many tokens',
        type: DioExceptionType.unknown,
      );
      final result = classifier.classify(error);
      expect(result, isA<OverflowError>());
    });
  });
}
