import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/permission/permission_service.dart';

void main() {
  group('Permission errors', () {
    group('PermissionDeniedError', () {
      test('has correct message with toolName and pattern', () {
        final error = PermissionDeniedError('write', '/etc/passwd');
        expect(
          error.toString(),
          equals('Permission denied: write cannot access "/etc/passwd"'),
        );
      });

      test('has correct message for read tool', () {
        final error = PermissionDeniedError('read', '*.env');
        expect(
          error.toString(),
          equals('Permission denied: read cannot access "*.env"'),
        );
      });

      test('has correct message for bash tool', () {
        final error = PermissionDeniedError('bash', 'rm -rf /');
        expect(
          error.toString(),
          equals('Permission denied: bash cannot access "rm -rf /"'),
        );
      });

      test('stores toolName correctly', () {
        final error = PermissionDeniedError('edit', 'lib/main.dart');
        expect(error.toolName, equals('edit'));
      });

      test('stores pattern correctly', () {
        final error = PermissionDeniedError('read', 'secret.txt');
        expect(error.pattern, equals('secret.txt'));
      });

      test('implements Exception', () {
        final error = PermissionDeniedError('write', '/root');
        expect(error, isA<Exception>());
      });

      test('message includes both toolName and pattern', () {
        final error = PermissionDeniedError('glob', '**/*.key');
        final message = error.toString();
        expect(message, contains('glob'));
        expect(message, contains('**/*.key'));
      });
    });

    group('PermissionRejectedError', () {
      test('has correct message with toolName', () {
        final error = PermissionRejectedError('bash');
        expect(error.toString(), equals('Permission rejected by user: bash'));
      });

      test('has correct message for write tool', () {
        final error = PermissionRejectedError('write');
        expect(error.toString(), equals('Permission rejected by user: write'));
      });

      test('has correct message for edit tool', () {
        final error = PermissionRejectedError('edit');
        expect(error.toString(), equals('Permission rejected by user: edit'));
      });

      test('stores toolName correctly', () {
        final error = PermissionRejectedError('bash');
        expect(error.toolName, equals('bash'));
      });

      test('implements Exception', () {
        final error = PermissionRejectedError('bash');
        expect(error, isA<Exception>());
      });

      test('message indicates user rejection', () {
        final error = PermissionRejectedError('bash');
        final message = error.toString();
        expect(message, contains('rejected by user'));
        expect(message, contains('bash'));
      });
    });

    group('Error differentiation', () {
      test(
        'PermissionDeniedError and PermissionRejectedError are different',
        () {
          final denied = PermissionDeniedError('write', '/etc');
          final rejected = PermissionRejectedError('write');

          expect(denied.runtimeType, isNot(equals(rejected.runtimeType)));
        },
      );

      test('PermissionDeniedError includes pattern, rejected does not', () {
        final denied = PermissionDeniedError('write', '/etc/passwd');
        final rejected = PermissionRejectedError('write');

        expect(denied.toString(), contains('/etc/passwd'));
        expect(rejected.toString(), isNot(contains('/etc/passwd')));
      });
    });
  });
}
