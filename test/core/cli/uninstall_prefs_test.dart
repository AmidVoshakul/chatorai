import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/cli/cli_commands.dart';
import 'package:chatorai/shared/utils/xdg_paths_cli.dart' as xdg;

void main() {
  group('uninstall preferences dir', () {
    test(
      'resolves to the shared_preferences directory (sibling of dataHome)',
      () {
        if (!Platform.isLinux) return;
        final expected = '${xdg.XdgPaths.dataHome}/../com.chatorai.app';
        expect(uninstallPreferencesDir, p.normalize(expected));
      },
    );

    test('is distinct from the session DB data dir', () {
      if (!Platform.isLinux) return;
      expect(uninstallPreferencesDir, isNot(xdg.XdgPaths.dataHome));
    });

    test('points at the real shared_preferences.json location', () {
      if (!Platform.isLinux) return;
      final file = '${uninstallPreferencesDir}/shared_preferences.json';
      // Build the expected path from the same base the app uses.
      final base =
          Platform.environment['XDG_DATA_HOME'] ??
          p.join(Platform.environment['HOME']!, '.local', 'share');
      expect(file, p.join(base, 'com.chatorai.app', 'shared_preferences.json'));
    });
  });
}
