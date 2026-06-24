import 'dart:async';
import 'dart:io';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Platform-aware application paths following each OS convention.
///
/// ### Directory name
///
/// The directory name is resolved dynamically from the application's package
/// name (bundle ID) via [PackageInfo] at runtime — never hardcoded.  Call
/// [init] once at startup (e.g. in `main()`) before accessing any getter.
///
/// ### Path layout
///
/// **Linux** — XDG Base Directory Specification:
///   Data   → `$XDG_DATA_HOME/package`          (default: `~/.local/share/package`)
///   Config → `$XDG_CONFIG_HOME/package`        (default: `~/.config/package`)
///   Cache  → `$XDG_CACHE_HOME/package`         (default: `~/.cache/package`)
///   State  → `$XDG_STATE_HOME/package`         (default: `~/.local/state/package`)
///
/// **macOS** — Apple convention:
///   Data   → `~/Library/Application Support/package`
///   Config → `~/Library/Application Support/package`
///   Cache  → `~/Library/Caches/package`
///   State  → `~/Library/Application Support/package`
///
/// **Windows** — MS convention:
///   Data   → `%APPDATA%\package`
///   Config → `%APPDATA%\package\config`
///   Cache  → `%LOCALAPPDATA%\package\cache`
///   State  → `%APPDATA%\package\state`
///
/// **Mobile** (Android / iOS) — entirely sandboxed via [path_provider]:
///   Data   → `[ApplicationSupportDirectory]/package`
///   Cache  → `[TemporaryDirectory]/package/cache`
class XdgPaths {
  XdgPaths._();

  static String? _appDirName;
  static Completer<void>? _initCompleter;

  /// Initialise the cached package-name directory.
  ///
  /// Must be called once at application startup (e.g. in `main()`) **before**
  /// any sync getter is accessed.  Safe to call multiple times — only the
  /// first invocation performs work.
  static Future<void> init() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    try {
      final info = await PackageInfo.fromPlatform();
      final name = info.packageName;
      if (name.isEmpty ||
          name.contains('/') ||
          name.contains('\\') ||
          name.contains('..')) {
        throw StateError('Invalid package name from PackageInfo: $name');
      }
      _appDirName = name;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    }
  }

  /// The resolved application directory name.
  ///
  /// Returns the package name (e.g. `com.chatorai.app`) if [init] has been
  /// called, otherwise falls back to `chatorai` so that early-bootstrap code
  /// and tests don't crash.
  static String get _dirName {
    if (_appDirName == null) {
      LogTags.storage.logWarning(
        '[XdgPaths] init() not called — using fallback directory name',
      );
      return 'chatorai';
    }
    return _appDirName!;
  }

  /// Resolved home directory.
  static String get home =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '/tmp';

  // ---------------------------------------------------------------------------
  // Platform detection
  // ---------------------------------------------------------------------------

  static bool get _isLinux => Platform.isLinux;
  static bool get _isMacOS => Platform.isMacOS;
  static bool get _isWindows => Platform.isWindows;

  // ---------------------------------------------------------------------------
  // Base directories
  // ---------------------------------------------------------------------------

  /// Persistent application data.
  ///
  /// Tool outputs, session database.
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

  /// Configuration files.
  ///
  /// chatorai.json, global skills, agents, commands.
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

  /// Non-essential cached data.
  ///
  /// Model lists, URL-skill cache.
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

  /// Persistent runtime state (non-essential, safe to discard).
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

  // ---------------------------------------------------------------------------
  // Async alternatives (all platforms including mobile)
  // ---------------------------------------------------------------------------

  /// [dataHome] — works on all platforms.
  /// On mobile uses [getApplicationSupportDirectory] (sandboxed app data).
  static Future<String> get dataHomeAsync async {
    if (_isMobile) {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
    return dataHome;
  }

  /// [configHome] — works on all platforms.
  /// On mobile, config shares the same sandboxed directory as data
  /// ([getApplicationSupportDirectory]) — mobile OS does not distinguish
  /// between separate data and config home directories.
  static Future<String> get configHomeAsync async {
    if (_isMobile) {
      final dir = await getApplicationSupportDirectory();
      return dir.path;
    }
    return configHome;
  }

  /// [cacheHome] — works on all platforms.
  /// On mobile uses [getTemporaryDirectory].
  static Future<String> get cacheHomeAsync async {
    if (_isMobile) {
      final dir = await getTemporaryDirectory();
      return p.join(dir.path, _dirName, 'cache');
    }
    return cacheHome;
  }

  /// [stateHome] — works on all platforms.
  /// On mobile reuses [dataHomeAsync].
  static Future<String> get stateHomeAsync async {
    if (_isMobile) {
      final dir = await getApplicationSupportDirectory();
      return p.join(dir.path, _dirName, 'state');
    }
    return stateHome;
  }

  static bool get _isMobile => !(_isLinux || _isMacOS || _isWindows);

  /// Ensure [path] exists as a directory (creates recursively if needed).
  static Future<Directory> ensureDir(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Directory ensureDirSync(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Get or create a subdirectory under [dataHome].
  static Future<Directory> dataSubdir(String name) =>
      ensureDir(p.join(dataHome, name));

  static Directory dataSubdirSync(String name) =>
      ensureDirSync(p.join(dataHome, name));

  /// Get or create a subdirectory under [dataHomeAsync] (all platforms).
  static Future<Directory> dataSubdirAsync(String name) async =>
      ensureDir(p.join(await dataHomeAsync, name));

  /// Get or create a subdirectory under [cacheHome].
  static Future<Directory> cacheSubdir(String name) =>
      ensureDir(p.join(cacheHome, name));

  /// Get or create a subdirectory under [cacheHomeAsync] (all platforms).
  static Future<Directory> cacheSubdirAsync(String name) async =>
      ensureDir(p.join(await cacheHomeAsync, name));

  // ---------------------------------------------------------------------------
  // Home expansion (for permission patterns etc.)
  // ---------------------------------------------------------------------------

  /// Expand `~`, `~/`, `$HOME/`, `$HOME` to the user's home directory.
  ///
  /// The resulting path is normalized and must remain inside the user's
  /// home directory.  Returns the original pattern if the expansion would
  /// escape (e.g. `~/../etc/passwd`), so callers can detect the rejection.
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
