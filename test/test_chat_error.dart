import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/models/chat_error.dart';

void main() {
  group('ChatError sealed class', () {
    test('all error types are ChatError subtypes', () {
      const errors = <ChatError>[
        RateLimitError('rate limited'),
        AuthFailureError('auth failed'),
        ContextOverflowError('overflow'),
        ServerError('server error'),
        NetworkError('network error'),
        UnknownError('unknown'),
      ];
      expect(errors.length, 6);
    });

    test('all errors carry a message', () {
      const errors = <ChatError>[
        RateLimitError('rate'),
        AuthFailureError('auth'),
        ContextOverflowError('ctx'),
        ServerError('srv'),
        NetworkError('net'),
        UnknownError('unk'),
      ];
      for (final error in errors) {
        expect(error.message, isNotEmpty);
      }
    });
  });

  group('RateLimitError', () {
    test('creates with message only', () {
      const error = RateLimitError('Too many requests');
      expect(error.message, 'Too many requests');
      expect(error.retryAfter, isNull);
    });

    test('creates with retryAfter duration', () {
      const error = RateLimitError(
        'Rate limited',
        retryAfter: Duration(seconds: 30),
      );
      expect(error.retryAfter, const Duration(seconds: 30));
    });

    test('is a ChatError', () {
      const error = RateLimitError('test');
      expect(error, isA<ChatError>());
    });
  });

  group('AuthFailureError', () {
    test('creates with message', () {
      const error = AuthFailureError('Invalid API key');
      expect(error.message, 'Invalid API key');
    });

    test('is a ChatError', () {
      const error = AuthFailureError('test');
      expect(error, isA<ChatError>());
    });
  });

  group('ContextOverflowError', () {
    test('creates with message', () {
      const error = ContextOverflowError('Context window exceeded');
      expect(error.message, 'Context window exceeded');
    });

    test('is a ChatError', () {
      const error = ContextOverflowError('test');
      expect(error, isA<ChatError>());
    });
  });

  group('ServerError', () {
    test('creates with message only', () {
      const error = ServerError('Internal server error');
      expect(error.message, 'Internal server error');
      expect(error.statusCode, isNull);
    });

    test('creates with status code', () {
      const error = ServerError('Service unavailable', statusCode: 503);
      expect(error.statusCode, 503);
    });

    test('is a ChatError', () {
      const error = ServerError('test');
      expect(error, isA<ChatError>());
    });
  });

  group('NetworkError', () {
    test('creates with message', () {
      const error = NetworkError('Connection refused');
      expect(error.message, 'Connection refused');
    });

    test('is a ChatError', () {
      const error = NetworkError('test');
      expect(error, isA<ChatError>());
    });
  });

  group('UnknownError', () {
    test('creates with message', () {
      const error = UnknownError('Something unexpected happened');
      expect(error.message, 'Something unexpected happened');
    });

    test('is a ChatError', () {
      const error = UnknownError('test');
      expect(error, isA<ChatError>());
    });
  });

  group('Error message preservation', () {
    test('messages are preserved exactly', () {
      final messages = <String>[
        'Simple error',
        'Error with special chars: <>&"\'',
        'Error with unicode: ошибка エラー',
        'Error with\nnewlines',
        'Very long error message ' * 20,
      ];

      for (final msg in messages) {
        final error = UnknownError(msg);
        expect(error.message, msg);
      }
    });
  });

  group('Error type distinction', () {
    test('different error types are not equal', () {
      const a = RateLimitError('test');
      const b = AuthFailureError('test');
      const c = ServerError('test');
      // Different types should not be equal
      expect(a.runtimeType, isNot(equals(b.runtimeType)));
      expect(b.runtimeType, isNot(equals(c.runtimeType)));
    });

    test('same type with same message preserves type', () {
      const a = RateLimitError('test');
      const b = RateLimitError('test');
      expect(a.runtimeType, equals(b.runtimeType));
      expect(a.message, equals(b.message));
    });
  });
}
