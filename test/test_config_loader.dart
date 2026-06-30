import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/config/config_manager.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/config/models/permission_section.dart';
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
        'keybinding': {'session_child_next': 'ctrl+right'},
      };

      final config = ChatOrAIConfig.fromJson(data);
      expect(config.version, 1);
      expect(config.permission['bash']?.defaultAction, 'ask');
      expect(config.keybinding?['session_child_next'], 'ctrl+right');
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
      final configDir = Directory('.chatorai');
      if (!await configDir.exists()) {
        await configDir.create();
      }

      final projectConfig = File('.chatorai/chatorai.json');
      final originalContent = await projectConfig.exists()
          ? await projectConfig.readAsString()
          : null;

      try {
        await projectConfig.writeAsString(
          json.encode({
            'version': 1,
            'permission': {'bash': 'alloww'}, // typo: should be "allow"
          }),
        );

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
