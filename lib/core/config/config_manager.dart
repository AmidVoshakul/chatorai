import 'dart:convert';

import 'chatorai_schema.dart';
import 'config_loader.dart';
import 'models/chatorai_config.dart';
import 'package:json_schema/json_schema.dart';

/// Validates and parses `chatorai.json` into [ChatOrAIConfig].
class ConfigManager {
  static Future<ChatOrAIConfig> loadConfig() async {
    final rawJson = await ConfigLoader.load();

    Map<String, dynamic> data;
    try {
      data = json.decode(rawJson) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw ConfigValidationError('Malformed JSON: ${e.message}');
    }

    // Validate against schema
    final schema = JsonSchema.create(
      chatoraiSchema,
      schemaVersion: SchemaVersion.draft2020_12,
    );
    final validationResult = schema.validate(data);
    if (!validationResult.isValid) {
      final errors = validationResult.errors;
      final message = errors.isNotEmpty
          ? errors.first.toString()
          : 'Unknown validation error';
      throw ConfigValidationError(message);
    }

    // Manual validation for permission enum values
    // (json_schema 5.2.2 has limited support for oneOf inside additionalProperties)
    final permission = data['permission'] as Map<String, dynamic>? ?? {};
    for (final entry in permission.entries) {
      final value = entry.value;
      if (value is String) {
        if (value != 'allow' && value != 'ask' && value != 'deny') {
          throw ConfigValidationError(
            'Invalid permission action "$value" for "${entry.key}". '
            'Must be one of: allow, ask, deny',
          );
        }
      } else if (value is Map<String, dynamic>) {
        for (final actionEntry in value.entries) {
          if (actionEntry.value is! String) {
            throw ConfigValidationError(
              'Invalid permission action type for "${entry.key}.${actionEntry.key}". '
              'Must be a string.',
            );
          }
          final action = actionEntry.value as String;
          if (action != 'allow' && action != 'ask' && action != 'deny') {
            throw ConfigValidationError(
              'Invalid permission action "$action" for "${entry.key}.${actionEntry.key}". '
              'Must be one of: allow, ask, deny',
            );
          }
        }
      }
    }

    return ChatOrAIConfig.fromJson(data);
  }
}
