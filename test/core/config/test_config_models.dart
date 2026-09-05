import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/config/models/permission_section.dart';

void main() {
  // ── ChatOrAIConfig.fromJson ────────────────────────────────────────────

  group('ChatOrAIConfig.fromJson', () {
    test('parses minimal config with defaults', () {
      final config = ChatOrAIConfig.fromJson({});
      expect(config.version, equals(0));
      expect(config.permission, isEmpty);
      expect(config.keybinding, isNull);
      expect(config.skills, isNull);
      expect(config.compaction, isNull);
    });

    test('parses full config with all fields', () {
      final json = {
        'version': 1,
        'permission': {'shell': 'ask', 'read': 'allow'},
        'keybinding': {'session_child_next': 'ctrl+right'},
        'skills': {
          'paths': ['/path/to/skills'],
          'urls': [
            {'url': 'https://example.com/skill.md'},
          ],
        },
        'compaction': {
          'auto': true,
          'prune': true,
          'keep': {'tokens': 10000},
          'buffer': 30000,
        },
      };

      final config = ChatOrAIConfig.fromJson(json);

      expect(config.version, equals(1));
      expect(config.permission['shell']?.defaultAction, equals('ask'));
      expect(config.permission['read']?.defaultAction, equals('allow'));
      expect(config.keybinding?['session_child_next'], equals('ctrl+right'));
      expect(config.skills, isNotNull);
      expect(config.skills!.paths, equals(['/path/to/skills']));
      expect(config.compaction, isNotNull);
      expect(config.compaction!.auto, isTrue);
      expect(config.compaction!.prune, isTrue);
      expect(config.compaction!.buffer, equals(30000));
    });

    test('parses permission section with patternActions', () {
      final json = {
        'version': 1,
        'permission': {
          'shell': {'git *': 'allow', 'rm *': 'deny'},
        },
      };

      final config = ChatOrAIConfig.fromJson(json);
      final shellConfig = config.permission['shell'];
      expect(shellConfig, isNotNull);
      expect(shellConfig!.defaultAction, isNull);
      expect(shellConfig.patternActions?['git *'], equals('allow'));
      expect(shellConfig.patternActions?['rm *'], equals('deny'));
    });

    test('handles missing permission section gracefully', () {
      final config = ChatOrAIConfig.fromJson({'version': 2});
      expect(config.permission, isEmpty);
    });

    test('handles null permission section', () {
      final config = ChatOrAIConfig.fromJson({
        'version': 2,
        'permission': null,
      });
      expect(config.permission, isEmpty);
    });

    test('parses provider section', () {
      final json = {
        'version': 1,
        'permission': {},
        'provider': {
          'custom-openrouter': {
            'name': 'OpenRouter (custom)',
            'options': {
              'baseURL': 'https://openrouter.ai/api/v1',
              'apiKey': '{env:OPENROUTER_API_KEY}',
              'temperature': 0.1,
            },
            'models': {
              'openrouter/owl-alpha': {
                'name': 'Owl Alpha',
                'limit': {'context': 1048576, 'output': 262144},
              },
            },
          },
        },
      };

      final config = ChatOrAIConfig.fromJson(json);
      expect(config.provider, isNotNull);
      final entry = config.provider!.providers['custom-openrouter'];
      expect(entry, isNotNull);
      expect(entry!.name, equals('OpenRouter (custom)'));
      expect(entry.options!.baseURL, equals('https://openrouter.ai/api/v1'));
      expect(entry.options!.apiKey, equals('{env:OPENROUTER_API_KEY}'));
      expect(entry.options!.temperature, equals(0.1));
      final model = entry.models['openrouter/owl-alpha'];
      expect(model, isNotNull);
      expect(model!.name, equals('Owl Alpha'));
      expect(model.limit!.context, equals(1048576));
      expect(model.limit!.output, equals(262144));
    });

    test('provider section absent yields null provider', () {
      final config = ChatOrAIConfig.fromJson({'version': 1, 'permission': {}});
      expect(config.provider, isNull);
    });
  });

  // ── ChatOrAIConfig.toJson ──────────────────────────────────────────────

  group('ChatOrAIConfig.toJson', () {
    test('roundtrip preserves all fields', () {
      final original = ChatOrAIConfig(
        version: 1,
        permission: {
          'shell': const PermissionRuleConfig(defaultAction: 'ask'),
          'edit': const PermissionRuleConfig(
            patternActions: {'*.dart': 'allow'},
          ),
        },
        keybinding: {'session_child_next': 'ctrl+right'},
        skills: const SkillConfig(paths: ['/skills'], urls: []),
        compaction: const CompactionConfig(
          auto: true,
          prune: false,
          buffer: 20000,
        ),
      );

      final json = original.toJson();
      final restored = ChatOrAIConfig.fromJson(json);

      expect(restored.version, equals(original.version));
      expect(restored.permission['shell']?.defaultAction, equals('ask'));
      expect(
        restored.permission['edit']?.patternActions?['*.dart'],
        equals('allow'),
      );
      expect(restored.keybinding?['session_child_next'], equals('ctrl+right'));
      expect(restored.skills?.paths, equals(['/skills']));
      expect(restored.compaction?.auto, isTrue);
    });

    test('omits null fields from toJson', () {
      const config = ChatOrAIConfig(version: 1, permission: {});

      final json = config.toJson();
      expect(json.containsKey('keybinding'), isFalse);
      expect(json.containsKey('skills'), isFalse);
      expect(json.containsKey('compaction'), isFalse);
    });
  });

  // ── CompactionConfig ───────────────────────────────────────────────────

  group('CompactionConfig', () {
    test('default values', () {
      const config = CompactionConfig();
      expect(config.auto, isTrue);
      expect(config.prune, isFalse);
      expect(config.buffer, equals(20000));
    });

    test('fromJson with all fields', () {
      final json = {
        'auto': false,
        'prune': true,
        'keep': {'tokens': 5000},
        'buffer': 15000,
      };

      final config = CompactionConfig.fromJson(json);
      expect(config.auto, isFalse);
      expect(config.prune, isTrue);
      // Legacy `keep.tokens` is accepted for backward compatibility but ignored.
      expect(config.buffer, equals(15000));
    });

    test('fromJson with defaults for missing fields', () {
      final config = CompactionConfig.fromJson({});
      expect(config.auto, isTrue);
      expect(config.prune, isFalse);
      expect(config.buffer, equals(20000));
    });

    test('toJson roundtrip', () {
      const original = CompactionConfig(
        auto: false,
        prune: true,
        buffer: 25000,
      );
      final json = original.toJson();
      final restored = CompactionConfig.fromJson(json);

      expect(restored.auto, equals(original.auto));
      expect(restored.prune, equals(original.prune));
      expect(restored.buffer, equals(original.buffer));
    });

    test('toJson produces correct structure', () {
      const config = CompactionConfig();
      final json = config.toJson();

      expect(json['auto'], isTrue);
      expect(json['prune'], isFalse);
      // Legacy `keep.tokens` is no longer written.
      expect(json.containsKey('keep'), isFalse);
      expect(json['buffer'], equals(20000));
    });
  });

  // ── SkillConfig ────────────────────────────────────────────────────────

  group('SkillConfig', () {
    test('default values', () {
      const config = SkillConfig();
      expect(config.paths, isEmpty);
      expect(config.urls, isEmpty);
    });

    test('fromJson with paths', () {
      final json = {
        'paths': ['/path1', '/path2'],
      };
      final config = SkillConfig.fromJson(json);
      expect(config.paths, equals(['/path1', '/path2']));
      expect(config.urls, isEmpty);
    });

    test('fromJson with URLs as strings', () {
      final json = {
        'urls': ['https://example.com/skill.md'],
      };
      final config = SkillConfig.fromJson(json);
      expect(config.urls, hasLength(1));
      expect(config.urls[0], equals({'url': 'https://example.com/skill.md'}));
    });

    test('fromJson with URLs as objects', () {
      final json = {
        'urls': [
          {'url': 'https://example.com/skill.md', 'name': 'Test Skill'},
        ],
      };
      final config = SkillConfig.fromJson(json);
      expect(config.urls, hasLength(1));
      expect(config.urls[0]['url'], equals('https://example.com/skill.md'));
      expect(config.urls[0]['name'], equals('Test Skill'));
    });

    test('fromJson with non-List paths returns empty paths', () {
      final json = {'paths': 'not a list'};
      final config = SkillConfig.fromJson(json);
      expect(config.paths, isEmpty);
    });

    test('toJson omits empty collections', () {
      const config = SkillConfig();
      final json = config.toJson();
      expect(json.containsKey('paths'), isFalse);
      expect(json.containsKey('urls'), isFalse);
    });

    test('toJson includes non-empty collections', () {
      const config = SkillConfig(
        paths: ['/p1'],
        urls: [
          {'url': 'https://x.com'},
        ],
      );
      final json = config.toJson();
      expect(json['paths'], equals(['/p1']));
      expect(json['urls'], isNotEmpty);
    });
  });

  group('ChatOrAIConfig tools field', () {
    test('parses global tools config with bool values', () {
      final config = ChatOrAIConfig.fromJson(<String, dynamic>{
        'version': 1,
        'tools': {'sequential_thinking__think': false, 'task': true},
      });
      expect(config.tools, isNotNull);
      expect(config.tools!['sequential_thinking__think'], equals(false));
      expect(config.tools!['task'], equals(true));
    });

    test('parses global tools config with string actions', () {
      final config = ChatOrAIConfig.fromJson(<String, dynamic>{
        'version': 1,
        'tools': {'mcp__server_tool': 'deny', 'shell': 'ask'},
      });
      expect(config.tools, isNotNull);
      expect(config.tools!['mcp__server_tool'], equals('deny'));
      expect(config.tools!['shell'], equals('ask'));
    });

    test('roundtrip preserves tools field', () {
      final original = ChatOrAIConfig(
        version: 1,
        permission: const {},
        tools: {'sequential_thinking__think': false, 'task': true},
      );
      final json = original.toJson();
      expect(json['tools'], isNotNull);
      expect(json['tools']['sequential_thinking__think'], equals(false));
      expect(json['tools']['task'], equals(true));

      final restored = ChatOrAIConfig.fromJson(json);
      expect(restored.tools, isNotNull);
      expect(restored.tools!['sequential_thinking__think'], equals(false));
      expect(restored.tools!['task'], equals(true));
    });

    test('omits tools field when null', () {
      const config = ChatOrAIConfig(version: 1, permission: {});
      final json = config.toJson();
      expect(json.containsKey('tools'), isFalse);
    });
  });
}
