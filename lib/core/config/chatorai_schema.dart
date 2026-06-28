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
    'compaction': {
      'type': 'object',
      'properties': {
        'auto': {'type': 'boolean'},
        'prune': {'type': 'boolean'},
        'keep': {
          'type': 'object',
          'properties': {
            'tokens': {'type': 'integer', 'minimum': 0},
          },
        },
        'buffer': {'type': 'integer', 'minimum': 0},
      },
    },
    'formatter': {
      'type': 'object',
      'properties': {
        'formatters': {
          'type': 'object',
          'additionalProperties': {
            'type': 'object',
            'properties': {
              'disabled': {'type': 'boolean'},
              'command': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'environment': {
                'type': 'object',
                'additionalProperties': {'type': 'string'},
              },
              'extensions': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
        },
      },
    },
    'mcp': {
      'type': 'object',
      'properties': {
        'default_timeout': {'type': 'integer'},
        'servers': {
          'type': 'object',
          'additionalProperties': {
            'type': 'object',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['local', 'remote'],
              },
              'enabled': {'type': 'boolean'},
              'timeout': {'type': 'integer'},
              // local
              'command': {'type': 'string'},
              'args': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'cwd': {'type': 'string'},
              'environment': {
                'type': 'object',
                'additionalProperties': {'type': 'string'},
              },
              // remote
              'url': {'type': 'string'},
              'headers': {
                'type': 'object',
                'additionalProperties': {'type': 'string'},
              },
              'oauth': {
                'type': 'object',
                'properties': {
                  'client_id': {'type': 'string'},
                  'client_secret': {'type': 'string'},
                  'scope': {'type': 'string'},
                  'callback_port': {'type': 'integer'},
                  'redirect_uri': {'type': 'string'},
                },
              },
            },
          },
        },
      },
    },
  },
};
