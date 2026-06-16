/// Riverpod providers for the AI provider catalog.
///
/// Provides access to [ProviderCatalogService] and [ModelResolver] via DI,
/// plus convenience providers for available models, selected model, etc.
library;

import 'package:chatorai/core/llm/catalog/model_resolver.dart';
import 'package:chatorai/core/llm/catalog/models/auth_config.dart';
import 'package:chatorai/core/llm/catalog/models/configured_provider.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/provider_config.dart';
import 'package:chatorai/core/llm/catalog/provider_catalog_service.dart';
import 'package:chatorai/core/llm/catalog/providers/built_in_providers.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// CATALOG SERVICE PROVIDER
// =============================================================================

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// FutureProvider for async initialization of the catalog.
/// This is the primary provider — consumers should use .when() to handle states.
final catalogInitializationProvider = FutureProvider<ProviderCatalogService>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final service = ProviderCatalogService(
    secureStorage: secureStorage,
    prefs: prefs,
    builtInProviders: builtInProviders(),
  );
  await service.migrateFromLegacySettings();
  await service.preloadApiKeys();
  return service;
});

/// Synchronous provider that returns the initialized catalog.
/// Throws during loading — consumers should use `catalogInitializationProvider`
/// directly for async access, or handle the error state.
final providerCatalogServiceProvider = Provider<ProviderCatalogService>((ref) {
  final asyncValue = ref.watch(catalogInitializationProvider);
  return asyncValue.when(
    data: (service) => service,
    loading: () => throw StateError('Catalog not yet initialized'),
    error: (e, st) => throw StateError('Catalog initialization failed: $e'),
  );
});

// =============================================================================
// MODEL RESOLVER PROVIDER
// =============================================================================

final modelResolverProvider = Provider<ModelResolver>((ref) {
  final catalog = ref.watch(providerCatalogServiceProvider);
  return ModelResolver(catalog);
});

// =============================================================================
// CATALOG STATE PROVIDERS
// =============================================================================

/// All models available for selection (from enabled providers).
final availableModelsProvider = Provider<List<ModelConfig>>((ref) {
  final catalog = ref.watch(providerCatalogServiceProvider);
  return catalog.getAllModels().where((m) => m.enabled).toList();
});

/// All providers in the catalog.
final allProvidersProvider = Provider<List<ProviderConfig>>((ref) {
  final catalog = ref.watch(providerCatalogServiceProvider);
  return catalog.getAllProvidersRaw();
});

/// Notifier for the currently selected model ID.
class SelectedModelIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? modelId) {
    state = modelId;
  }

  void clear() {
    state = null;
  }
}

/// Currently selected model ID (mutable state).
final selectedModelIdProvider =
    NotifierProvider<SelectedModelIdNotifier, String?>(
      SelectedModelIdNotifier.new,
    );

/// Currently selected model config.
final selectedModelProvider = Provider<ModelConfig?>((ref) {
  final selectedId = ref.watch(selectedModelIdProvider);
  if (selectedId == null) return null;
  final catalog = ref.watch(providerCatalogServiceProvider);
  return catalog.getModel(selectedId);
});

/// The default model (first enabled model).
final defaultModelProvider = Provider<ModelConfig?>((ref) {
  final catalog = ref.watch(providerCatalogServiceProvider);
  return catalog.defaultModel;
});

/// List of configured providers (with API key or selected models) for settings UI.
/// Uses AsyncValue to handle loading/error states properly.
final configuredProvidersProvider =
    Provider<AsyncValue<List<ConfiguredProvider>>>((ref) {
      final asyncCatalog = ref.watch(catalogInitializationProvider);
      return asyncCatalog.when(
        data: (catalog) {
          final providers = <ConfiguredProvider>[];
          for (final p in catalog.getAllProvidersRaw()) {
            final apiKey = catalog.getApiKeySync(p.id);
            final customBaseUrl = catalog.getCustomBaseUrl(p.id);
            final selectedModelIds = catalog.getSelectedModelIds(p.id);
            final hasApiKey = apiKey != null && apiKey.isNotEmpty;
            final isConfigured =
                hasApiKey ||
                (p.auth.type == AuthType.none &&
                    catalog.isProviderEnabled(p.id)) ||
                selectedModelIds.isNotEmpty;
            if (isConfigured) {
              providers.add(
                ConfiguredProvider(
                  id: p.id,
                  name: p.name,
                  baseUrl: customBaseUrl ?? p.baseUrl,
                  enabled: catalog.isProviderEnabled(p.id),
                  iconPath: p.metadata['iconPath'] as String?,
                ),
              );
            }
          }
          return AsyncValue.data(providers);
        },
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });
