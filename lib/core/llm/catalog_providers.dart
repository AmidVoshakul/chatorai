/// Riverpod providers for the AI provider catalog.
///
/// Provides access to [ProviderCatalogService] and [ModelResolver] via DI,
/// plus convenience providers for available models, selected model, etc.
library;

import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/configured_provider.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/core/llm/providers/built_in_providers.dart';
import 'package:chatorai/core/llm/providers/config_provider_parser.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// CATALOG SERVICE PROVIDER
// =============================================================================

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Shared catalog service instance, available synchronously from the first
/// frame. Construction is cheap (built-in providers only); the heavy
/// `preloadApiKeys` I/O happens later in [catalogInitializationProvider] and must
/// NOT block the UI (see bootstrap split into fast/heavy providers).
///
/// The bootstrap has already awaited `SharedPreferences.getInstance()` and stored
/// it in [PreferencesHolder] before any widget reads this provider, so the
/// instance is built without an async Provider. The service is a single shared
/// instance: [catalogInitializationProvider] warms (preloads keys onto) exactly
/// this object, so key-dependent UI sees the same instance once ready.
ProviderCatalogService? _catalogServiceInstance;

/// Holds the already-loaded [SharedPreferences] (set by the bootstrap) so the
/// catalog service can be constructed synchronously. Providers cannot await, so
/// this bridges the async bootstrap result into the synchronous provider.
class PreferencesHolder {
  static SharedPreferences? prefs;
}

/// Constructs (once) and returns the shared [ProviderCatalogService] instance.
///
/// Cheap: only built-in providers are loaded. The heavy `preloadApiKeys` runs
/// later in [catalogInitializationProvider]. [prefs] must be the already-loaded
/// [SharedPreferences] (the bootstrap awaits `SharedPreferences.getInstance()`
/// and passes it here). Safe to call from bootstrap before any widget reads
/// [catalogServiceProvider].
ProviderCatalogService ensureCatalogService(
  SharedPreferences prefs,
  SecureStorageService secureStorage,
) {
  _catalogServiceInstance ??= ProviderCatalogService(
    secureStorage: secureStorage,
    prefs: prefs,
    builtInProviders: builtInProviders(),
  );
  return _catalogServiceInstance!;
}

/// Synchronous provider exposing the catalog service.
///
/// Unlike the previous throwing implementation, this never throws while the
/// catalog is still warming — built-in models are usable immediately, and
/// `getApiKeySync` simply returns null until [catalogInitializationProvider]
/// finishes preloading. This lets [ChatScreen] (and the Welcome widget) mount on
/// the first frame instead of waiting for the full async init to complete.
///
/// The bootstrap (fast provider) always constructs the instance before the
/// first frame, so [_catalogServiceInstance] is non-null here. The fallback only
/// triggers if a consumer is reached first, in which case [PreferencesHolder.prefs]
/// is already set by the bootstrap.
final catalogServiceProvider = Provider<ProviderCatalogService>((ref) {
  final existing = _catalogServiceInstance;
  if (existing != null) return existing;
  final prefs = PreferencesHolder.prefs;
  if (prefs == null) {
    throw StateError(
      'catalogServiceProvider: SharedPreferences not initialized. '
      'Complete appBootstrapFastProvider before reading the catalog service.',
    );
  }
  return ensureCatalogService(prefs, ref.watch(secureStorageServiceProvider));
});

/// FutureProvider that warms the catalog: migrates legacy settings, preloads
/// API keys (~40 providers, the slow part), and applies chatorai.json providers.
///
/// This is intentionally NOT awaited on the UI render path — it runs in the
/// background while the chat (and Welcome suggestions) are already visible.
final catalogInitializationProvider = FutureProvider<ProviderCatalogService>((
  ref,
) async {
  final service = ref.watch(catalogServiceProvider);
  await service.migrateFromLegacySettings();
  await service.preloadApiKeys();

  // Apply providers declared in chatorai.json (read-only, overrides built-ins).
  final config = await ref.watch(configProvider.future);
  if (config.provider != null) {
    final parser = const ConfigProviderParser();
    service.applyConfigProviders(parser.parse(config.provider));
  }

  return service;
});

/// Synchronous provider that returns the catalog service.
///
/// Replaces the old implementation that threw [StateError] while loading. It now
/// returns the shared instance immediately (built-in models work before keys are
/// preloaded), so [ChatMessages] and other synchronous consumers never crash the
/// first frame. Use [catalogInitializationProvider] only where warmed key state
/// is required (e.g. settings screens listing configured providers).
final providerCatalogServiceProvider = Provider<ProviderCatalogService>((ref) {
  return ref.watch(catalogServiceProvider);
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

/// The first enabled model across all providers (convenience).
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
            // For API-key providers, a key from secure storage OR from the
            // in-memory config (chatorai.json `{env:VAR}`) both count.
            final effectiveApiKey = (apiKey != null && apiKey.isNotEmpty)
                ? apiKey
                : (p.auth.type == AuthType.apiKey ? p.auth.apiKey : null);
            final hasApiKey =
                effectiveApiKey != null && effectiveApiKey.isNotEmpty;
            final isConfigured =
                hasApiKey ||
                (p.auth.type == AuthType.none &&
                    (catalog.isProviderEnabled(p.id) || p.isConfig)) ||
                selectedModelIds.isNotEmpty;
            if (isConfigured) {
              // Config providers are read-only and applied from chatorai.json,
              // so their enabled state comes from the config (defaults true),
              // not from a persisted pref (which is always false for them).
              final enabled = p.isConfig
                  ? p.enabled
                  : catalog.isProviderEnabled(p.id);
              providers.add(
                ConfiguredProvider(
                  id: p.id,
                  name: p.name,
                  baseUrl: customBaseUrl ?? p.baseUrl,
                  enabled: enabled,
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
