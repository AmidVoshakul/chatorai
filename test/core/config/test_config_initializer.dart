import 'dart:io';

import 'package:chatorai/core/config/config_initializer.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ConfigInitializer', () {
    test('ensureGlobalConfig creates file when missing', () async {
      final projectConfig = File('.chatorai/chatorai.json');
      final globalConfig = File(p.join(XdgPaths.configHome, 'chatorai.json'));

      String? originalProjectContent;
      String? originalGlobalContent;
      final projectExisted = await projectConfig.exists();
      final globalExisted = await globalConfig.exists();

      if (projectExisted) {
        originalProjectContent = await projectConfig.readAsString();
      }
      if (globalExisted) {
        originalGlobalContent = await globalConfig.readAsString();
      }

      try {
        if (projectExisted) await projectConfig.delete();
        if (globalExisted) await globalConfig.delete();

        await ConfigInitializer.ensureGlobalConfig();

        expect(await globalConfig.exists(), true);
        final content = await globalConfig.readAsString();
        expect(content, contains('"version": 1'));
        // Scaffold must expose every schema section as an empty placeholder
        // so users can see what is configurable.
        for (final section in [
          '"permission"',
          '"compaction"',
          '"skills"',
          '"mcp"',
          '"agent"',
          '"formatter"',
          '"tools"',
          '"instructions"',
        ]) {
          expect(
            content,
            contains(section),
            reason: 'scaffold should include $section',
          );
        }
        // mcp must use the flat layout (no "servers" wrapper).
        expect(content, isNot(contains('"servers"')));
      } finally {
        if (originalProjectContent != null) {
          await projectConfig.writeAsString(originalProjectContent);
        } else if (projectExisted) {
          await projectConfig.delete();
        }
        if (originalGlobalContent != null) {
          await globalConfig.writeAsString(originalGlobalContent);
        } else if (globalExisted) {
          await globalConfig.delete();
        }
      }
    });

    test('ensureGlobalConfig does not overwrite existing file', () async {
      final projectConfig = File('.chatorai/chatorai.json');
      final globalConfig = File(p.join(XdgPaths.configHome, 'chatorai.json'));

      const customContent = '{"version": 1, "permission": {"test": "allow"}}';

      String? originalProjectContent;
      final projectExisted = await projectConfig.exists();
      if (projectExisted) {
        originalProjectContent = await projectConfig.readAsString();
      }

      try {
        if (projectExisted) await projectConfig.delete();

        await XdgPaths.ensureDir(XdgPaths.configHome);
        await globalConfig.writeAsString(customContent);

        await ConfigInitializer.ensureGlobalConfig();

        final content = await globalConfig.readAsString();
        expect(content, equals(customContent));
      } finally {
        if (await globalConfig.exists()) {
          await globalConfig.delete();
        }
        if (originalProjectContent != null) {
          await projectConfig.writeAsString(originalProjectContent);
        } else if (projectExisted) {
          await projectConfig.delete();
        }
      }
    });
  });
}
