import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/config/config_manager.dart';

void main() {
  group('ConfigLoader', () {
    test('returns {} when no config file exists', () async {
      // Ensure no chatorai.json in cwd or XDG config dir
      // This test relies on the CI/testing environment not having these files
      final raw = await ConfigLoader.load();
      // Should be either '{}' or valid JSON from an existing config
      final parsed = json.decode(raw);
      expect(parsed, isA<Map>());
    });

    test('ConfigNotFound is a ConfigError', () {
      const error = ConfigNotFound();
      expect(error, isA<ConfigError>());
      expect(error, isA<Exception>());
    });

    test('ConfigReadError has path and original', () {
      const error = ConfigReadError(path: '/test/path', original: 'IO error');
      expect(error.path, equals('/test/path'));
      expect(error.original, equals('IO error'));
      expect(error.toString(), contains('/test/path'));
      expect(error.toString(), contains('IO error'));
    });

    test('ConfigValidationError has message', () {
      const error = ConfigValidationError('bad config');
      expect(error.message, equals('bad config'));
      expect(error.toString(), contains('bad config'));
    });
  });

  group('ConfigManager', () {
    test(
      'loadConfig returns config with defaults when no file exists',
      () async {
        // This loads the actual config, which may or may not exist.
        // The important thing is that it doesn't throw.
        final config = await ConfigManager.loadConfig();
        expect(config.version, greaterThanOrEqualTo(0));
      },
    );

    test(
      'loadConfig throws ConfigValidationError for invalid action',
      () async {
        // Write a temporary chatorai.json with a bad permission action
        final projectConfig = File('.chatorai/chatorai.json');
        final dir = Directory('.chatorai');

        String? originalContent;
        bool dirExisted = await dir.exists();

        try {
          if (!dirExisted) {
            await dir.create(recursive: true);
          }
          originalContent = await projectConfig.exists()
              ? await projectConfig.readAsString()
              : null;

          await projectConfig.writeAsString(
            json.encode({
              'version': 1,
              'permission': {'bash': 'alloww'}, // typo
            }),
          );

          await expectLater(
            ConfigManager.loadConfig(),
            throwsA(isA<ConfigValidationError>()),
          );
        } finally {
          if (originalContent != null) {
            await projectConfig.writeAsString(originalContent);
          } else if (await projectConfig.exists()) {
            await projectConfig.delete();
          }
          if (!dirExisted && await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'loadConfig throws ConfigValidationError for malformed JSON',
      () async {
        final projectConfig = File('.chatorai/chatorai.json');
        final dir = Directory('.chatorai');

        String? originalContent;
        bool dirExisted = await dir.exists();

        try {
          if (!dirExisted) {
            await dir.create(recursive: true);
          }
          originalContent = await projectConfig.exists()
              ? await projectConfig.readAsString()
              : null;

          await projectConfig.writeAsString('not valid json {{{');

          await expectLater(
            ConfigManager.loadConfig(),
            throwsA(isA<ConfigValidationError>()),
          );
        } finally {
          if (originalContent != null) {
            await projectConfig.writeAsString(originalContent);
          } else if (await projectConfig.exists()) {
            await projectConfig.delete();
          }
          if (!dirExisted && await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'loadConfig throws ConfigValidationError for invalid nested permission',
      () async {
        final projectConfig = File('.chatorai/chatorai.json');
        final dir = Directory('.chatorai');

        String? originalContent;
        bool dirExisted = await dir.exists();

        try {
          if (!dirExisted) {
            await dir.create(recursive: true);
          }
          originalContent = await projectConfig.exists()
              ? await projectConfig.readAsString()
              : null;

          await projectConfig.writeAsString(
            json.encode({
              'version': 1,
              'permission': {
                'bash': {'*': 'invalid_action'},
              },
            }),
          );

          await expectLater(
            ConfigManager.loadConfig(),
            throwsA(isA<ConfigValidationError>()),
          );
        } finally {
          if (originalContent != null) {
            await projectConfig.writeAsString(originalContent);
          } else if (await projectConfig.exists()) {
            await projectConfig.delete();
          }
          if (!dirExisted && await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'loadConfig throws ConfigValidationError for non-string action in nested perm',
      () async {
        final projectConfig = File('.chatorai/chatorai.json');
        final dir = Directory('.chatorai');

        String? originalContent;
        bool dirExisted = await dir.exists();

        try {
          if (!dirExisted) {
            await dir.create(recursive: true);
          }
          originalContent = await projectConfig.exists()
              ? await projectConfig.readAsString()
              : null;

          await projectConfig.writeAsString(
            json.encode({
              'version': 1,
              'permission': {
                'bash': {'*': 42}, // not a string
              },
            }),
          );

          await expectLater(
            ConfigManager.loadConfig(),
            throwsA(isA<ConfigValidationError>()),
          );
        } finally {
          if (originalContent != null) {
            await projectConfig.writeAsString(originalContent);
          } else if (await projectConfig.exists()) {
            await projectConfig.delete();
          }
          if (!dirExisted && await dir.exists()) {
            await dir.delete(recursive: true);
          }
        }
      },
    );
  });
}
