import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';

/// Mock SecureStorageService for testing.
class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _store.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_store);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }
}

/// Creates a test provider config.
ProviderConfig _testProvider(String id) {
  return ProviderConfig.basic(
    id: id,
    name: 'Test $id',
    baseUrl: 'https://api.$id.com/v1',
  );
}

/// Creates a test model config.
ModelConfig _testModel(String providerId, String name) {
  return ModelConfig.basic(
    providerId: providerId,
    modelName: name,
    displayName: name,
    contextLength: 4096,
  );
}

/// Unit tests for ProviderCatalogService.
void main() {
  late MockSecureStorageService secureStorage;
  late ProviderCatalogService catalog;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStorage = MockSecureStorageService();
  });

  group('ProviderCatalogService initialization', () {
    test('creates with empty providers', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.getAllProviders(), isEmpty);
    });

    test('creates with built-in providers', () async {
      final prefs = await SharedPreferences.getInstance();
      final providers = [_testProvider('p1'), _testProvider('p2')];

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: providers,
      );

      // By default, built-in providers are loaded but disabled
      expect(catalog.getAllProvidersRaw(), hasLength(2));
    });
  });

  group('ProviderCatalogService.getProvider', () {
    test('returns provider by ID', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = _testProvider('test');

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [provider],
      );

      final found = catalog.getProvider('test');
      expect(found, isNotNull);
      expect(found!.id, equals('test'));
    });

    test('returns null for unknown ID', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.getProvider('nonexistent'), isNull);
    });
  });

  group('ProviderCatalogService.getAllProviders', () {
    test('returns only enabled providers', () async {
      final prefs = await SharedPreferences.getInstance();
      final p1 = _testProvider('p1');
      final p2 = _testProvider('p2');

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [p1, p2],
      );

      // By default, providers are disabled
      expect(catalog.getAllProviders(), isEmpty);

      await catalog.setProviderEnabled('p1', true);

      final enabled = catalog.getAllProviders();
      expect(enabled, hasLength(1));
      expect(enabled.first.id, equals('p1'));
    });
  });

  group('ProviderCatalogService.getModel', () {
    test('returns model by provider/model format', () async {
      final prefs = await SharedPreferences.getInstance();
      final model1 = _testModel('openai', 'gpt-4o');
      final model2 = _testModel('openai', 'gpt-3.5-turbo');
      final provider = ProviderConfig.basic(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        models: [model1, model2],
      );

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [provider],
      );

      final found = catalog.getModel('openai/gpt-4o');
      expect(found, isNotNull);
      expect(found!.modelName, equals('gpt-4o'));
    });

    test(
      'returns null for legacy provider:model format (only / supported)',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final model = _testModel('anthropic', 'claude-3-opus');
        final provider = ProviderConfig.basic(
          id: 'anthropic',
          name: 'Anthropic',
          baseUrl: 'https://api.anthropic.com',
          models: [model],
        );

        catalog = ProviderCatalogService(
          secureStorage: secureStorage,
          prefs: prefs,
          builtInProviders: [provider],
        );

        final found = catalog.getModel('anthropic:claude-3-opus');
        expect(found, isNull);
      },
    );

    test('returns null for non-existent model', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.getModel('openai/nonexistent'), isNull);
    });

    test('returns null for invalid format', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.getModel('no-separator'), isNull);
    });
  });

  group('ProviderCatalogService.updateProviderModels', () {
    test('updates models for existing provider', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = _testProvider('openai');

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [provider],
      );

      final models = [
        _testModel('openai', 'gpt-4o'),
        _testModel('openai', 'gpt-3.5-turbo'),
      ];

      await catalog.updateProviderModels('openai', models);

      final updated = catalog.getProvider('openai');
      expect(updated, isNotNull);
      expect(updated!.models, hasLength(2));
    });

    test('does nothing for non-existent provider', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      await catalog.updateProviderModels('nonexistent', []);
      // No exception thrown
    });

    test(
      'preserves existing enabled flag when overwriteEnabled=false',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final model = _testModel('openai', 'gpt-4o');
        final provider = ProviderConfig.basic(
          id: 'openai',
          name: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          models: [model],
        );

        catalog = ProviderCatalogService(
          secureStorage: secureStorage,
          prefs: prefs,
          builtInProviders: [provider],
        );

        final newModel = _testModel(
          'openai',
          'gpt-4o',
        ).copyWith(enabled: false);
        await catalog.updateProviderModels('openai', [
          newModel,
        ], overwriteEnabled: false);

        // When overwriteEnabled is false, existing enabled flag is preserved
        final updated = catalog.getModel('openai/gpt-4o');
        expect(updated, isNotNull);
        expect(updated!.enabled, isTrue); // Preserved from original
      },
    );

    test('overwrites enabled flag when overwriteEnabled=true', () async {
      final prefs = await SharedPreferences.getInstance();
      final model = _testModel('openai', 'gpt-4o');
      final provider = ProviderConfig.basic(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        models: [model],
      );

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [provider],
      );

      final newModel = _testModel('openai', 'gpt-4o').copyWith(enabled: false);
      await catalog.updateProviderModels('openai', [
        newModel,
      ], overwriteEnabled: true);

      final updated = catalog.getModel('openai/gpt-4o');
      expect(updated, isNotNull);
      expect(updated!.enabled, isFalse); // Overwritten
    });
  });

  group('ProviderCatalogService API key operations', () {
    test('set and get API key', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      await catalog.setApiKey('openai', 'sk-test-key');

      final key = await catalog.getApiKey('openai');
      expect(key, equals('sk-test-key'));
    });

    test('getApiKeySync returns null for unloaded key', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      final syncKey = catalog.getApiKeySync('openai');
      expect(syncKey, isNull);
    });

    test('deleteApiKey removes key', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      await catalog.setApiKey('openai', 'sk-test-key');
      await catalog.deleteApiKey('openai');

      final key = await catalog.getApiKey('openai');
      expect(key, isNull);
    });

    test('getApiKey caches value', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      await catalog.setApiKey('openai', 'sk-test-key');

      // First call reads from storage
      await catalog.getApiKey('openai');
      // Second call should use cache
      final key = await catalog.getApiKey('openai');
      expect(key, equals('sk-test-key'));
    });
  });

  group('ProviderCatalogService enabled/disabled', () {
    test('isProviderEnabled returns false by default', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.isProviderEnabled('openai'), isFalse);
    });

    test('setProviderEnabled persists state', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = _testProvider('openai');

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [provider],
      );

      await catalog.setProviderEnabled('openai', true);

      expect(catalog.isProviderEnabled('openai'), isTrue);
    });
  });

  group('ProviderCatalogService custom providers', () {
    test('addCustomProvider adds provider', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      final custom = _testProvider('custom-llm');
      catalog.addCustomProvider(custom);

      final found = catalog.getProvider('custom-llm');
      expect(found, isNotNull);
      expect(found!.id, equals('custom-llm'));
    });

    test('removeCustomProvider removes provider', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      final custom = _testProvider('custom-llm');
      catalog.addCustomProvider(custom);
      catalog.removeCustomProvider('custom-llm');

      expect(catalog.getProvider('custom-llm'), isNull);
    });

    test('addCustomProvider replaces existing with same ID', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      final custom1 = _testProvider('custom');
      final custom2 = _testProvider('custom');

      catalog.addCustomProvider(custom1);
      catalog.addCustomProvider(custom2);

      // Should only have one
      final all = catalog.getAllProvidersRaw();
      expect(all.where((p) => p.id == 'custom'), hasLength(1));
    });
  });

  group('ProviderCatalogService defaultModel', () {
    test('returns null when no models', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.defaultModel, isNull);
    });

    test('returns first enabled model', () async {
      final prefs = await SharedPreferences.getInstance();
      final model = _testModel('openai', 'gpt-4o');
      final provider = ProviderConfig.basic(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        models: [model],
        enabled: true,
      );

      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
        builtInProviders: [provider],
      );

      await catalog.setProviderEnabled('openai', true);

      final defaultModel = catalog.defaultModel;
      expect(defaultModel, isNotNull);
      expect(defaultModel!.modelName, equals('gpt-4o'));
    });
  });

  group('ProviderCatalogService.getSelectedModelIds', () {
    test('returns empty list by default', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      expect(catalog.getSelectedModelIds('openai'), isEmpty);
    });

    test('setSelectedModelIds persists selection', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      await catalog.setSelectedModelIds('openai', ['gpt-4o', 'gpt-3.5']);

      final selected = catalog.getSelectedModelIds('openai');
      expect(selected, contains('gpt-4o'));
      expect(selected, contains('gpt-3.5'));
    });

    test('clearSelectedModelIds clears selection', () async {
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: secureStorage,
        prefs: prefs,
      );

      await catalog.setSelectedModelIds('openai', ['gpt-4o']);
      await catalog.clearSelectedModelIds('openai');

      expect(catalog.getSelectedModelIds('openai'), isEmpty);
    });
  });
}
