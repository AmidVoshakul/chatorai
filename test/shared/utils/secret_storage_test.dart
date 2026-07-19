import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/shared/utils/secret_storage.dart';

/// Mock storage that throws on every operation (simulates locked/unavailable keyring).
class _FailingMockStorage implements SecretStorage {
  @override
  Future<void> write({required String key, required String value}) async {
    throw Exception('KeyringLocked');
  }

  @override
  Future<String?> read({required String key}) async {
    throw Exception('KeyringLocked');
  }

  @override
  Future<void> delete({required String key}) async {
    throw Exception('KeyringLocked');
  }

  @override
  Future<bool> containsKey({required String key}) async {
    throw Exception('KeyringLocked');
  }

  @override
  Future<Map<String, String>> readAll() async {
    throw Exception('KeyringLocked');
  }

  @override
  Future<void> deleteAll() async {
    throw Exception('KeyringLocked');
  }
}

void main() {
  group('PrefsSecretStorage', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('writes and reads encrypted secret', () async {
      final storage = PrefsSecretStorage(prefs);
      await storage.write(key: 'test-key', value: 'sk-secret-key-123');

      final value = await storage.read(key: 'test-key');
      expect(value, 'sk-secret-key-123');
    });

    test('reads null for missing key', () async {
      final storage = PrefsSecretStorage(prefs);
      final value = await storage.read(key: 'nonexistent');
      expect(value, isNull);
    });

    test('delete removes secret', () async {
      final storage = PrefsSecretStorage(prefs);
      await storage.write(key: 'test-key', value: 'secret');
      await storage.delete(key: 'test-key');
      expect(await storage.read(key: 'test-key'), isNull);
    });

    test('containsKey returns correct value', () async {
      final storage = PrefsSecretStorage(prefs);
      expect(await storage.containsKey(key: 'test-key'), false);
      await storage.write(key: 'test-key', value: 'secret');
      expect(await storage.containsKey(key: 'test-key'), true);
    });

    test('readAll returns all secrets', () async {
      final storage = PrefsSecretStorage(prefs);
      await storage.write(key: 'key1', value: 'value1');
      await storage.write(key: 'key2', value: 'value2');

      final all = await storage.readAll();
      expect(all, {'key1': 'value1', 'key2': 'value2'});
    });

    test('deleteAll removes all secrets', () async {
      final storage = PrefsSecretStorage(prefs);
      await storage.write(key: 'key1', value: 'value1');
      await storage.write(key: 'key2', value: 'value2');
      await storage.deleteAll();

      expect(await storage.read(key: 'key1'), isNull);
      expect(await storage.read(key: 'key2'), isNull);
    });

    test('persists encrypted data across instances', () async {
      final storage1 = PrefsSecretStorage(prefs);
      await storage1.write(key: 'persistent-key', value: 'persistent-value');

      final storage2 = PrefsSecretStorage(prefs);
      final value = await storage2.read(key: 'persistent-key');
      expect(value, 'persistent-value');
    });
  });

  group('SecretStorageFactory', () {
    late SharedPreferences prefs;
    late FlutterSecureStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = const FlutterSecureStorage();
    });

    test('creates with PrefsSecretStorage when keyring unavailable', () async {
      final factory = await SecretStorageFactory.create(
        keyring: storage,
        prefs: prefs,
        forcePrefs: true,
      );
      expect(factory.usingFallback, true);
    });

    test('write/read works in fallback mode', () async {
      final factory = await SecretStorageFactory.create(
        keyring: storage,
        prefs: prefs,
        forcePrefs: true,
      );

      await factory.write(key: 'api-key', value: 'sk-fallback-test');
      final value = await factory.read(key: 'api-key');
      expect(value, 'sk-fallback-test');
    });

    test('graceful degradation after keyring failure', () async {
      final factory = await SecretStorageFactory.create(
        keyring: storage,
        prefs: prefs,
        forcePrefs: true,
      );

      expect(factory.usingFallback, true);

      // After initial failure, subsequent calls should work
      await factory.write(key: 'key-after-fail', value: 'value-after-fail');
      final value = await factory.read(key: 'key-after-fail');
      expect(value, 'value-after-fail');

      // containsKey should also work
      expect(await factory.containsKey(key: 'key-after-fail'), true);

      // delete should work
      await factory.delete(key: 'key-after-fail');
      expect(await factory.read(key: 'key-after-fail'), isNull);

      // readAll should work
      await factory.write(key: 'key1', value: 'v1');
      await factory.write(key: 'key2', value: 'v2');
      final all = await factory.readAll();
      expect(all, contains('key1'));
      expect(all, contains('key2'));

      // deleteAll should work
      await factory.deleteAll();
      expect((await factory.readAll()).length, 0);
    });

    test('graceful degradation when keyring fails at runtime', () async {
      // Create factory with failing backend and working fallback
      final fallback = PrefsSecretStorage(prefs);
      final factory = SecretStorageFactory.test(
        _FailingMockStorage(),
        fallback,
        false,
      );

      // First operations should fail over to fallback
      await factory.write(key: 'first-key', value: 'first-value');
      final value = await factory.read(key: 'first-key');
      expect(value, 'first-value');
      expect(factory.usingFallback, true);

      // Subsequent operations should use fallback directly
      await factory.write(key: 'second-key', value: 'second-value');
      expect(await factory.read(key: 'second-key'), 'second-value');

      // containsKey should work
      expect(await factory.containsKey(key: 'first-key'), true);

      // delete should work
      await factory.delete(key: 'first-key');
      expect(await factory.read(key: 'first-key'), isNull);

      // readAll/deleteAll should work
      await factory.write(key: 'k1', value: 'v1');
      await factory.write(key: 'k2', value: 'v2');
      final all = await factory.readAll();
      expect(all.length, 3); // second-key, k1, k2 (first-key was deleted)
      await factory.deleteAll();
      expect((await factory.readAll()).length, 0);
    });
  });
}
