import 'package:test/test.dart';
import 'package:dio/dio.dart';
import 'package:chatorai/core/error/error_classifier.dart';

/// Unit tests for ErrorClassifier.
void main() {
  late ErrorClassifier classifier;

  setUp(() {
    classifier = const ErrorClassifier();
  });

  group('ErrorClassifier.classify', () {
    test('returns same error if already classified', () {
      const classified = RateLimitError();
      final result = classifier.classify(classified);
      expect(result, same(classified));
    });
  });

  group('DioException classification', () {
    test('classifies 429 as RateLimitError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<RateLimitError>());
      expect(result.isRetryable, isTrue);
      expect(result.statusCode, equals(429));
    });

    test('classifies 401 as AuthenticationError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<AuthenticationError>());
      expect(result.isRetryable, isFalse);
      expect(result.statusCode, equals(401));
    });

    test('classifies 403 as AuthenticationError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<AuthenticationError>());
      expect(result.isRetryable, isFalse);
    });

    test('classifies 500 as ServerError (retryable)', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isTrue);
      expect(result.statusCode, equals(500));
    });

    test('classifies 502 as ServerError (retryable)', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 502,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies 503 as ServerError (retryable)', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 503,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies 400 as ServerError (not retryable)', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isFalse);
    });

    test('classifies 404 as ServerError (not retryable)', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isFalse);
    });

    test('detects context overflow in 400 response', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'context_length_exceeded',
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {
            'error': {'message': 'context_length_exceeded'},
          },
        ),
      );

      final result = classifier.classify(dio);
      expect(result, isA<OverflowError>());
      expect(result.isRetryable, isFalse);
    });

    test('classifies connectionTimeout as NetworkError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = classifier.classify(dio);
      expect(result, isA<NetworkError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies receiveTimeout as NetworkError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );

      final result = classifier.classify(dio);
      expect(result, isA<NetworkError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies sendTimeout as NetworkError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );

      final result = classifier.classify(dio);
      expect(result, isA<NetworkError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies connectionError as NetworkError', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final result = classifier.classify(dio);
      expect(result, isA<NetworkError>());
      expect(result.isRetryable, isTrue);
    });

    test('extracts Retry-After header (seconds)', () {
      final headers = Headers.fromMap({
        'retry-after': ['30'],
      });

      final result = classifier.classify(DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
          headers: headers,
        ),
      ));

      expect(result, isA<RateLimitError>());
      expect(result.retryAfter, equals(const Duration(seconds: 30)));
    });

    test('extracts Retry-After header (milliseconds)', () {
      final headers = Headers.fromMap({
        'retry-after-ms': ['5000'],
      });

      final result = classifier.classify(DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
          headers: headers,
        ),
      ));

      expect(result, isA<RateLimitError>());
      expect(result.retryAfter, equals(const Duration(milliseconds: 5000)));
    });
  });

  group('String-based classification', () {
    test('classifies "429" string as RateLimitError', () {
      final result = classifier.classify('HTTP 429 Too Many Requests');
      expect(result, isA<RateLimitError>());
    });

    test('classifies "rate limit" string as RateLimitError', () {
      final result = classifier.classify('rate limit exceeded');
      expect(result, isA<RateLimitError>());
    });

    test('classifies "too many requests" string as RateLimitError', () {
      final result = classifier.classify('too many requests');
      expect(result, isA<RateLimitError>());
    });

    test('classifies "401" string as AuthenticationError', () {
      final result = classifier.classify('HTTP 401 Unauthorized');
      expect(result, isA<AuthenticationError>());
    });

    test('classifies "403" string as AuthenticationError', () {
      final result = classifier.classify('HTTP 403 Forbidden');
      expect(result, isA<AuthenticationError>());
    });

    test('classifies "500" string as ServerError', () {
      final result = classifier.classify('HTTP 500 Internal Server Error');
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isTrue);
    });

    test('classifies "502" string as ServerError', () {
      final result = classifier.classify('HTTP 502 Bad Gateway');
      expect(result, isA<ServerError>());
    });

    test('classifies "503" string as ServerError', () {
      final result = classifier.classify('HTTP 503 Service Unavailable');
      expect(result, isA<ServerError>());
    });

    test('classifies "504" string as ServerError', () {
      final result = classifier.classify('HTTP 504 Gateway Timeout');
      expect(result, isA<ServerError>());
    });

    test('classifies "505" string as UnknownError (no specific pattern)', () {
      // The classifier only matches specific 5xx codes (500, 502, 503, 504).
      // 505 doesn't match any specific pattern, so it falls through to UnknownError.
      final result = classifier.classify('HTTP 505 something');
      expect(result, isA<UnknownError>());
    });

    test('classifies "404" string as ServerError (not retryable)', () {
      final result = classifier.classify('HTTP 404 Not Found');
      expect(result, isA<ServerError>());
      expect(result.isRetryable, isFalse);
    });

    test('classifies "400" string as ServerError', () {
      final result = classifier.classify('HTTP 400 Bad Request');
      expect(result, isA<ServerError>());
    });

    test('classifies "422" string as ServerError', () {
      final result = classifier.classify('HTTP 422 Unprocessable');
      expect(result, isA<ServerError>());
    });

    test('classifies "timeout" string as NetworkError', () {
      final result = classifier.classify('Connection timeout');
      expect(result, isA<NetworkError>());
    });

    test('classifies "network" string as NetworkError', () {
      final result = classifier.classify('Network error occurred');
      expect(result, isA<NetworkError>());
    });

    test('classifies "connection reset" string as NetworkError', () {
      final result = classifier.classify('connection reset by peer');
      expect(result, isA<NetworkError>());
    });

    test('classifies "econnreset" string as NetworkError', () {
      final result = classifier.classify('econnreset');
      expect(result, isA<NetworkError>());
    });

    test('classifies "etimedout" string as NetworkError', () {
      final result = classifier.classify('etimedout');
      expect(result, isA<NetworkError>());
    });

    test('classifies "socket" string as NetworkError', () {
      final result = classifier.classify('socket hang up');
      expect(result, isA<NetworkError>());
    });

    test('classifies "context length exceeded" as OverflowError', () {
      final result = classifier.classify('context_length_exceeded');
      expect(result, isA<OverflowError>());
    });

    test('classifies "maximum context length" as OverflowError', () {
      final result = classifier.classify('maximum context length exceeded');
      expect(result, isA<OverflowError>());
    });

    test('classifies "too many tokens" as OverflowError', () {
      final result = classifier.classify('too many tokens in request');
      expect(result, isA<OverflowError>());
    });

    test('classifies unknown string as UnknownError', () {
      final result = classifier.classify('something completely unexpected');
      expect(result, isA<UnknownError>());
      expect(result.isRetryable, isTrue);
    });
  });

  group('ClassifiedError properties', () {
    test('RateLimitError message includes retry after', () {
      const error = RateLimitError(retryAfter: Duration(seconds: 30));
      expect(error.message, contains('30s'));
    });

    test('RateLimitError message without retry after', () {
      const error = RateLimitError();
      expect(error.message, equals('Rate limit exceeded'));
    });

    test('AuthenticationError with detail', () {
      const error = AuthenticationError(
        statusCode: 401,
        detail: 'Invalid API key',
      );
      expect(error.message, contains('401'));
      expect(error.message, contains('Invalid API key'));
    });

    test('OverflowError with detail', () {
      const error = OverflowError(
        statusCode: 400,
        detail: 'context_length_exceeded',
      );
      expect(error.message, contains('400'));
      expect(error.message, contains('context_length_exceeded'));
    });

    test('ServerError with detail', () {
      const error = ServerError(statusCode: 500, detail: 'Internal error');
      expect(error.message, contains('500'));
      expect(error.message, contains('Internal error'));
    });

    test('NetworkError with detail', () {
      const error = NetworkError(detail: 'connection refused');
      expect(error.message, contains('connection refused'));
    });

    test('UnknownError with original', () {
      const error = UnknownError(original: 'weird error');
      expect(error.message, contains('weird error'));
    });
  });
}
