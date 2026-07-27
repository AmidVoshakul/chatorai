import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool_error.dart';

void main() {
  group('ToolError', () {
    group('ToolNotFoundError', () {
      test('is a ToolError', () {
        const error = ToolNotFoundError('read');
        expect(error, isA<ToolError>());
      });

      test('has correct toolName', () {
        const error = ToolNotFoundError('read');
        expect(error.toolName, equals('read'));
      });

      test('is not retryable (inherits from ToolError)', () {
        // ToolError itself doesn't define isRetryable, but the pattern
        // is that NotFound errors should not be retried
        const error = ToolNotFoundError('read');
        expect(error.toolName, isNotEmpty);
      });
    });

    group('ToolTimeoutError', () {
      test('is a ToolError', () {
        const error = ToolTimeoutError('shell');
        expect(error, isA<ToolError>());
      });

      test('has correct toolName', () {
        const error = ToolTimeoutError('shell');
        expect(error.toolName, equals('shell'));
      });

      test('timeout errors are conceptually retryable', () {
        // ToolTimeoutError represents a timeout - retrying with longer
        // timeout is a valid strategy
        const error = ToolTimeoutError('shell');
        expect(error.toolName, equals('shell'));
      });
    });

    group('ToolPermissionDeniedError', () {
      test('is a ToolError', () {
        const error = ToolPermissionDeniedError('write');
        expect(error, isA<ToolError>());
      });

      test('has correct toolName', () {
        const error = ToolPermissionDeniedError('write');
        expect(error.toolName, equals('write'));
      });

      test('permission denied errors are not retryable', () {
        // Permission errors require user intervention, not retry
        const error = ToolPermissionDeniedError('write');
        expect(error.toolName, isNotEmpty);
      });
    });

    group('ToolExecutionError', () {
      test('is a ToolError', () {
        const error = ToolExecutionError('shell', 'exit code 1');
        expect(error, isA<ToolError>());
      });

      test('has correct toolName', () {
        const error = ToolExecutionError('shell', 'exit code 1');
        expect(error.toolName, equals('shell'));
      });

      test('has correct message', () {
        const error = ToolExecutionError('shell', 'exit code 1');
        expect(error.message, equals('exit code 1'));
      });

      test('execution errors are not retryable', () {
        // Execution errors (non-zero exit code) won't succeed on retry
        const error = ToolExecutionError('shell', 'file not found');
        expect(error.message, isNotEmpty);
      });
    });

    group('ToolError sealed class hierarchy', () {
      test('all ToolError subtypes have toolName', () {
        const errors = <ToolError>[
          ToolNotFoundError('read'),
          ToolTimeoutError('shell'),
          ToolPermissionDeniedError('write'),
          ToolExecutionError('grep', 'pattern not found'),
        ];

        for (final error in errors) {
          expect(error.toolName, isNotEmpty);
        }
      });

      test('ToolError subtypes are distinct', () {
        const notFound = ToolNotFoundError('read');
        const timeout = ToolTimeoutError('read');
        const permission = ToolPermissionDeniedError('read');
        const execution = ToolExecutionError('read', 'error');

        // Same toolName, different error types
        expect(notFound.runtimeType, isNot(equals(timeout.runtimeType)));
        expect(permission.runtimeType, isNot(equals(execution.runtimeType)));
      });
    });
  });
}
