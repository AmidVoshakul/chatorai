import 'package:json_schema/json_schema.dart';
import 'tool.dart';

export 'tool.dart' show SchemaValidationError;

class SchemaValidationResult {
  final bool isValid;
  final List<SchemaValidationError> errors;

  const SchemaValidationResult._({required this.isValid, required this.errors});

  factory SchemaValidationResult.valid() =>
      const SchemaValidationResult._(isValid: true, errors: []);

  factory SchemaValidationResult.invalid(List<SchemaValidationError> errors) =>
      SchemaValidationResult._(isValid: false, errors: errors);

  @override
  String toString() => isValid
      ? 'valid'
      : 'invalid: ${errors.map((e) => e.toString()).join('; ')}';
}

class JsonSchemaValidator {
  static const _defaultVersion = SchemaVersion.draft2020_12;

  static SchemaValidationResult validate(
    Map<String, dynamic> input,
    Map<String, dynamic> schema,
  ) {
    try {
      final jsonSchema = JsonSchema.create(
        schema,
        schemaVersion: _defaultVersion,
      );

      final result = jsonSchema.validate(input, validateFormats: true);
      if (result.isValid) return SchemaValidationResult.valid();

      final errors = result.errors
          .map(
            (e) => SchemaValidationError(
              path: e.instancePath.isEmpty ? '<root>' : e.instancePath,
              message: e.message,
              schemaPath: e.schemaPath,
            ),
          )
          .toList();

      return SchemaValidationResult.invalid(errors);
    } catch (e) {
      return SchemaValidationResult.invalid([
        SchemaValidationError(path: '<root>', message: 'Schema error: $e'),
      ]);
    }
  }
}
