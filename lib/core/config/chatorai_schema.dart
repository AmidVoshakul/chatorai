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
    'keybinding': {'type': 'object'},
    'skills': {
      'type': 'object',
      'properties': {
        'paths': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'List of directories to scan for skills (SKILL.md files)',
        },
        'urls': {
          'type': 'array',
          'items': {
            'oneOf': [
              {'type': 'string'},
              {
                'type': 'object',
                'properties': {
                  'url': {'type': 'string'},
                  'cache_ttl': {'type': 'integer', 'minimum': 60},
                  'api_key': {'type': 'string'},
                },
                'required': ['url'],
              },
            ],
          },
          'description': 'List of remote skill sources (URLs to index.json)',
        },
      },
      'additionalProperties': false,
    },
  },
};
