import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over a secret (API key / token) store.
///
/// On platforms with OS keyring (Android Keystore, iOS/macOS Keychain,
/// Windows DPAPI, Linux LibSecret), secrets are stored in the native vault.
/// When unavailable (Linux without gnome-keyring/secret-service), falls back
/// to AES-256-GCM encrypted SharedPreferences.
///
/// SECURITY NOTE: The fallback encryption key is stored alongside the data.
/// This provides obfuscation against casual inspection but NOT full security.
/// Use on-device keyring when available for hardware-bound encryption.
abstract class SecretStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<bool> containsKey({required String key});
  Future<Map<String, String>> readAll();
  Future<void> deleteAll();
}

class KeyringSecretStorage implements SecretStorage {
  const KeyringSecretStorage(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<bool> containsKey({required String key}) =>
      _storage.containsKey(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  static Future<bool> isAvailable(FlutterSecureStorage storage) async {
    try {
      const probe = '__chatorai_probe__';
      await storage.write(key: probe, value: '1');
      await storage.delete(key: probe);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class PrefsSecretStorage implements SecretStorage {
  PrefsSecretStorage(this._prefs);
  final SharedPreferences _prefs;

  static const _ns = 'secret.';
  static const _keyKey = 'secret.encryption_key';

  static final AesGcm _aesGcm = AesGcm.with256bits();
  SecretKey? _cachedKey;

  Future<SecretKey> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final cached = _prefs.getString(_keyKey);
    if (cached != null) {
      final keyBytes = base64Decode(cached);
      _cachedKey = SecretKey(List<int>.from(keyBytes));
      return _cachedKey!;
    }

    final secretKey = await _aesGcm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    final keyString = base64Encode(keyBytes);
    await _prefs.setString(_keyKey, keyString);
    _cachedKey = secretKey;
    return secretKey;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    final secretKey = await _getOrCreateKey();
    final secretBox = await _aesGcm.encryptString(value, secretKey: secretKey);
    final data = base64Encode(secretBox.concatenation());
    await _prefs.setString('$_ns$key', data);
  }

  @override
  Future<String?> read({required String key}) async {
    final data = _prefs.getString('$_ns$key');
    if (data == null) return null;

    try {
      final bytes = base64Decode(data);
      final secretKey = await _getOrCreateKey();
      final secretBox = SecretBox.fromConcatenation(
        bytes,
        nonceLength: _aesGcm.nonceLength,
        macLength: _aesGcm.macAlgorithm.macLength,
        copy: true,
      );
      final clearText = await _aesGcm.decryptString(
        secretBox,
        secretKey: secretKey,
      );
      return clearText;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    await _prefs.remove('$_ns$key');
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _prefs.containsKey('$_ns$key');
  }

  @override
  Future<Map<String, String>> readAll() async {
    final out = <String, String>{};
    final prefsMap = _prefs.getKeys();
    for (final k in prefsMap) {
      if (k.startsWith(_ns) && k != _keyKey) {
        final v = await read(key: k.substring(_ns.length));
        if (v != null) {
          out[k.substring(_ns.length)] = v;
        }
      }
    }
    return out;
  }

  @override
  Future<void> deleteAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_ns)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}

class SecretStorageFactory {
  SecretStorageFactory._(this._backend, this._fallback, this._usingFallback);

  // Exposed for testing to simulate runtime keyring failure
  SecretStorageFactory.test(this._backend, this._fallback, this._usingFallback);

  SecretStorage _backend;
  final PrefsSecretStorage _fallback;
  bool _usingFallback;

  static Future<SecretStorageFactory> create({
    required FlutterSecureStorage keyring,
    required SharedPreferences prefs,
    bool forcePrefs = false,
  }) async {
    final fallback = PrefsSecretStorage(prefs);
    if (forcePrefs) {
      return SecretStorageFactory._(fallback, fallback, true);
    }
    final available = await KeyringSecretStorage.isAvailable(keyring);
    if (available) {
      return SecretStorageFactory._(
        KeyringSecretStorage(keyring),
        fallback,
        false,
      );
    }
    return SecretStorageFactory._(fallback, fallback, true);
  }

  SecretStorage get backend => _backend;
  bool get usingFallback => _usingFallback;

  Future<void> write({required String key, required String value}) async {
    if (_usingFallback) return _fallback.write(key: key, value: value);
    try {
      await _backend.write(key: key, value: value);
    } catch (_) {
      _usingFallback = true;
      _backend = _fallback;
      await _fallback.write(key: key, value: value);
    }
  }

  Future<String?> read({required String key}) async {
    if (_usingFallback) return _fallback.read(key: key);
    try {
      return await _backend.read(key: key);
    } catch (_) {
      _usingFallback = true;
      _backend = _fallback;
      return _fallback.read(key: key);
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _backend.delete(key: key);
    } catch (_) {
      _usingFallback = true;
      _backend = _fallback;
    }
    if (_usingFallback) await _fallback.delete(key: key);
  }

  Future<bool> containsKey({required String key}) async {
    try {
      return await _backend.containsKey(key: key);
    } catch (_) {
      _usingFallback = true;
      _backend = _fallback;
      return _fallback.containsKey(key: key);
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return await _backend.readAll();
    } catch (_) {
      _usingFallback = true;
      _backend = _fallback;
      return _fallback.readAll();
    }
  }

  Future<void> deleteAll() async {
    try {
      await _backend.deleteAll();
    } catch (_) {
      _usingFallback = true;
      _backend = _fallback;
      await _fallback.deleteAll();
    }
  }
}
