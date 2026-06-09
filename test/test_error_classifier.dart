import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:chatorai/core/error/error_classifier.dart';

void main() {
  const classifier = ErrorClassifier();

  group('ErrorClassifier', () {
    group('RateLimitError', () {
      test('classifies 429 DioException as RateLimitError', () {
        final headers = Headers.fromMap({
          'retry-after': ['30'],
        });
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
          headers: headers,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<RateLimitError>());
        expect(result.isRetryable, isTrue);
        expect(result.statusCode, equals(429));
        expect(result.retryAfter, equals(const Duration(seconds: 30)));
      });

      test('classifies "rate limit" string as RateLimitError', () {
        final result = classifier.classify(Exception('Rate limit exceeded'));

        expect(result, isA<RateLimitError>());
        expect(result.isRetryable, isTrue);
        expect(result.statusCode, equals(429));
      });

      test('classifies "429" string as RateLimitError', () {
        final result = classifier.classify('HTTP Error 429');

        expect(result, isA<RateLimitError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "too many requests" string as RateLimitError', () {
        final result = classifier.classify('Too many requests');

        expect(result, isA<RateLimitError>());
        expect(result.isRetryable, isTrue);
      });

      test('extracts retry-after-ms header from DioException', () {
        final headers = Headers.fromMap({
          'retry-after-ms': ['5000'],
        });
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
          headers: headers,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<RateLimitError>());
        expect(result.retryAfter, equals(const Duration(milliseconds: 5000)));
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
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = classifier.classify(dioError);

        expect(result.retryAfter, equals(const Duration(milliseconds: 2000)));
      });
    });

    group('AuthenticationError', () {
      test('classifies 401 DioException as AuthenticationError', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<AuthenticationError>());
        expect(result.isRetryable, isFalse);
        expect(result.statusCode, equals(401));
      });

      test('classifies 403 DioException as AuthenticationError', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
        );
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<AuthenticationError>());
        expect(result.isRetryable, isFalse);
        expect(result.statusCode, equals(403));
      });

      test('classifies "401" string as AuthenticationError', () {
        final result = classifier.classify('Error 401 Unauthorized');

        expect(result, isA<AuthenticationError>());
        expect(result.isRetryable, isFalse);
      });

      test('classifies "unauthorized" string as AuthenticationError', () {
        final result = classifier.classify('unauthorized access');

        expect(result, isA<AuthenticationError>());
        expect(result.isRetryable, isFalse);
      });
    });

    group('ServerError', () {
      test(
        'classifies 500 DioException as ServerError with retryable=true',
        () {
          final response = Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          );
          final dioError = DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: response,
            type: DioExceptionType.badResponse,
          );

          final result = classifier.classify(dioError);

          expect(result, isA<ServerError>());
          expect(result.isRetryable, isTrue);
          expect(result.statusCode, equals(500));
        },
      );

      test(
        'classifies 503 DioException as ServerError with retryable=true',
        () {
          final response = Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
          );
          final dioError = DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: response,
            type: DioExceptionType.badResponse,
          );

          final result = classifier.classify(dioError);

          expect(result, isA<ServerError>());
          expect(result.isRetryable, isTrue);
          expect(result.statusCode, equals(503));
        },
      );

      test(
        'classifies 400 DioException as ServerError with retryable=false',
        () {
          final response = Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
          );
          final dioError = DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: response,
            type: DioExceptionType.badResponse,
          );

          final result = classifier.classify(dioError);

          expect(result, isA<ServerError>());
          expect(result.isRetryable, isFalse);
          expect(result.statusCode, equals(400));
        },
      );

      test(
        'classifies 404 DioException as ServerError with retryable=false',
        () {
          final response = Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          );
          final dioError = DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: response,
            type: DioExceptionType.badResponse,
          );

          final result = classifier.classify(dioError);

          expect(result, isA<ServerError>());
          expect(result.isRetryable, isFalse);
          expect(result.statusCode, equals(404));
        },
      );

      test('classifies "500" string as ServerError', () {
        final result = classifier.classify('Internal Server Error 500');

        expect(result, isA<ServerError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "502" string as ServerError', () {
        final result = classifier.classify('Bad Gateway 502');

        expect(result, isA<ServerError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "400" string as ServerError with retryable=false', () {
        final result = classifier.classify('Bad Request 400');

        expect(result, isA<ServerError>());
        expect(result.isRetryable, isFalse);
      });
    });

    group('NetworkError', () {
      test('classifies DioException connectionTimeout as NetworkError', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies DioException receiveTimeout as NetworkError', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies DioException connectionError as NetworkError', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "timeout" string as NetworkError', () {
        final result = classifier.classify('Connection timeout');

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "network" string as NetworkError', () {
        final result = classifier.classify('Network unreachable');

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "connection reset" string as NetworkError', () {
        final result = classifier.classify('connection reset by peer');

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });

      test('classifies "econnreset" string as NetworkError', () {
        final result = classifier.classify('ECONNRESET');

        expect(result, isA<NetworkError>());
        expect(result.isRetryable, isTrue);
      });
    });

    group('UnknownError', () {
      test('classifies unknown error as UnknownError', () {
        final result = classifier.classify('some random error');

        expect(result, isA<UnknownError>());
        expect(result.isRetryable, isTrue); // Default to retry
      });

      test('classifies unhandled DioException type as UnknownError', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );

        final result = classifier.classify(dioError);

        expect(result, isA<UnknownError>());
        expect(result.isRetryable, isTrue);
      });
    });

    group('ClassifiedError passthrough', () {
      test('returns same error if already ClassifiedError', () {
        const original = RateLimitError(statusCode: 429);
        final result = classifier.classify(original);

        expect(result, same(original));
      });
    });

    group('ErrorClassifier messages', () {
      test('RateLimitError message includes retry-after', () {
        const error = RateLimitError(
          statusCode: 429,
          retryAfter: Duration(seconds: 30),
        );
        expect(error.message, contains('Rate limit exceeded'));
        expect(error.message, contains('30s'));
      });

      test('AuthenticationError message includes status code', () {
        const error = AuthenticationError(statusCode: 401);
        expect(error.message, contains('Authentication failed'));
        expect(error.message, contains('401'));
      });

      test('ServerError message includes status code', () {
        const error = ServerError(statusCode: 500);
        expect(error.message, contains('Server error'));
        expect(error.message, contains('500'));
      });

      test('NetworkError message includes detail', () {
        const error = NetworkError(detail: 'connectionTimeout');
        expect(error.message, contains('Network error'));
        expect(error.message, contains('connectionTimeout'));
      });

      test('UnknownError message includes original', () {
        const error = UnknownError(original: 'mystery error');
        expect(error.message, contains('Unknown error'));
        expect(error.message, contains('mystery error'));
      });
    });
  });
}
