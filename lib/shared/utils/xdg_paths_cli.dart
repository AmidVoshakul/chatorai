import 'dart:io';
import 'package:path/path.dart' as p;

/// Desktop-only application paths for CLI use.
///
/// Does NOT depend on `path_provider` (Flutter plugin) — safe for `dart run`.
class XdgPaths {
  XdgPaths._();

  static String? _appDirName;

  static bool get _isLinux => Platform.isLinux;
  static bool get _isMacOS => Platform.isMacOS;
  static bool get _isWindows => Platform.isWindows;

  /// Initialise from `pubspec.yaml` in the current working directory.
  static void init() {
    if (_appDirName != null) return;
    _appDirName = _resolveAppDirName();
  }

  static String _resolveAppDirName() {
    try {
      final pubspec = File('pubspec.yaml');
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        final match = RegExp(
          r'^name:\s*(.+)$',
          multiLine: true,
        ).firstMatch(content);
        if (match != null) {
          final raw = match
              .group(1)!
              .trim()
              .replaceAll("'", '')
              .replaceAll('"', '');
          if (raw.isNotEmpty) return raw;
        }
      }
    } catch (_) {}
    return 'chatorai';
  }

  static String get _dirName {
    if (_appDirName == null) return 'chatorai';
    return _appDirName!;
  }

  static String get home =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '/tmp';

  /// Persistent application data (tool outputs, session database).
  static String get dataHome {
    if (_isLinux) {
      final base =
          Platform.environment['XDG_DATA_HOME'] ??
          p.join(home, '.local', 'share');
      return p.join(base, _dirName);
    }
    if (_isMacOS) {
      return p.join(home, 'Library', 'Application Support', _dirName);
    }
    if (_isWindows) {
      final appData =
          Platform.environment['APPDATA'] ?? p.join(home, 'AppData', 'Roaming');
      return p.join(appData, _dirName);
    }
    return p.join(home, '.local', 'share', _dirName);
  }

  /// Configuration files (chatorai.json, skills, agents).
  static String get configHome {
    if (_isLinux) {
      final base =
          Platform.environment['XDG_CONFIG_HOME'] ?? p.join(home, '.config');
      return p.join(base, _dirName);
    }
    if (_isMacOS) {
      return p.join(home, 'Library', 'Application Support', _dirName);
    }
    if (_isWindows) {
      final appData =
          Platform.environment['APPDATA'] ?? p.join(home, 'AppData', 'Roaming');
      return p.join(appData, _dirName, 'config');
    }
    return p.join(home, '.config', _dirName);
  }

  /// Non-essential cached data (model lists, cache).
  static String get cacheHome {
    if (_isLinux) {
      final base =
          Platform.environment['XDG_CACHE_HOME'] ?? p.join(home, '.cache');
      return p.join(base, _dirName);
    }
    if (_isMacOS) {
      return p.join(home, 'Library', 'Caches', _dirName);
    }
    if (_isWindows) {
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ??
          p.join(home, 'AppData', 'Local');
      return p.join(localAppData, _dirName, 'cache');
    }
    return p.join(home, '.cache', _dirName);
  }

  /// Persistent runtime state.
  static String get stateHome {
    if (_isLinux) {
      final base =
          Platform.environment['XDG_STATE_HOME'] ??
          p.join(home, '.local', 'state');
      return p.join(base, _dirName);
    }
    if (_isMacOS) {
      return p.join(home, 'Library', 'Application Support', _dirName);
    }
    if (_isWindows) {
      final appData =
          Platform.environment['APPDATA'] ?? p.join(home, 'AppData', 'Roaming');
      return p.join(appData, _dirName, 'state');
    }
    return p.join(home, '.local', 'state', _dirName);
  }

  /// Directory used by the `shared_preferences` package for `shared_preferences.json`.
  ///
  /// Mirrors `path_provider.getApplicationSupportPath()`, which resolves to
  /// `<base>/<APPLICATION_ID>`. On Linux `APPLICATION_ID` is `com.chatorai.app`
  /// (from `linux/CMakeLists.txt`), so this matches the real location
  /// `<XDG_DATA_HOME>/com.chatorai.app`. Note this is a SIBLING of [dataHome]
  /// (which uses the pubspec `name`), not a child of it.
  ///
  /// On macOS/Windows the OS bundle identifier differs (e.g. macOS uses
  /// `com.ChatORAI.chat.ChatORAIChatAi`), so this constant is Linux-accurate.
  /// The CLI `uninstall` is Linux-first (per-user install), so this is the
  /// primary target; macOS/Windows preferences are best removed by the OS
  /// uninstaller. Keep this in sync with the Linux `APPLICATION_ID`.
  static const String prefsAppId = 'com.chatorai.app';

  static String get prefsHome {
    if (_isLinux) {
      final base =
          Platform.environment['XDG_DATA_HOME'] ??
          p.join(home, '.local', 'share');
      return p.join(base, prefsAppId);
    }
    if (_isMacOS) {
      return p.join(home, 'Library', 'Application Support', prefsAppId);
    }
    if (_isWindows) {
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ??
          p.join(home, 'AppData', 'Local');
      return p.join(localAppData, prefsAppId);
    }
    return p.join(home, '.local', 'share', prefsAppId);
  }

  // ---------------------------------------------------------------------------
  // Async wrappers (desktop — synchronous under the hood)
  // ---------------------------------------------------------------------------

  static Future<String> get dataHomeAsync async => dataHome;

  static Future<String> get configHomeAsync async => configHome;

  static Future<String> get cacheHomeAsync async => cacheHome;

  /// Ensure [path] exists as a directory (creates recursively if needed).
  static Future<Directory> ensureDir(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Resolve `~` to the user's home directory.
  static String expandHome(String pattern) {
    if (pattern == '~') return home;
    String resolved;
    if (pattern.startsWith('~/')) {
      resolved = '$home${pattern.substring(1)}';
    } else if (pattern.startsWith(r'$HOME/')) {
      resolved = '$home${pattern.substring(6)}';
    } else if (pattern.startsWith(r'$HOME')) {
      resolved = '$home${pattern.substring(5)}';
    } else {
      return pattern;
    }
    final normalized = p.normalize(resolved);
    if (!normalized.startsWith(p.normalize(home))) {
      return pattern;
    }
    return normalized;
  }
}
