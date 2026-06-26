import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks file mtime for read-before-edit guards.
///
/// When a tool reads a file, it records the file's last-modified epoch ms.
/// Before a write/edit, the guard compares the recorded mtime against the
/// current on-disk mtime. If they differ, the file was modified externally
/// (IDE, VCS checkout, another agent) and the caller should re-read first.
///
/// Storage backend: SharedPreferences (already required by the app). Keys are
/// namespaced under `_edit_guard_prefix` to avoid collisions.
class FileEditGuard {
  static const _prefix = '_edit_guard_';
  static SharedPreferences? _prefs;

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Record the current mtime of [path] after a successful read.
  static Future<void> recordRead(String path) async {
    try {
      await _ensurePrefs();
      final stat = await File(path).stat();
      await _prefs!.setInt(
        '$_prefix$path',
        stat.modified.millisecondsSinceEpoch,
      );
    } catch (_) {
      // Non-fatal: if we can't record, next edit just skips the guard.
    }
  }

  /// Get the last-recorded mtime for [path], or null if never read.
  static Future<int?> getLastReadMtime(String path) async {
    await _ensurePrefs();
    return _prefs!.getInt('$_prefix$path');
  }

  /// Check whether [path] was modified since the last [recordRead] call.
  ///
  /// Returns `null` if no prior read was recorded (first-time access, OK).
  /// Returns the current on-disk mtime if a mismatch is detected.
  static Future<int?> checkStale(String path) async {
    try {
      final cached = await getLastReadMtime(path);
      if (cached == null) {
        return null; // no prior read — not stale by definition
      }
      final stat = await File(path).stat();
      final current = stat.modified.millisecondsSinceEpoch;
      if (current != cached) return current;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clear all cached mtimes (e.g. on session close).
  static Future<void> clearAll() async {
    await _ensurePrefs();
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
}
