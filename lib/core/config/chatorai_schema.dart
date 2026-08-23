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
    'instructions': {
      'type': 'array',
      'items': {'type': 'string'},
      'description':
          'List of instruction globs or URLs merged into the system prompt. '
          'Supports relative globs resolved from the project root (e.g. '
          '".chatorai/instructions/*.md"), filenames searched upward '
          '(e.g. "AGENTS.md"), "~/" home expansion, absolute paths, and '
          'http(s) URLs.',
    },
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
    'keybinding': {
      'type': 'object',
      'additionalProperties': {'type': 'string'},
    },
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
        'tail_turns': {'type': 'integer', 'minimum': 1},
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
    'lsp': {
      'type': ['object', 'boolean'],
      'description':
          'LSP server configuration. Set to true to enable all built-in servers, false to disable all.',
      'properties': {
        'servers': {
          'type': 'object',
          'additionalProperties': {
            'type': 'object',
            'properties': {
              'disabled': {'type': 'boolean'},
              'command': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'args': {
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
              'languageId': {'type': 'string'},
              'initialization': {'type': 'object'},
              'autoInstall': {'type': 'boolean'},
            },
          },
        },
      },
    },
    'mcp': {
      'type': 'object',
      'description':
          'MCP server declarations. Servers may be listed directly under '
          '"mcp" or nested under "mcp.servers".',
      'properties': {
        'default_timeout': {'type': 'integer'},
        'defaultTimeout': {'type': 'integer'},
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
              'command': {
                'oneOf': [
                  {'type': 'string'},
                  {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                ],
              },
              'args': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'cwd': {'type': 'string'},
              'environment': {
                'type': 'object',
                'additionalProperties': {'type': 'string'},
              },
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
      // Flat layout: each key under "mcp" is a server name.
      'additionalProperties': {
        'type': 'object',
        'properties': {
          'type': {
            'type': 'string',
            'enum': ['local', 'remote'],
          },
          'enabled': {'type': 'boolean'},
          'timeout': {'type': 'integer'},
          'command': {
            'oneOf': [
              {'type': 'string'},
              {
                'type': 'array',
                'items': {'type': 'string'},
              },
            ],
          },
          'args': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'cwd': {'type': 'string'},
          'environment': {
            'type': 'object',
            'additionalProperties': {'type': 'string'},
          },
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
    'agent': {
      'type': 'object',
      'description': 'Agent overrides and customizations.',
      'additionalProperties': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'Override the agent name.'},
          'description': {
            'type': 'string',
            'description': 'Override the agent description.',
          },
          'prompt': {
            'type': 'string',
            'description': 'Override the agent system prompt.',
          },
          'disabled': {
            'type': 'boolean',
            'description': 'Remove this agent from registry.',
          },
          'hidden': {
            'type': 'boolean',
            'description': 'Hide this agent from UI.',
          },
          'max_steps': {
            'oneOf': [
              {'type': 'integer', 'minimum': 1},
              {'type': 'null'},
            ],
            'description':
                'Override max steps for agent execution. Omit to inherit from built-in/YAML definition.',
          },
          'maxSteps': {
            'oneOf': [
              {'type': 'integer', 'minimum': 1},
              {'type': 'null'},
            ],
            'description':
                'Alias for max_steps. Omit to inherit from built-in/YAML definition.',
          },
          'model': {
            'type': 'string',
            'description': 'Override the model for this agent.',
          },
          'temperature': {
            'type': 'number',
            'description': 'Override the temperature for this agent.',
          },
          'permission': {
            'type': 'object',
            'description': 'Permission overrides for this agent.',
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
          'tools': {
            'type': 'object',
            'description':
                'Tool visibility overrides. Glob patterns map to true (allow), false (deny), or "ask"/"allow"/"deny".',
            'additionalProperties': {
              'oneOf': [
                {'type': 'boolean'},
                {
                  'type': 'string',
                  'enum': ['allow', 'ask', 'deny'],
                },
              ],
            },
          },
        },
      },
    },
    'tools': {
      'type': 'object',
      'description':
          'Global tool visibility overrides. Glob patterns map to true (allow), false (deny), or "ask"/"allow"/"deny".',
      'additionalProperties': {
        'oneOf': [
          {'type': 'boolean'},
          {
            'type': 'string',
            'enum': ['allow', 'ask', 'deny'],
          },
        ],
      },
    },
    'provider': {
      'type': 'object',
      'description':
          'Custom LLM providers. Each key is a provider ID. '
          'All config providers are treated as OpenAI-compatible. The `apiKey` '
          'field supports a literal key, the "{env:VAR}" reference (resolved '
          'from the process environment, falling back to shell rc files on '
          'desktop), or the literal "public" for key-less providers.',
      'additionalProperties': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'description': 'Provider display name.',
          'options': {
            'type': 'object',
            'properties': {
              'baseURL': {'type': 'string'},
              'apiKey': {
                'type': 'string',
                'description':
                    'Literal key or "{env:VAR}" reference resolved at runtime.',
              },
              'temperature': {'type': 'number'},
            },
            'additionalProperties': true,
          },
          'models': {
            'type': 'object',
            'additionalProperties': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'limit': {
                  'type': 'object',
                  'properties': {
                    'context': {'type': 'integer', 'minimum': 0},
                    'output': {'type': 'integer', 'minimum': 0},
                  },
                },
              },
            },
          },
        },
      },
    },
  },
};
