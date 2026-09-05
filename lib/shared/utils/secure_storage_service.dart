import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secret_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static SecretStorageFactory? _factory;
  static bool _initializing = false;

  static Future<void> init({bool forcePrefs = false}) async {
    if (_factory != null || _initializing) return;
    _initializing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _factory = await SecretStorageFactory.create(
        keyring: _storage,
        prefs: prefs,
        forcePrefs: forcePrefs,
      );
    } finally {
      _initializing = false;
    }
  }

  static Future<SecretStorageFactory> get _resolved async {
    final ready = _factory;
    if (ready != null) return ready;
    await init();
    final after = _factory;
    if (after == null) {
      // Fail with a diagnosable message instead of a bare null-check error.
      throw StateError(
        'SecureStorageService.init() completed without creating a storage '
        'factory — secret reads are impossible in this state.',
      );
    }
    return after;
  }

  static Future<bool> get usingFallback async =>
      (await _resolved).usingFallback;

  Future<void> write({required String key, required String value}) async =>
      (await _resolved).write(key: key, value: value);

  Future<String?> read({required String key}) async =>
      (await _resolved).read(key: key);

  Future<void> delete({required String key}) async =>
      (await _resolved).delete(key: key);

  Future<bool> containsKey({required String key}) async =>
      (await _resolved).containsKey(key: key);

  Future<Map<String, String>> readAll() async => (await _resolved).readAll();

  Future<void> deleteAll() async => (await _resolved).deleteAll();
}
