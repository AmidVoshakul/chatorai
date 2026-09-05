import 'dart:io';

import 'package:path/path.dart' as p;

/// Platform-aware installation paths for uninstall/upgrade operations.
///
/// Installs into per-user directories (no administrator/sudo required),
/// which keeps the app isolated from the system and lets `uninstall` run
/// without elevation.
class InstallPaths {
  InstallPaths._();

  /// Directory where the application bundle lives.
  static String get installDir {
    if (Platform.isLinux) {
      return p.join(_home, '.local', 'share', 'chatorai');
    }
    if (Platform.isMacOS) return p.join(_home, 'Applications', 'ChatORAI.app');
    if (Platform.isWindows) {
      return p.join(_localAppData, 'ChatORAI');
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Launcher / executable path (on PATH for terminal use).
  static String get launcherPath {
    if (Platform.isLinux) return p.join(_home, '.local', 'bin', 'chatorai');
    if (Platform.isMacOS) {
      return p.join(
        _home,
        'Applications',
        'ChatORAI.app',
        'Contents',
        'MacOS',
        'chatorai',
      );
    }
    if (Platform.isWindows) {
      return p.join(_localAppData, 'ChatORAI', 'chatorai.exe');
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Desktop entry path (user-level, Linux).
  static String get desktopEntryPath {
    if (Platform.isLinux) {
      return p.join(
        _home,
        '.local',
        'share',
        'applications',
        'chatorai.desktop',
      );
    }
    throw UnsupportedError('Desktop entries only on Linux');
  }

  /// Icon path (user-level, Linux).
  static String get iconPath {
    if (Platform.isLinux) {
      return p.join(
        _home,
        '.local',
        'share',
        'icons',
        'hicolor',
        '256x256',
        'apps',
        'chatorai.png',
      );
    }
    throw UnsupportedError('Icons only on Linux');
  }

  /// Start Menu shortcut path (Windows).
  static String get startMenuShortcut {
    if (Platform.isWindows) {
      return p.join(
        _appData,
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
        'ChatORAI.lnk',
      );
    }
    throw UnsupportedError('Shortcuts only on Windows');
  }

  /// Desktop shortcut path (Windows).
  static String get desktopShortcut {
    if (Platform.isWindows) {
      return p.join(_userProfile, 'Desktop', 'ChatORAI.lnk');
    }
    throw UnsupportedError('Shortcuts only on Windows');
  }

  /// Built-in uninstaller script path (Windows).
  static String get uninstallerScript {
    if (Platform.isWindows) {
      return p.join(_localAppData, 'ChatORAI', 'Uninstall-ChatORAI.ps1');
    }
    throw UnsupportedError('Uninstaller script only on Windows');
  }

  static String get _home =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';

  static String get _userProfile =>
      Platform.environment['USERPROFILE'] ?? _home;

  static String get _appData =>
      Platform.environment['APPDATA'] ??
      p.join(_userProfile, 'AppData', 'Roaming');

  static String get _localAppData =>
      Platform.environment['LOCALAPPDATA'] ??
      p.join(_userProfile, 'AppData', 'Local');
}
