import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/shared/utils/chat_error_utils.dart';

void main() {
  group('ChatErrorUtils', () {
    group('isRateLimitError', () {
      test('detects 429 status code', () {
        expect(
          ChatErrorUtils.isRateLimitError('HTTP 429 Too Many Requests'),
          isTrue,
        );
      });

      test('detects rate limit string (case-insensitive)', () {
        expect(ChatErrorUtils.isRateLimitError('Rate limit exceeded'), isTrue);
        expect(ChatErrorUtils.isRateLimitError('rate limit exceeded'), isTrue);
      });

      test('detects "too many requests" string', () {
        expect(ChatErrorUtils.isRateLimitError('Too many requests'), isTrue);
      });

      test('returns false for non-rate-limit errors', () {
        expect(ChatErrorUtils.isRateLimitError('400 Bad Request'), isFalse);
        expect(
          ChatErrorUtils.isRateLimitError('500 Internal Server Error'),
          isFalse,
        );
        expect(ChatErrorUtils.isRateLimitError('Unknown error'), isFalse);
        // "bad response" is not a rate limit indicator
        expect(
          ChatErrorUtils.isRateLimitError('DioException [bad response]'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(ChatErrorUtils.isRateLimitError(''), isFalse);
      });
    });

    group('isBadRequestError', () {
      test('detects 400 status code', () {
        expect(ChatErrorUtils.isBadRequestError('400 Bad Request'), isTrue);
      });

      test('detects "bad request" with status code', () {
        expect(
          ChatErrorUtils.isBadRequestError('HTTP 400 Bad Request'),
          isTrue,
        );
        expect(ChatErrorUtils.isBadRequestError('400 bad request'), isTrue);
      });

      test('detects "client error" with status code', () {
        expect(
          ChatErrorUtils.isBadRequestError('Client error occurred: 400'),
          isTrue,
        );
      });

      test('detects other 4xx codes', () {
        expect(ChatErrorUtils.isBadRequestError('404 Not Found'), isTrue);
        expect(
          ChatErrorUtils.isBadRequestError('422 Unprocessable Entity'),
          isTrue,
        );
      });

      test('returns false for non-bad-request errors', () {
        expect(
          ChatErrorUtils.isBadRequestError('500 Internal Server Error'),
          isFalse,
        );
        expect(ChatErrorUtils.isBadRequestError('429 Rate limit'), isFalse);
        expect(ChatErrorUtils.isBadRequestError('Unknown error'), isFalse);
        // "bad response" without a 4xx code is not a bad request
        expect(
          ChatErrorUtils.isBadRequestError('DioException [bad response]'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(ChatErrorUtils.isBadRequestError(''), isFalse);
      });
    });

    group('formatError', () {
      test('formats simple error string', () {
        final result = ChatErrorUtils.formatError('Something went wrong');
        expect(result, equals('Something went wrong'));
      });

      test('removes DioException bad response prefix', () {
        final result = ChatErrorUtils.formatError(
          'DioException [bad response]: Something went wrong',
        );
        expect(result, equals('Something went wrong'));
      });

      test('removes DioException connection error prefix', () {
        final result = ChatErrorUtils.formatError(
          'DioException [connection error]: Connection refused',
        );
        expect(result, equals('Connection refused'));
      });

      test('removes SocketException prefix', () {
        final result = ChatErrorUtils.formatError(
          'SocketException: Connection refused',
        );
        expect(result, equals('Connection refused'));
      });

      test('removes HttpException prefix', () {
        final result = ChatErrorUtils.formatError('HttpException: Not found');
        expect(result, equals('Not found'));
      });

      test('truncates long error messages to 500 chars', () {
        final longMessage = 'A' * 1000;
        final result = ChatErrorUtils.formatError(longMessage);
        expect(result.length, lessThanOrEqualTo(503)); // 500 + '...'
        expect(result, endsWith('...'));
      });

      test('parses JSON error with error field', () {
        final jsonError =
            '{"error": {"message": "Invalid API key", "code": "401"}}';
        final result = ChatErrorUtils.formatError(jsonError);
        expect(result, equals('Error 401: Invalid API key'));
      });

      test('handles JSON without error field gracefully', () {
        final jsonError = '{"status": "error", "detail": "Something"}';
        final result = ChatErrorUtils.formatError(jsonError);
        // Should return the original string (not JSON-parsed)
        expect(result, isNotEmpty);
      });

      test('handles non-JSON string that looks like JSON', () {
        final result = ChatErrorUtils.formatError('{not valid json}');
        expect(result, equals('{not valid json}'));
      });

      test('replaces escaped newlines', () {
        final result = ChatErrorUtils.formatError('Line1\\nLine2');
        expect(result, equals('Line1\nLine2'));
      });

      test('replaces escaped tabs', () {
        final result = ChatErrorUtils.formatError('Col1\\tCol2');
        expect(result, equals('Col1 Col2'));
      });
    });

    group('sanitizeMessages', () {
      test('preserves valid messages', () {
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi there'},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(2));
        expect(result[0]['content'], equals('Hello'));
        expect(result[1]['content'], equals('Hi there'));
      });

      test('removes assistant messages with error patterns', () {
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {
            'role': 'assistant',
            'content': 'DioException: Something went wrong',
          },
          {'role': 'user', 'content': 'Try again'},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(2));
        expect(
          result.any((m) => m['content'].toString().contains('DioException')),
          isFalse,
        );
      });

      test('removes assistant messages with Exception pattern', () {
        final messages = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Exception: Something failed'},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(1));
        expect(result[0]['role'], equals('user'));
      });

      test('preserves user messages with error patterns', () {
        final messages = [
          {'role': 'user', 'content': 'I got an Exception when running this'},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(1));
      });

      test('preserves multimodal content (list format)', () {
        final messages = [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Hello'},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:...'},
              },
            ],
          },
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(1));
        expect(result[0]['content'], isA<List>());
      });

      test('truncates very long messages', () {
        final longContent = 'A' * 30000;
        final messages = [
          {'role': 'user', 'content': longContent},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result[0]['content'].length, lessThan(longContent.length));
        expect(result[0]['content'], contains('[truncated]'));
      });

      test('handles empty messages list', () {
        final result = ChatErrorUtils.sanitizeMessages([]);
        expect(result, isEmpty);
      });

      test('handles message without content key', () {
        final messages = [
          {'role': 'user'},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(1));
        expect(result[0]['content'], equals(''));
      });

      test('handles message without role key', () {
        final messages = [
          {'content': 'Hello'},
        ];
        final result = ChatErrorUtils.sanitizeMessages(messages);
        expect(result.length, equals(1));
        expect(result[0]['role'], equals('user'));
      });
    });
  });
}
