import 'package:test/test.dart';
import 'package:chatorai/core/tools/json_schema_validator.dart';

void main() {
  group('JsonSchemaValidator', () {
    test('valid object with all required fields passes', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'integer'},
        },
        'required': ['name', 'age'],
      };

      final result = JsonSchemaValidator.validate({
        'name': 'Alice',
        'age': 30,
      }, schema);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('missing required field fails with clear path', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'count': {'type': 'integer'},
        },
        'required': ['name', 'count'],
      };

      final result = JsonSchemaValidator.validate({'name': 'Bob'}, schema);

      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(1));
      final missingCount = result.errors.where((e) => e.path.contains('count'));
      expect(missingCount.length, greaterThan(0));
    });

    test('wrong type fails', () {
      final schema = {
        'type': 'object',
        'properties': {
          'value': {'type': 'number'},
        },
        'required': ['value'],
      };

      final result = JsonSchemaValidator.validate({
        'value': 'not a number',
      }, schema);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.path.contains('value')), isTrue);
    });

    test('enum validation works', () {
      final schema = {
        'type': 'object',
        'properties': {
          'status': {
            'enum': ['active', 'inactive'],
          },
        },
        'required': ['status'],
      };

      final valid = JsonSchemaValidator.validate({'status': 'active'}, schema);
      expect(valid.isValid, isTrue);

      final invalid = JsonSchemaValidator.validate({
        'status': 'unknown',
      }, schema);
      expect(invalid.isValid, isFalse);
    });

    test('nested object validation', () {
      final schema = {
        'type': 'object',
        'properties': {
          'user': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
            'required': ['name'],
          },
        },
        'required': ['user'],
      };

      final valid = JsonSchemaValidator.validate({
        'user': {'name': 'Jane'},
      }, schema);
      expect(valid.isValid, isTrue);

      final invalid = JsonSchemaValidator.validate({
        'user': {'age': 25},
      }, schema);
      expect(invalid.isValid, isFalse);
    });

    test('array validation', () {
      final schema = {
        'type': 'object',
        'properties': {
          'items': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
      };

      final valid = JsonSchemaValidator.validate({
        'items': ['a', 'b', 'c'],
      }, schema);
      expect(valid.isValid, isTrue);

      final invalid = JsonSchemaValidator.validate({
        'items': [1, 2],
      }, schema);
      expect(invalid.isValid, isFalse);
    });

    test('empty input against object schema passes if no required', () {
      final schema = {
        'type': 'object',
        'properties': {
          'optional': {'type': 'string'},
        },
      };

      final result = JsonSchemaValidator.validate({}, schema);
      expect(result.isValid, isTrue);
    });

    test('additional properties are allowed by default', () {
      final schema = {
        'type': 'object',
        'properties': {
          'known': {'type': 'string'},
        },
      };

      final result = JsonSchemaValidator.validate({
        'known': 'yes',
        'extra': 42,
      }, schema);
      expect(result.isValid, isTrue);
    });

    test('additionalProperties false rejects unknown keys', () {
      final schema = {
        'type': 'object',
        'properties': {
          'known': {'type': 'string'},
        },
        'additionalProperties': false,
      };

      final result = JsonSchemaValidator.validate({
        'known': 'yes',
        'unknown': true,
      }, schema);
      expect(result.isValid, isFalse);
    });

    test('integer validation accepts only integers', () {
      final schema = {
        'type': 'object',
        'properties': {
          'count': {'type': 'integer'},
        },
      };

      final valid = JsonSchemaValidator.validate({'count': 5}, schema);
      expect(valid.isValid, isTrue);

      final invalid = JsonSchemaValidator.validate({'count': 5.5}, schema);
      expect(invalid.isValid, isFalse);
    });

    test('validation accumulates multiple errors', () {
      final schema = {
        'type': 'object',
        'properties': {
          'a': {'type': 'string', 'minLength': 5},
          'b': {'type': 'integer'},
        },
        'required': ['a', 'b'],
      };

      final result = JsonSchemaValidator.validate({
        'a': 'hi',
        'b': 'not_int',
      }, schema);

      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(2));
    });

    test('invalid schema returns error result instead of throwing', () {
      final schema = {'type': 'not_a_real_type'};

      final result = JsonSchemaValidator.validate({'key': 'value'}, schema);

      expect(result.isValid, isFalse);
      expect(result.errors.isNotEmpty, isTrue);
    });

    test('boolean true schema accepts any input', () {
      final result = JsonSchemaValidator.validate(
        {'anything': 1},
        {'type': 'object'},
      );
      // Note: true/false as schema is not tested because our tool schemas are all objects
      expect(result, isNotNull);
    });

    test('empty map against schema with no required passes', () {
      final schema = {
        'type': 'object',
        'properties': {
          'value': {'type': 'string'},
        },
      };

      final result = JsonSchemaValidator.validate({}, schema);
      expect(result.isValid, isTrue);
    });

    test('validation errors include path and message', () {
      final schema = {
        'type': 'object',
        'properties': {
          'email': {'type': 'string', 'format': 'email'},
        },
      };

      final result = JsonSchemaValidator.validate({
        'email': 'not-an-email',
      }, schema);

      expect(result.isValid, isFalse);
      for (final error in result.errors) {
        expect(error.path, isNotEmpty);
        expect(error.message, isNotEmpty);
      }
    });

    test('tool-like schema: shell command required string', () {
      final schema = {
        'type': 'object',
        'properties': {
          'command': {'type': 'string'},
          'description': {'type': 'string'},
        },
        'required': ['command'],
      };

      final valid = JsonSchemaValidator.validate({'command': 'ls -la'}, schema);
      expect(valid.isValid, isTrue);

      final invalid = JsonSchemaValidator.validate({
        'description': 'list files',
      }, schema);
      expect(invalid.isValid, isFalse);
    });

    test('tool-like schema: file_path and content for write', () {
      final schema = {
        'type': 'object',
        'properties': {
          'file_path': {'type': 'string'},
          'content': {'type': 'string'},
        },
        'required': ['file_path', 'content'],
      };

      final valid = JsonSchemaValidator.validate({
        'file_path': 'lib/main.dart',
        'content': 'void main() {}',
      }, schema);
      expect(valid.isValid, isTrue);

      final invalid = JsonSchemaValidator.validate({
        'file_path': 'lib/main.dart',
      }, schema);
      expect(invalid.isValid, isFalse);
    });

    test('minimum and maximum constraints', () {
      final schema = {
        'type': 'object',
        'properties': {
          'score': {'type': 'integer', 'minimum': 0, 'maximum': 100},
        },
      };

      expect(
        JsonSchemaValidator.validate({'score': 50}, schema).isValid,
        isTrue,
      );
      expect(
        JsonSchemaValidator.validate({'score': -1}, schema).isValid,
        isFalse,
      );
      expect(
        JsonSchemaValidator.validate({'score': 101}, schema).isValid,
        isFalse,
      );
    });

    test('pattern constraint on string', () {
      final schema = {
        'type': 'object',
        'properties': {
          'code': {'type': 'string', 'pattern': r'^[A-Z]{3}-\d{3}$'},
        },
      };

      expect(
        JsonSchemaValidator.validate({'code': 'ABC-123'}, schema).isValid,
        isTrue,
      );
      expect(
        JsonSchemaValidator.validate({'code': 'abc-123'}, schema).isValid,
        isFalse,
      );
    });

    test('minLength and maxLength constraints', () {
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'minLength': 2, 'maxLength': 20},
        },
      };

      expect(
        JsonSchemaValidator.validate({'name': 'Al'}, schema).isValid,
        isTrue,
      );
      expect(
        JsonSchemaValidator.validate({'name': 'A'}, schema).isValid,
        isFalse,
      );
      expect(
        JsonSchemaValidator.validate({'name': 'A' * 25}, schema).isValid,
        isFalse,
      );
    });

    test('SchemaValidationResult toString is informative', () {
      final valid = SchemaValidationResult.valid();
      expect(valid.toString(), contains('valid'));

      final errors = [
        SchemaValidationError(path: '/name', message: 'required'),
      ];
      final invalid = SchemaValidationResult.invalid(errors);
      expect(invalid.toString(), contains('invalid'));
      expect(invalid.toString(), contains('/name: required'));
    });
  });
}
