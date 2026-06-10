import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data (API keys, tokens).
///
/// Uses platform-specific secure storage:
/// - Android: Keystore with encrypted SharedPreferences
/// - iOS: Keychain (first_unlock accessibility)
/// - macOS: Keychain
/// - Windows: DPAPI
/// - Linux: LibSecret
/// - Web: IndexedDB (consider additional encryption for production)
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  /// Write a value to secure storage
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Delete a value from secure storage
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Check if a key exists
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  /// Read all values
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  /// Delete all values
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
