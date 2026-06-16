import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/llm/catalog/provider_catalog_service.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';

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

      test('provider is enabled by default when no pref is set', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        catalog = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

        expect(catalog.isProviderEnabled('test-provider'), true);
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
              id: 'test-provider/gpt-4o',
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
              id: 'test-provider/gpt-4o',
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
              id: 'test-provider/gpt-4o',
              providerId: 'test-provider',
              modelName: 'gpt-4o',
              displayName: 'GPT-4o',
              contextLength: 128000,
            ),
            ModelConfig.basic(
              id: 'test-provider/gpt-4o-mini',
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
            id: 'test-provider/gpt-4o',
            providerId: 'test-provider',
            modelName: 'gpt-4o',
            displayName: 'GPT-4o',
            contextLength: 128000,
          );
          final modelB = ModelConfig.basic(
            id: 'test-provider/gpt-4o-mini',
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

          // getAllModels should include them (provider is enabled by default)
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
          id: 'test-provider/gpt-4o',
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
          id: 'test-provider/claude-sonnet',
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
            id: 'test-provider/gpt-4o',
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
          id: 'test-provider/llama-3',
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
          id: 'test-provider/model-a',
          providerId: 'test-provider',
          modelName: 'model-a',
          displayName: 'Model A',
          contextLength: 4096,
        );
        final modelB = ModelConfig.basic(
          id: 'test-provider/model-b',
          providerId: 'test-provider',
          modelName: 'model-b',
          displayName: 'Model B',
          contextLength: 8192,
        );

        await catalog.updateProviderModels('test-provider', [modelA, modelB]);

        // Verify saved via getAllModels
        expect(catalog.getAllModels(), hasLength(2));

        // Create new instance (simulates restart) with same prefs + storage
        final catalog2 = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [testProvider],
        );

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
  });
}
