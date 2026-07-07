import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:chatorai/core/error/error_classifier.dart';
import 'package:chatorai/features/chat/services/chat_retry_service.dart';
import 'package:chatorai/features/chat/services/chat_cancellation.dart';

class FakeError implements Exception {
  final String message;
  const FakeError(this.message);
  @override
  String toString() => 'FakeError: $message';
}

void main() {
  group('ChatRetryService infinite retry', () {
    test('retries forever on NetworkError until success', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;
      int successes = 0;

      await service.execute(
        ({void Function()? onChunkReceived}) async {
          attempts++;
          if (attempts < 4) {
            throw const FakeError('timeout');
          }
          successes++;
          return 'ok';
        },
        onRetry: (info) {
          expect(info.attempt, greaterThanOrEqualTo(0));
          expect(info.message, contains('attempt #'));
        },
      );

      expect(attempts, equals(4));
      expect(successes, equals(1));
      expect(service.isRetrying, isFalse);
    });

    test('retries forever on ServerError (5xx) until success', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;

      await service.execute(({void Function()? onChunkReceived}) async {
        attempts++;
        if (attempts < 3) {
          throw DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 503,
              data: 'Service Unavailable',
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return 'ok';
      });

      expect(attempts, equals(3));
      expect(service.isRetrying, isFalse);
    });

    test('raw message from API appears in retry header', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      String? capturedMessage;
      int attempts = 0;

      await service.execute(
        ({void Function()? onChunkReceived}) async {
          attempts++;
          if (attempts < 2) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              response: Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 429,
                data: 'You have exceeded your current quota',
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return 'ok';
        },
        onRetry: (info) {
          capturedMessage = info.message;
        },
      );

      expect(capturedMessage, contains('You have exceeded your current quota'));
      expect(capturedMessage, contains('attempt #1'));
    });

    test('falls back to template when rawMessage is empty', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      String? capturedMessage;
      int attempts = 0;

      await service.execute(
        ({void Function()? onChunkReceived}) async {
          attempts++;
          if (attempts < 2) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              response: Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 500,
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return 'ok';
        },
        onRetry: (info) {
          capturedMessage = info.message;
        },
      );

      expect(capturedMessage, contains('Server error (500)'));
      expect(capturedMessage, contains('attempt #1'));
    });

    test('stops immediately on non-retryable AuthenticationError', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;

      expect(
        () async =>
            await service.execute(({void Function()? onChunkReceived}) async {
              attempts++;
              throw DioException(
                requestOptions: RequestOptions(path: '/test'),
                response: Response(
                  requestOptions: RequestOptions(path: '/test'),
                  statusCode: 401,
                ),
                type: DioExceptionType.badResponse,
              );
            }),
        throwsA(isA<DioException>()),
      );

      expect(attempts, equals(1));
      expect(service.isRetrying, isFalse);
    });

    test('stops immediately on ContextOverflowError', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;

      expect(
        () async =>
            await service.execute(({void Function()? onChunkReceived}) async {
              attempts++;
              throw OverflowError(detail: 'context too long');
            }),
        throwsA(isA<OverflowError>()),
      );

      expect(attempts, equals(1));
      expect(service.isRetrying, isFalse);
    });

    test('cancellation during backoff stops immediately', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;

      final future = service.execute(({
        void Function()? onChunkReceived,
      }) async {
        attempts++;
        throw const FakeError('always fails');
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      service.cancelRetry();

      try {
        await future;
        fail('expected throw');
      } catch (_) {}

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.isRetrying, isFalse);
    });

    test('chunkReceived resets attempt counter after success', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;

      await service.execute(({void Function()? onChunkReceived}) async {
        attempts++;
        if (attempts == 1) {
          onChunkReceived?.call();
          throw const FakeError('fail after chunk');
        }
        return 'ok';
      });

      expect(attempts, equals(2));
    });

    test('429 without retry-after uses exponential backoff', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      int attempts = 0;

      await service.execute(({void Function()? onChunkReceived}) async {
        attempts++;
        if (attempts < 2) {
          throw DioException(
            requestOptions: RequestOptions(path: '/test'),
            response: Response(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: 429,
              headers: Headers.fromMap({}),
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return 'ok';
      });

      expect(attempts, equals(2));
    });

    test('FreeUsageLimitError body produces free_tier_limit header', () async {
      final cancellation = ChatCancellation();
      final service = ChatRetryService(cancellation: cancellation);
      String? captured;
      int attempts = 0;

      await service.execute(
        ({void Function()? onChunkReceived}) async {
          attempts++;
          if (attempts < 2) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              response: Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 429,
                data: 'FreeUsageLimitError: you exceeded your free tier',
              ),
              type: DioExceptionType.badResponse,
            );
          }
          return 'ok';
        },
        onRetry: (info) {
          captured = info.message;
        },
      );

      expect(
        captured,
        contains('FreeUsageLimitError: you exceeded your free tier'),
      );
      expect(captured, contains('attempt #1'));
    });
  });
}
