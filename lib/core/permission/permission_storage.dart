import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PermissionStorage {
  Future<Map<String, String>> loadAlways(String workspacePath);
  Future<void> saveAlways(String workspacePath, Map<String, String> always);
  Future<void> clearAlways(String workspacePath);
}

class NoopPermissionStorage implements PermissionStorage {
  const NoopPermissionStorage();

  @override
  Future<Map<String, String>> loadAlways(String workspacePath) async => {};

  @override
  Future<void> saveAlways(
    String workspacePath,
    Map<String, String> always,
  ) async {}

  @override
  Future<void> clearAlways(String workspacePath) async {}
}

class SharedPrefsPermissionStorage implements PermissionStorage {
  static String _key(String workspacePath) =>
      'permission_always_${base64Url.encode(utf8.encode(workspacePath))}';

  static String _oldKey(String workspacePath) =>
      'permission_always_${workspacePath.hashCode}';

  SharedPreferences? _prefs;

  SharedPrefsPermissionStorage([SharedPreferences? prefs]) : _prefs = prefs;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<Map<String, String>> loadAlways(String workspacePath) async {
    final prefs = await _prefsInstance;
    final newKey = _key(workspacePath);
    final raw = prefs.getString(newKey);
    if (raw != null) {
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        return Map<String, String>.from(decoded);
      } on FormatException {
        return {};
      }
    }
    // Migration: try old hashCode-based key and migrate to new stable key
    final oldKey = _oldKey(workspacePath);
    final oldRaw = prefs.getString(oldKey);
    if (oldRaw != null) {
      try {
        final decoded = json.decode(oldRaw) as Map<String, dynamic>;
        final migrated = Map<String, String>.from(decoded);
        await prefs.setString(newKey, oldRaw);
        await prefs.remove(oldKey);
        return migrated;
      } on FormatException {
        return {};
      }
    }
    return {};
  }

  @override
  Future<void> saveAlways(
    String workspacePath,
    Map<String, String> always,
  ) async {
    final prefs = await _prefsInstance;
    await prefs.setString(_key(workspacePath), json.encode(always));
  }

  @override
  Future<void> clearAlways(String workspacePath) async {
    final prefs = await _prefsInstance;
    await prefs.remove(_key(workspacePath));
  }
}
