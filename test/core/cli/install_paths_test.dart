import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/cli/install_paths.dart';

void main() {
  group('InstallPaths', () {
    test('linux paths resolve to expected locations', () {
      if (!Platform.isLinux) return;
      expect(
        InstallPaths.installDir,
        '${Platform.environment['HOME']}/.local/share/chatorai',
      );
      expect(
        InstallPaths.launcherPath,
        '${Platform.environment['HOME']}/.local/bin/chatorai',
      );
      expect(
        InstallPaths.desktopEntryPath,
        '${Platform.environment['HOME']}/.local/share/applications/chatorai.desktop',
      );
      expect(
        InstallPaths.iconPath,
        '${Platform.environment['HOME']}/.local/share/icons/hicolor/256x256/apps/chatorai.png',
      );
    });

    test('windows-only getters throw on non-windows', () {
      if (Platform.isWindows) return;
      expect(() => InstallPaths.startMenuShortcut, throwsUnsupportedError);
      expect(() => InstallPaths.desktopShortcut, throwsUnsupportedError);
      expect(() => InstallPaths.uninstallerScript, throwsUnsupportedError);
    });

    test('macos/linux desktop entry throws on windows', () {
      if (!Platform.isWindows) return;
      expect(() => InstallPaths.desktopEntryPath, throwsUnsupportedError);
      expect(() => InstallPaths.iconPath, throwsUnsupportedError);
    });
  });
}
