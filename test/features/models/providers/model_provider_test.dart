import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/features/models/providers/model_provider.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression: modelProvider must populate availableModels/selectedModelObject
/// from the SYNC catalog WITHOUT awaiting catalogInitializationProvider (warm).
void main() {
  group('ModelNotifier sync catalog', () {
    test('populates models from sync catalog without awaiting warm', () async {
      SharedPreferences.setMockInitialValues({
        'catalog_provider_enabled_openrouter': true,
        'catalog_selected_openrouter': <String>['openrouter/test-model'],
      });
      final prefs = await SharedPreferences.getInstance();
      PreferencesHolder.prefs = prefs;

      // Build a catalog instance with a pre-seeded model so the sync path
      // returns availableModels without needing network discovery.
      final catalogInstance = ProviderCatalogService(
        secureStorage: SecureStorageService(),
        prefs: prefs,
        builtInProviders: builtInProviders(),
      );
      await catalogInstance.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'test-model',
          displayName: 'Test Model',
          description: 'Test',
          contextLength: 4096,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(
            SecureStorageService(),
          ),
          catalogServiceProvider.overrideWithValue(catalogInstance),
        ],
      );

      // Read modelProvider — it should populate from the sync catalog
      // without needing catalogInitializationProvider.future.
      final state = container.read(modelProvider);

      // Wait for models to load (bounded by the notifier's internal logic).
      await container
          .read(modelProvider.notifier)
          .waitForModelsLoaded(timeout: const Duration(seconds: 5));

      final loaded = container.read(modelProvider);
      expect(
        loaded.modelsLoaded,
        isTrue,
        reason: 'modelsLoaded should be true after sync catalog load',
      );
      expect(
        loaded.availableModels,
        isNotEmpty,
        reason: 'availableModels should be populated from sync catalog',
      );
      expect(loaded.selectedModelId, equals('openrouter/test-model'));
    });
  });
}
