import 'dart:async';
import 'dart:io';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Platform-aware application paths following each OS convention.
///
/// Directory name is resolved from `pubspec.yaml` of the current working
/// directory when [init] is called.  Falls back to `chatorai` when the file
/// is not present (e.g. globally installed CLI binary).
class XdgPaths {
  XdgPaths._();

  static String? _appDirName;
  static Completer<void>? _initCompleter;

  // ---------------------------------------------------------------------------
  // Platform detection
  // ---------------------------------------------------------------------------

  static bool get _isLinux => Platform.isLinux;
  static bool get _isMacOS => Platform.isMacOS;
  static bool get _isWindows => Platform.isWindows;
  static bool get _isAndroid => Platform.isAndroid;
  static bool get _isIOS => Platform.isIOS;
  static bool get _isMobile => _isAndroid || _isIOS;

  // ---------------------------------------------------------------------------
  // Cached mobile paths (populated by init())
  // ---------------------------------------------------------------------------

  static String? _cachedDataDir;
  static String? _cachedCacheDir;
  static String? _cachedConfigDir;

  /// Fallback error thrown when mobile paths are accessed before init().
  static String get _fallbackMobileError =>
      'XdgPaths.init() must be called before accessing paths on mobile';

  /// Initialise from `pubspec.yaml` in the current working directory.
  ///
  /// Safe to call multiple times — only the first invocation performs work.
  /// On mobile (Android/iOS), caches platform-specific paths from path_provider.
  static Future<void> init() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    try {
      _appDirName = _resolveAppDirName();
      if (_isMobile) {
        final docs = getApplicationDocumentsDirectory();
        final temp = getTemporaryDirectory();
        final support = getApplicationSupportDirectory();
        _cachedDataDir = (await docs).path;
        _cachedCacheDir = (await temp).path;
        _cachedConfigDir = (await support).path;
      }
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      rethrow;
    }
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
    } catch (_) {
      // ignore and use fallback below
    }
    return 'chatorai';
  }

  /// Cached app directory name, or null when [init] has not been called yet.
  static String get _dirName {
    if (_appDirName == null) {
      LogTags.storage.logWarning(
        '[XdgPaths] init() not called — using fallback directory name',
      );
      return 'chatorai';
    }
    return _appDirName!;
  }

  /// Resolved home directory (desktop only — mobile uses cached paths).
  static String get home =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      (_isMobile ? '' : '/tmp');

  // ---------------------------------------------------------------------------
  // Base directories
  // ---------------------------------------------------------------------------

  /// Persistent application data.
  ///
  /// Tool outputs, session database.
  static String get dataHome {
    if (_isMobile) {
      final cached = _cachedDataDir;
      if (cached == null) {
        throw UnsupportedError(_fallbackMobileError);
      }
      return p.join(cached, _dirName);
    }
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
    if (_isMobile) {
      final cached = _cachedConfigDir;
      if (cached == null) {
        throw UnsupportedError(_fallbackMobileError);
      }
      return p.join(cached, _dirName);
    }
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
    if (_isMobile) {
      final cached = _cachedCacheDir;
      if (cached == null) {
        throw UnsupportedError(_fallbackMobileError);
      }
      return p.join(cached, _dirName);
    }
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
    if (_isMobile) {
      // On mobile, state goes under data directory
      final cached = _cachedDataDir;
      if (cached == null) {
        throw UnsupportedError(_fallbackMobileError);
      }
      return p.join(cached, _dirName, 'state');
    }
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
  // Async alternatives (desktop only — no mobile Flutter runtime needed)
  // ---------------------------------------------------------------------------

  static Future<String> get dataHomeAsync async => dataHome;

  static Future<String> get configHomeAsync async => configHome;

  static Future<String> get cacheHomeAsync async => cacheHome;

  static Future<String> get stateHomeAsync async => stateHome;

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

  /// Get or create a subdirectory under [dataHomeAsync].
  static Future<Directory> dataSubdirAsync(String name) async =>
      ensureDir(p.join(await dataHomeAsync, name));

  /// Get or create a subdirectory under [cacheHome].
  static Future<Directory> cacheSubdir(String name) =>
      ensureDir(p.join(cacheHome, name));

  /// Get or create a subdirectory under [cacheHomeAsync].
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
