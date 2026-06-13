import 'dart:io';

import 'package:chatorai/features/skills/domain/errors/skill_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillError', () {
    group('ParseError', () {
      test('constructs with message only', () {
        final error = ParseError('Invalid YAML');
        expect(error.message, 'Invalid YAML');
        expect(error.filePath, isNull);
        expect(error.line, isNull);
      });

      test('constructs with all fields', () {
        final error = ParseError(
          'Invalid syntax',
          filePath: '/path/to/file',
          line: 42,
        );
        expect(error.message, 'Invalid syntax');
        expect(error.filePath, '/path/to/file');
        expect(error.line, 42);
      });

      test('toString formats correctly with message only', () {
        final error = ParseError('YAML parse error');
        expect(error.toString(), 'ParseError: YAML parse error');
      });

      test('toString includes filePath when provided', () {
        final error = ParseError('Missing field', filePath: '/skills/SKILL.md');
        expect(
          error.toString(),
          'ParseError: Missing field in /skills/SKILL.md',
        );
      });

      test('toString includes line when provided', () {
        final error = ParseError('Invalid format', line: 15);
        expect(error.toString(), 'ParseError: Invalid format at line 15');
      });

      test('toString includes both filePath and line', () {
        final error = ParseError('Error', filePath: '/test.md', line: 10);
        expect(error.toString(), 'ParseError: Error in /test.md at line 10');
      });
    });

    group('NotFoundError', () {
      test('constructs with name', () {
        final error = NotFoundError('missing-skill');
        expect(error.name, 'missing-skill');
      });

      test('toString formats correctly', () {
        final error = NotFoundError('test-skill');
        expect(error.toString(), 'NotFoundError: skill "test-skill" not found');
      });
    });

    group('PermissionDeniedError', () {
      test('constructs with skill and agent names', () {
        final error = PermissionDeniedError('restricted-skill', 'agent-1');
        expect(error.skillName, 'restricted-skill');
        expect(error.agentName, 'agent-1');
      });

      test('toString formats correctly', () {
        final error = PermissionDeniedError('skill-a', 'agent-b');
        expect(
          error.toString(),
          'PermissionDenied: agent "agent-b" cannot access skill "skill-a"',
        );
      });
    });

    group('SourceError', () {
      test('constructs with source and exception', () {
        final exception = Exception('Connection failed');
        final error = SourceError('directory:/path', exception);
        expect(error.source, 'directory:/path');
        expect(error.exception, exception);
      });

      test('toString includes source and exception message', () {
        final error = SourceError(
          'url:https://example.com',
          HttpException('404'),
        );
        expect(
          error.toString(),
          contains('SourceError (url:https://example.com)'),
        );
        expect(error.toString(), contains('404'));
      });
    });

    group('ValidationError', () {
      test('constructs with message only', () {
        final error = ValidationError('Schema mismatch');
        expect(error.message, 'Schema mismatch');
        expect(error.data, isNull);
      });

      test('constructs with data', () {
        final data = {'field': 'value'};
        final error = ValidationError('Invalid value', data: data);
        expect(error.message, 'Invalid value');
        expect(error.data, data);
      });

      test('toString formats correctly', () {
        final error = ValidationError('Required field missing');
        expect(error.toString(), 'ValidationError: Required field missing');
      });
    });

    group('Sealed class behavior', () {
      test('all errors extend SkillError', () {
        final errors = <SkillError>[
          ParseError('test'),
          NotFoundError('test'),
          PermissionDeniedError('skill', 'agent'),
          SourceError('source', Exception('test')),
          ValidationError('test'),
        ];

        for (final error in errors) {
          expect(error, isA<SkillError>());
        }
      });

      test('errors are distinct types', () {
        final parseError = ParseError('test');
        final notFoundError = NotFoundError('test');
        final permissionError = PermissionDeniedError('skill', 'agent');
        final sourceError = SourceError('source', Exception('test'));
        final validationError = ValidationError('test');

        expect(
          parseError.runtimeType,
          isNot(equals(notFoundError.runtimeType)),
        );
        expect(
          permissionError.runtimeType,
          isNot(equals(sourceError.runtimeType)),
        );
        expect(
          validationError.runtimeType,
          isNot(equals(parseError.runtimeType)),
        );
      });
    });
  });
}
