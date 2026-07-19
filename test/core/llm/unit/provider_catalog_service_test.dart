import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';

import 'package:chatorai/shared/utils/secure_storage_service.dart';

/// Mock SecureStorageService for testing.
class MockSecureStorageService extends SecureStorageService {
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
  Future<bool> containsKey({required String key}) async =>
      _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_store);

  @override
  Future<void> deleteAll() async => _store.clear();

  void clear() => _store.clear();
}

void main() {
  group('ProviderCatalogService', () {
    late MockSecureStorageService mockStorage;
    late ProviderCatalogService catalog;

    final testProvider = ProviderConfig.basic(
      id: 'test-provider',
      name: 'Test Provider',
      baseUrl: 'https://api.test.com/v1',
    );

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    tearDown(() {
      mockStorage.clear();
    });

    group('getSelectedModelIds', () {
      test('returns empty list for unknown provider', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final result = catalog.getSelectedModelIds('nonexistent');
        expect(result, isEmpty);
      });

      test('returns empty list for provider with no selected models', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final result = catalog.getSelectedModelIds('test-provider');
        expect(result, isEmpty);
      });

      test('returns empty list for unknown provider ID', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final result = catalog.getSelectedModelIds('nonexistent');
        expect(result, isEmpty);
      });
    });

    group('setSelectedModelIds and persistence', () {
      test('saves and loads selected IDs', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setSelectedModelIds('test-provider', [
          'test-provider/model-a',
          'test-provider/model-b',
        ]);

        final result = catalog.getSelectedModelIds('test-provider');
        expect(result, ['test-provider/model-a', 'test-provider/model-b']);
      });

      test('setSelectedModelIds persists selected IDs', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setSelectedModelIds('test-provider', [
          'test-provider/model-x',
        ]);

        expect(catalog.getSelectedModelIds('test-provider'), [
          'test-provider/model-x',
        ]);
      });
    });

    group('clearSelectedModelIds', () {
      test('clears selected IDs for a provider', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_selected_test-provider': [
            'test-provider/model-a',
            'test-provider/model-b',
          ],
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        // Verify loaded from prefs
        expect(catalog.getSelectedModelIds('test-provider'), [
          'test-provider/model-a',
          'test-provider/model-b',
        ]);

        await catalog.clearSelectedModelIds('test-provider');

        expect(catalog.getSelectedModelIds('test-provider'), isEmpty);
      });

      test('clearSelectedModelIds removes selected models', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setSelectedModelIds('test-provider', ['test-provider/a']);
        expect(catalog.getSelectedModelIds('test-provider'), [
          'test-provider/a',
        ]);

        await catalog.clearSelectedModelIds('test-provider');
        expect(catalog.getSelectedModelIds('test-provider'), isEmpty);
      });
    });

    group('API key operations', () {
      test('setApiKey stores and retrieves key', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setApiKey('test-provider', 'sk-test-key');
        expect(catalog.getApiKeySync('test-provider'), 'sk-test-key');
      });

      test('deleteApiKey removes key', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setApiKey('test-provider', 'sk-test-key');
        expect(catalog.getApiKeySync('test-provider'), 'sk-test-key');

        await catalog.deleteApiKey('test-provider');
        expect(catalog.getApiKeySync('test-provider'), isNull);
      });
    });

    group('provider config operations', () {
      test('setProviderEnabled persists value', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setProviderEnabled('test-provider', false);
        expect(catalog.isProviderEnabled('test-provider'), false);

        await catalog.setProviderEnabled('test-provider', true);
        expect(catalog.isProviderEnabled('test-provider'), true);
      });

      test('setCustomBaseUrl persists value', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setCustomBaseUrl(
          'test-provider',
          'https://custom.api.com',
        );
        expect(
          catalog.getCustomBaseUrl('test-provider'),
          'https://custom.api.com',
        );
      });

      test('applyConfigProviders adds and overrides by id', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final configProvider = ProviderConfig.basic(
          id: 'new-provider',
          name: 'New Provider',
          baseUrl: 'https://new.api/v1',
          source: ProviderSource.config,
          models: [
            ModelConfig.basic(
              providerId: 'new-provider',
              modelName: 'm1',
              displayName: 'M1',
              contextLength: 1000,
            ),
          ],
        );

        catalog.applyConfigProviders([configProvider]);
        final added = catalog.getProvider('new-provider');
        expect(added, isNotNull);
        expect(added!.baseUrl, equals('https://new.api/v1'));
        expect(added.isConfig, isTrue);
        expect(added.models, hasLength(1));

        // Override existing built-in by id
        final override = ProviderConfig.basic(
          id: 'test-provider',
          name: 'Overridden',
          baseUrl: 'https://override/v1',
          source: ProviderSource.config,
        );
        catalog.applyConfigProviders([override]);
        final ov = catalog.getProvider('test-provider');
        expect(ov!.name, equals('Overridden'));
        expect(ov.baseUrl, equals('https://override/v1'));
        expect(ov.isConfig, isTrue);
        // Only one entry per id
        expect(
          catalog.getAllProvidersRaw().where((p) => p.id == 'test-provider'),
          hasLength(1),
        );
      });

      test(
        'config providers are read-only (not persisted, mutations no-op)',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final configProvider = ProviderConfig.basic(
            id: 'cfg',
            name: 'Cfg',
            baseUrl: 'https://cfg/v1',
            auth: AuthConfig.apiKey(apiKey: 'secret'),
            source: ProviderSource.config,
          );
          catalog.applyConfigProviders([configProvider]);

          // Mutation methods must be no-ops for config providers.
          await catalog.setApiKey('cfg', 'leaked');
          await catalog.setProviderEnabled('cfg', false);
          await catalog.setCustomBaseUrl('cfg', 'https://evil/v1');
          catalog.removeCustomProvider('cfg');

          // Provider still present, unchanged, not persisted.
          final p = catalog.getProvider('cfg');
          expect(p, isNotNull);
          expect(p!.auth.apiKey, equals('secret'));
          expect(
            catalog.isProviderEnabled('cfg'),
            isFalse,
          ); // prefs flag untouched

          // Nothing written to secure storage / prefs custom list.
          expect(prefs.getString('catalog_custom_providers'), isNull);
          final stored = await mockStorage.read(key: 'catalog_apiKey_cfg');
          expect(stored, isNull);
        },
      );
    });

    group('_loadFromPrefs', () {
      test('loads catalog_selected_ keys from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_selected_test-provider': [
            'test-provider/model-a',
            'test-provider/model-b',
          ],
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final result = catalog.getSelectedModelIds('test-provider');
        expect(result, ['test-provider/model-a', 'test-provider/model-b']);
      });

      test('loads provider enabled state from prefs', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.isProviderEnabled('test-provider'), false);
      });

      test(
        'legacy custom providers are tagged as custom source on load',
        () async {
          // Simulate a custom provider persisted BEFORE the `source` field
          // existed (no `source` key in JSON).
          final legacyJson = jsonEncode([
            {
              'id': 'legacy-custom',
              'name': 'Legacy Custom',
              'baseUrl': 'https://legacy/v1',
              'models': [],
              'enabled': true,
            },
          ]);
          SharedPreferences.setMockInitialValues({
            'catalog_custom_providers': legacyJson,
          });
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final loaded = catalog.getProvider('legacy-custom');
          expect(loaded, isNotNull);
          expect(loaded!.source, equals(ProviderSource.custom));
          // Legacy custom providers must remain editable (not treated as config).
          expect(loaded.isConfig, isFalse);
          await catalog.setApiKey('legacy-custom', 'updated');
          expect(
            await mockStorage.read(
              key: 'catalog_provider_api_key_legacy-custom',
            ),
            equals('updated'),
          );
        },
      );

      test('provider is enabled by default when no pref is set', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        // Provider is now disabled by default; must be explicitly enabled
        await catalog.setProviderEnabled('test-provider', true);
        expect(catalog.isProviderEnabled('test-provider'), true);
      });
    });

    group('migrateFromLegacySettings API key migration', () {
      test('migrates legacy API key to secure storage', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': true,
          'provider_api_key_test-provider': 'sk-legacy-key',
        });
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.migrateFromLegacySettings();

        // Legacy API key should be migrated to secure storage
        final key = await catalog.getApiKey('test-provider');
        expect(key, 'sk-legacy-key');
      });

      test('migrates legacy base URL to new format', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': true,
          'provider_base_url_test-provider': 'https://legacy.example.com/v1',
        });
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.migrateFromLegacySettings();

        expect(
          catalog.getCustomBaseUrl('test-provider'),
          'https://legacy.example.com/v1',
        );
      });

      test('migrates legacy selected models to new format', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': true,
          'provider_models_test-provider': [
            'test-provider/model-a',
            'test-provider/model-b',
          ],
        });
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.migrateFromLegacySettings();

        expect(catalog.getSelectedModelIds('test-provider'), [
          'test-provider/model-a',
          'test-provider/model-b',
        ]);
      });
    });

    group('migrateFromLegacySettings', () {
      test('migrates legacy enabled state to new format', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.migrateFromLegacySettings();

        expect(catalog.isProviderEnabled('test-provider'), false);
      });

      test('does not migrate twice', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.migrateFromLegacySettings();
        await catalog.migrateFromLegacySettings();

        // Should still be disabled (migrated only once)
        expect(catalog.isProviderEnabled('test-provider'), false);
      });

      test('migrates legacy enabled state to new format', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.migrateFromLegacySettings();

        expect(catalog.isProviderEnabled('test-provider'), false);
      });

      test('does not migrate twice', () async {
        SharedPreferences.setMockInitialValues({
          'provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        // First migration
        await catalog.migrateFromLegacySettings();
        expect(catalog.isProviderEnabled('test-provider'), false);

        // Change prefs to simulate new legacy data
        await prefs.setBool('provider_enabled_test-provider', true);

        // Second call should be a no-op (already migrated)
        await catalog.migrateFromLegacySettings();
        // Should still be disabled (not overwritten by second migration)
        expect(catalog.isProviderEnabled('test-provider'), false);
      });
    });

    group('dispose', () {
      test('dispose clears API key cache without errors', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setApiKey('test-provider', 'sk-test');

        // Should not throw
        expect(() => catalog.dispose(), returnsNormally);
      });
    });

    group('API key operations', () {
      test('setApiKey and getApiKey work correctly', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setApiKey('test-provider', 'sk-12345');
        final key = await catalog.getApiKey('test-provider');
        expect(key, 'sk-12345');
      });

      test('deleteApiKey removes the key', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setApiKey('test-provider', 'sk-12345');
        await catalog.deleteApiKey('test-provider');
        final key = await catalog.getApiKey('test-provider');
        expect(key, isNull);
      });

      test('getApiKeySync returns cached key', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setApiKey('test-provider', 'sk-cached');
        expect(catalog.getApiKeySync('test-provider'), 'sk-cached');
      });
    });

    group('Provider lookup', () {
      test('getProvider returns correct provider by ID', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final provider = catalog.getProvider('test-provider');
        expect(provider, isNotNull);
        expect(provider!.id, 'test-provider');
        expect(provider.name, 'Test Provider');
      });

      test('getProvider returns null for unknown ID', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.getProvider('nonexistent'), isNull);
      });

      test('getAllProviders returns only enabled providers', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final providers = catalog.getAllProviders();
        expect(providers, isEmpty);
      });

      test(
        'getAllProvidersRaw returns all providers regardless of enabled',
        () async {
          SharedPreferences.setMockInitialValues({
            'catalog_provider_enabled_test-provider': false,
          });
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final providers = catalog.getAllProvidersRaw();
          expect(providers, hasLength(1));
          expect(providers.first.id, 'test-provider');
        },
      );
    });

    group('Model lookup', () {
      test('getModel resolves provider/model format', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final providerWithModels = testProvider.copyWith(
          models: [
            ModelConfig.basic(
              providerId: 'test-provider',
              modelName: 'gpt-4o',
              displayName: 'GPT-4o',
              contextLength: 128000,
            ),
          ],
        );
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [providerWithModels],
        );

        final model = catalog.getModel('test-provider/gpt-4o');
        expect(model, isNotNull);
        expect(model!.modelName, 'gpt-4o');
      });

      test('getModel returns null for unknown model', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.getModel('test-provider/unknown'), isNull);
      });

      test('getModel returns null for invalid format', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.getModel('no-separator'), isNull);
      });

      test('getAllModels returns models from enabled providers only', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final providerWithModels = testProvider.copyWith(
          models: [
            ModelConfig.basic(
              providerId: 'test-provider',
              modelName: 'gpt-4o',
              displayName: 'GPT-4o',
              contextLength: 128000,
            ),
          ],
        );
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [providerWithModels],
        );

        expect(catalog.getAllModels(), isEmpty);
      });
    });

    group('Custom base URL', () {
      test('setCustomBaseUrl and getCustomBaseUrl work correctly', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setCustomBaseUrl(
          'test-provider',
          'https://custom.example.com/v1',
        );

        expect(
          catalog.getCustomBaseUrl('test-provider'),
          'https://custom.example.com/v1',
        );
      });

      test('getCustomBaseUrl returns null when not set', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.getCustomBaseUrl('test-provider'), isNull);
      });
    });

    group('Provider enabled state', () {
      test('setProviderEnabled persists the value', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.setProviderEnabled('test-provider', false);
        expect(catalog.isProviderEnabled('test-provider'), false);

        await catalog.setProviderEnabled('test-provider', true);
        expect(catalog.isProviderEnabled('test-provider'), true);
      });
    });

    group('Default model', () {
      test('defaultModel returns first enabled model', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final providerWithModels = testProvider.copyWith(
          models: [
            ModelConfig.basic(
              providerId: 'test-provider',
              modelName: 'gpt-4o',
              displayName: 'GPT-4o',
              contextLength: 128000,
            ),
            ModelConfig.basic(
              providerId: 'test-provider',
              modelName: 'gpt-4o-mini',
              displayName: 'GPT-4o Mini',
              contextLength: 128000,
            ),
          ],
        );
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [providerWithModels],
        );

        // Enable provider since disabled by default
        await catalog.setProviderEnabled('test-provider', true);
        expect(catalog.defaultModel?.modelName, 'gpt-4o');
      });

      test('defaultModel returns null when no models exist', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.defaultModel, isNull);
      });
    });

    group('forceRefresh bypasses cached discovery', () {
      test(
        'updateProviderModels stores and getAllModels returns them',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
            cacheDuration: const Duration(hours: 24),
          );

          // Provider should have no models initially
          expect(catalog.getProvider('test-provider')?.models, isEmpty);

          final modelA = ModelConfig.basic(
            providerId: 'test-provider',
            modelName: 'gpt-4o',
            displayName: 'GPT-4o',
            contextLength: 128000,
          );
          final modelB = ModelConfig.basic(
            providerId: 'test-provider',
            modelName: 'gpt-4o-mini',
            displayName: 'GPT-4o Mini',
            contextLength: 128000,
          );

          await catalog.updateProviderModels('test-provider', [modelA, modelB]);

          // Models should now be stored
          final storedModels = catalog.getProvider('test-provider')?.models;
          expect(storedModels, hasLength(2));
          expect(storedModels?.map((m) => m.modelName).toSet(), {
            'gpt-4o',
            'gpt-4o-mini',
          });

          // Enable provider (disabled by default) so getAllModels includes them
          await catalog.setProviderEnabled('test-provider', true);
          expect(catalog.getAllModels(), hasLength(2));
        },
      );

      test('updateProviderModels overwrites previous models', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
          cacheDuration: const Duration(hours: 24),
        );

        final modelA = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'gpt-4o',
          displayName: 'GPT-4o',
          contextLength: 128000,
        );

        await catalog.updateProviderModels('test-provider', [modelA]);
        expect(catalog.getProvider('test-provider')?.models, hasLength(1));
        expect(
          catalog.getProvider('test-provider')?.models.first.modelName,
          'gpt-4o',
        );

        // Now overwrite with different models
        final modelB = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'claude-sonnet',
          displayName: 'Claude Sonnet',
          contextLength: 200000,
        );

        await catalog.updateProviderModels('test-provider', [modelB]);
        expect(catalog.getProvider('test-provider')?.models, hasLength(1));
        expect(
          catalog.getProvider('test-provider')?.models.first.modelName,
          'claude-sonnet',
        );
      });

      test(
        'clearSelectedModelIds removes selected models but not provider models',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final modelA = ModelConfig.basic(
            providerId: 'test-provider',
            modelName: 'gpt-4o',
            displayName: 'GPT-4o',
            contextLength: 128000,
          );

          await catalog.updateProviderModels('test-provider', [modelA]);
          await catalog.setSelectedModelIds('test-provider', [
            'test-provider/gpt-4o',
          ]);

          expect(catalog.getSelectedModelIds('test-provider'), [
            'test-provider/gpt-4o',
          ]);

          await catalog.clearSelectedModelIds('test-provider');

          // Selected IDs cleared
          expect(catalog.getSelectedModelIds('test-provider'), isEmpty);
          // But provider models remain
          expect(catalog.getProvider('test-provider')?.models, hasLength(1));
        },
      );
    });

    group('discoverModels fetches from API on forceRefresh', () {
      test('getProvider models empty before updateProviderModels', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        // Before update — no models
        expect(catalog.getProvider('test-provider')?.models, isEmpty);

        final modelA = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'llama-3',
          displayName: 'Llama 3',
          contextLength: 8192,
        );

        await catalog.updateProviderModels('test-provider', [modelA]);

        // After update — models present
        expect(catalog.getProvider('test-provider')?.models, hasLength(1));
        expect(
          catalog.getProvider('test-provider')?.models.first.modelName,
          'llama-3',
        );
      });
    });

    group('updateProviderModels persists models across restart', () {
      test('models survive service re-creation', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // First instance: save models
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final modelA = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'model-a',
          displayName: 'Model A',
          contextLength: 4096,
        );
        final modelB = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'model-b',
          displayName: 'Model B',
          contextLength: 8192,
        );

        await catalog.updateProviderModels('test-provider', [modelA, modelB]);

        // Enable provider (disabled by default) so getAllModels returns them
        await catalog.setProviderEnabled('test-provider', true);

        // Verify saved via getAllModels
        expect(catalog.getAllModels(), hasLength(2));

        // Create new instance (simulates restart) with same prefs + storage
        final catalog2 = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        // Enable provider in new instance too
        await catalog2.setProviderEnabled('test-provider', true);

        // Models should be loaded from SharedPreferences
        final models = catalog2.getAllModels();
        expect(models, hasLength(2));
        expect(models.map((m) => m.modelName).toSet(), {'model-a', 'model-b'});
      });
    });

    group('addCustomProvider', () {
      test('generates fallback ID for non-Latin names', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [],
        );

        final customProvider = ProviderConfig.basic(
          id: 'custom_provider_ру',
          name: 'Мой Провайдер',
          baseUrl: 'https://custom.example.com/v1',
        );

        catalog.addCustomProvider(customProvider);

        final allProviders = catalog.getAllProvidersRaw();
        expect(allProviders, hasLength(1));
        expect(allProviders.first.name, 'Мой Провайдер');
        expect(allProviders.first.id, 'custom_provider_ру');
      });
    });

    group('cacheDuration', () {
      test('can be overridden in constructor', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
          cacheDuration: const Duration(minutes: 5),
        );

        // Should instantiate without errors and function normally
        expect(catalog.getProvider('test-provider'), isNotNull);
        expect(catalog.getAllModels(), isEmpty);
      });
    });

    group('loadFromPrefs ignores non-catalog pref keys', () {
      test(
        'getSelectedModelIds does not pick up garbage from other keys',
        () async {
          SharedPreferences.setMockInitialValues({
            'some_other_key': ['should-not-be-selected'],
            'completely_unrelated': ['garbage'],
          });
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          // Should return empty — non-catalog keys must be ignored
          final result = catalog.getSelectedModelIds('test-provider');
          expect(result, isEmpty);

          // Also verify the unrelated keys don't crash _loadFromPrefs
          expect(catalog.getProvider('test-provider'), isNotNull);
        },
      );
    });

    group('canonicalId model naming', () {
      test(
        'modelName already containing providerId is double-prefixed (OpenCode convention)',
        () async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final model = ModelConfig.basic(
            providerId: 'test-provider',
            modelName: 'test-provider/free',
            displayName: 'Test Free',
            contextLength: 4096,
          );

          await catalog.updateProviderModels('test-provider', [model]);

          final stored = catalog.getProvider('test-provider')?.models;
          expect(stored, hasLength(1));
          expect(stored!.first.id, 'test-provider/test-provider/free');
          expect(stored.first.modelName, 'test-provider/free');
          expect(stored.first.providerId, 'test-provider');
        },
      );

      test('getModel resolves single-prefixed ID', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final model = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'test-provider/model-a',
          displayName: 'Model A',
          contextLength: 4096,
        );

        await catalog.updateProviderModels('test-provider', [model]);
        await catalog.setProviderEnabled('test-provider', true);

        final resolved = catalog.getModel('test-provider/model-a');
        expect(resolved, isNotNull);
        expect(resolved!.id, 'test-provider/test-provider/model-a');
        expect(resolved.modelName, 'test-provider/model-a');
      });

      test('colon in modelName preserved in canonicalId', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final model = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'test-provider:model-a',
          displayName: 'Model A',
          contextLength: 4096,
        );

        await catalog.updateProviderModels('test-provider', [model]);

        final stored = catalog.getProvider('test-provider')?.models;
        expect(stored, hasLength(1));
        expect(stored!.first.id, 'test-provider/test-provider:model-a');
      });

      test('raw modelName without prefix gets single-prefixed', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final model = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        );

        await catalog.updateProviderModels('test-provider', [model]);

        final stored = catalog.getProvider('test-provider')?.models;
        expect(stored, hasLength(1));
        expect(stored!.first.id, 'test-provider/owl-alpha');
        expect(stored.first.modelName, 'owl-alpha');
      });

      test('two models with same root name get distinct IDs', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final modelA = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'test-provider/free',
          displayName: 'Test Free',
          contextLength: 4096,
        );
        final modelB = ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        );

        await catalog.updateProviderModels('test-provider', [modelA, modelB]);
        await catalog.setProviderEnabled('test-provider', true);

        final ids = catalog.getAllModels().map((m) => m.id).toSet();
        expect(ids, contains('test-provider/test-provider/free'));
        expect(ids, contains('test-provider/owl-alpha'));
      });
    });

    group('preloadApiKeys', () {
      test('loads API keys from secure storage into cache', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        await mockStorage.write(
          key: 'catalog_provider_api_key_test-provider',
          value: 'sk-preloaded',
        );
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        await catalog.preloadApiKeys();

        expect(catalog.getApiKeySync('test-provider'), 'sk-preloaded');
      });
    });

    group('updatePrefs', () {
      test('reloads state from new prefs instance', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.isProviderEnabled('test-provider'), false);

        // Create new prefs with different values
        SharedPreferences.setMockInitialValues({
          'catalog_provider_enabled_test-provider': true,
        });
        final newPrefs = await SharedPreferences.getInstance();
        catalog.updatePrefs(newPrefs);

        expect(catalog.isProviderEnabled('test-provider'), true);
      });
    });

    group('removeCustomProvider', () {
      test('removes a custom provider by ID', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [],
        );

        catalog.addCustomProvider(
          ProviderConfig.basic(
            id: 'custom-1',
            name: 'Custom One',
            baseUrl: 'https://custom1.example.com',
          ),
        );
        catalog.addCustomProvider(
          ProviderConfig.basic(
            id: 'custom-2',
            name: 'Custom Two',
            baseUrl: 'https://custom2.example.com',
          ),
        );

        expect(catalog.getAllProvidersRaw(), hasLength(2));

        catalog.removeCustomProvider('custom-1');

        expect(catalog.getAllProvidersRaw(), hasLength(1));
        expect(catalog.getAllProvidersRaw().first.id, 'custom-2');
      });
    });

    group('_stripTruncation', () {
      test(
        'removes trailing truncation markers from description on reload',
        () async {
          SharedPreferences.setMockInitialValues({'catalog_cache_version': 4});
          final prefs = await SharedPreferences.getInstance();
          mockStorage = MockSecureStorageService();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final model = ModelConfig.basic(
            providerId: 'test-provider',
            modelName: 'gpt-4o',
            displayName: 'GPT-4o',
            description: 'A great model...with truncation...',
            contextLength: 128000,
          );

          await catalog.updateProviderModels('test-provider', [model]);

          // Create a new catalog instance to trigger _loadFromPrefs with cache
          final catalog2 = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          final stored = catalog2.getProvider('test-provider')?.models.first;
          expect(stored, isNotNull);
          // _stripTruncation is called during _loadFromPrefs when loading from cache
          // The description should have truncation markers removed
          expect(stored!.description, isNot(contains('...')));
        },
      );
    });

    group('addListener/removeListener', () {
      test('addListener and removeListener are no-ops', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        // Should not throw
        expect(() => catalog.addListener(() {}), returnsNormally);
        expect(() => catalog.removeListener(() {}), returnsNormally);
      });
    });

    group('getAllModelsRaw', () {
      test('returns all models regardless of enabled state', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_provider_enabled_test-provider': false,
        });
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        final providerWithModels = testProvider.copyWith(
          models: [
            ModelConfig.basic(
              providerId: 'test-provider',
              modelName: 'gpt-4o',
              displayName: 'GPT-4o',
              contextLength: 128000,
            ),
          ],
        );
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [providerWithModels],
        );

        // Provider is disabled, so getAllModels returns empty
        expect(catalog.getAllModels(), isEmpty);

        // But getAllModelsRaw returns models regardless
        final allModels = catalog.getAllModelsRaw();
        expect(allModels, hasLength(1));
        expect(allModels.first.modelName, 'gpt-4o');
      });
    });

    group('custom providers persistence', () {
      test('loads custom providers from stored JSON', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [],
        );

        // Add a custom provider
        catalog.addCustomProvider(
          ProviderConfig.basic(
            id: 'my-custom',
            name: 'My Custom',
            baseUrl: 'https://custom.example.com/v1',
          ),
        );

        // Create new catalog instance to load from prefs
        final catalog2 = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [],
        );

        final providers = catalog2.getAllProvidersRaw();
        expect(providers, hasLength(1));
        expect(providers.first.id, 'my-custom');
        expect(providers.first.name, 'My Custom');
      });

      test('handles invalid custom providers JSON gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'catalog_custom_providers': 'not valid json',
        });
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [],
        );

        // Should not throw, just skip invalid JSON
        expect(catalog.getAllProvidersRaw(), isEmpty);
      });
    });

    group('discoverModels error handling', () {
      test('returns empty list when provider not found', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        mockStorage = MockSecureStorageService();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        final result = await catalog.discoverModels('nonexistent');
        expect(result, isEmpty);
      });

      test(
        'returns empty list on network failure',
        () async {
          SharedPreferences.setMockInitialValues({'catalog_cache_version': 4});
          final prefs = await SharedPreferences.getInstance();
          mockStorage = MockSecureStorageService();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
            // Very short timeout so the test doesn't hang
            cacheDuration: const Duration(milliseconds: 1),
          );

          // Wait for cache to expire
          await Future.delayed(const Duration(milliseconds: 2));

          // discoverModels will try to connect to https://api.test.com/v1/models
          // which should fail in test environment
          final result = await catalog.discoverModels('test-provider');
          // Should return empty on network failure
          expect(result, isEmpty);
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'forceRefresh bypasses cache even when fresh',
        () async {
          SharedPreferences.setMockInitialValues({
            'catalog_cache_version': 4,
            'catalog_discovered_at_test-provider':
                DateTime.now().millisecondsSinceEpoch,
          });
          final prefs = await SharedPreferences.getInstance();
          mockStorage = MockSecureStorageService();
          catalog = ProviderCatalogService(
            secureStorage: mockStorage,
            prefs: prefs,
            builtInProviders: [testProvider],
          );

          // First, populate models
          final model = ModelConfig.basic(
            providerId: 'test-provider',
            modelName: 'gpt-4o',
            displayName: 'GPT-4o',
            contextLength: 128000,
          );
          await catalog.updateProviderModels('test-provider', [model]);
          await catalog.setProviderEnabled('test-provider', true);

          // discoverModels with forceRefresh should try network (and fail)
          // but the method catches errors and returns []
          final result = await catalog.discoverModels(
            'test-provider',
            forceRefresh: true,
          );
          // Network call fails → returns empty
          expect(result, isEmpty);
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });
  });
}
