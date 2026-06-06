import 'dart:convert';
import 'dart:io';

import 'package:chatorai/config/config_loader.dart';
import 'package:chatorai/config/config_manager.dart';
import 'package:chatorai/config/models/chatorai_config.dart';
import 'package:chatorai/config/models/permission_section.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader', () {
    test('returns default config when no file exists', () async {
      final raw = await ConfigLoader.load();
      expect(raw, '{}');
    });

    test('throws when JSON is malformed', () async {
      expect(
        () => json.decode('not valid json {{{'),
        throwsA(isA<FormatException>()),
      );
    });

    test('valid config parses correctly', () async {
      final data = {
        'version': 1,
        'permission': {'bash': 'ask'},
        'provider': {
          'openrouter': {'apiKey': 'test'},
        },
      };

      final config = ChatOrAIConfig.fromJson(data);
      expect(config.version, 1);
      expect(config.permission['bash']?.defaultAction, 'ask');
      expect(config.provider?['openrouter'], isNotNull);
    });

    test('permission section roundtrip', () {
      final original = ChatOrAIConfig(
        version: 1,
        permission: {
          'bash': const PermissionRuleConfig(defaultAction: 'ask'),
          'web_fetch': const PermissionRuleConfig(
            patternActions: {'*.example.com': 'allow', '*': 'ask'},
          ),
        },
        provider: null,
        keybinding: null,
      );

      final json = original.toJson();
      final restored = ChatOrAIConfig.fromJson(json);

      expect(restored.version, original.version);
      expect(restored.permission['bash']?.defaultAction, 'ask');
      expect(
        restored.permission['web_fetch']?.patternActions?['*.example.com'],
        'allow',
      );
      expect(restored.permission['web_fetch']?.patternActions?['*'], 'ask');
    });

    test('schema validation catches bad enum value', () async {
      print('Current dir: ${Directory.current.path}');
      final projectConfig = File('chatorai.json');
      print('Project config exists: ${await projectConfig.exists()}');

      final originalContent = await projectConfig.exists()
          ? await projectConfig.readAsString()
          : null;
      print('Original content: $originalContent');

      try {
        await projectConfig.writeAsString(
          json.encode({
            'version': 1,
            'permission': {'bash': 'alloww'}, // typo: should be "allow"
          }),
        );
        print('Wrote bad config');
        print('File exists after write: ${await projectConfig.exists()}');
        print('File content: ${await projectConfig.readAsString()}');

        await expectLater(
          ConfigManager.loadConfig(),
          throwsA(isA<ConfigValidationError>()),
        );
      } finally {
        if (originalContent != null) {
          await projectConfig.writeAsString(originalContent);
        } else {
          await projectConfig.delete();
        }
      }
    });
  });
}
