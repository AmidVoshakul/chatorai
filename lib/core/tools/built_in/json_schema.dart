import 'package:chatorai/core/tools/json_schema_validator.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createJsonSchemaTool() {
  return ToolDef(
    id: 'json_schema',
    description:
        'Validate JSON data against a JSON Schema (draft 2020-12). '
        'Use this tool when you need to verify the structure of JSON data '
        'before processing or when the user asks for schema validation.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'schema': {
          'type': 'object',
          'description':
              'JSON Schema object to validate against (draft 2020-12)',
        },
        'data': {'type': 'object', 'description': 'JSON data to validate'},
      },
      'required': ['schema', 'data'],
    },
    execute: (input, ctx) async {
      LogTags.permission.logInfo('JsonSchemaTool: validating JSON');

      final schema = input['schema'] as Map<String, dynamic>?;
      final data = input['data'];

      if (schema == null) {
        return ToolOutput(
          'Error: "schema" field is required and must be an object',
          metadata: {'error': true},
        );
      }

      if (data == null) {
        return ToolOutput(
          'Error: "data" field is required',
          metadata: {'error': true},
        );
      }

      final inputMap = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{'value': data};

      final result = JsonSchemaValidator.validate(inputMap, schema);

      if (result.isValid) {
        LogTags.permission.logInfo('JsonSchemaTool: validation passed');
        return ToolOutput(
          'Validation passed: JSON data matches the provided schema',
          metadata: {'valid': true, 'schema': schema, 'data': inputMap},
        );
      }

      final errors = result.errors.map((e) => e.toString()).toList();
      LogTags.permission.logInfo(
        'JsonSchemaTool: validation failed with ${errors.length} errors',
      );

      return ToolOutput(
        'Validation failed with ${errors.length} error(s):\n${errors.join('\n')}',
        metadata: {
          'valid': false,
          'errors': errors,
          'schema': schema,
          'data': inputMap,
        },
      );
    },
  );
}
