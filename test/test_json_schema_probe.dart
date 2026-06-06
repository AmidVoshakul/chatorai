import 'package:chatorai/config/chatorai_schema.dart';
import 'package:json_schema/json_schema.dart';

void main() {
  final schema = JsonSchema.create(
    chatoraiSchema,
    schemaVersion: SchemaVersion.draft2020_12,
  );

  print('Empty object valid: ${schema.validate({}).isValid}');
  print(
    'Bad enum valid: ${schema.validate({
      'version': 1,
      'permission': {'bash': 'alloww'},
    }).isValid}',
  );
  print(
    'Good data valid: ${schema.validate({
      'version': 1,
      'permission': {'bash': 'ask'},
    }).isValid}',
  );
}
