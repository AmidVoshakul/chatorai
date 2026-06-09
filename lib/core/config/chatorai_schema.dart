/// JSON Schema for `chatorai.json` configuration file.
///
/// This schema is used for runtime validation via `package:json_schema`
/// and can be referenced by IDE autocomplete using the `$schema` URL.
const Map<String, dynamic> chatoraiSchema = {
  r'$schema': 'http://json-schema.org/draft/2020-12/schema#',
  'type': 'object',
  'required': ['version', 'permission'],
  'properties': {
    'version': {'type': 'integer'},
    'permission': {
      'type': 'object',
      'additionalProperties': {
        'oneOf': [
          {
            'type': 'string',
            'enum': ['allow', 'ask', 'deny'],
          },
          {
            'type': 'object',
            'additionalProperties': {
              'type': 'string',
              'enum': ['allow', 'ask', 'deny'],
            },
          },
        ],
      },
    },
    'provider': {'type': 'object'},
    'keybinding': {'type': 'object'},
  },
};
