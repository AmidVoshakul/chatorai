/// Centralized provider and model catalog service.
///
/// catalog patterns: centralized registry, immutable data,
/// schema-driven, with persistence via SecureStorage (API keys) and
/// SharedPreferences (settings). Built-in providers are passed in from
/// [builtInProviders()] in [providers/providers.dart]; custom/user-defined
/// providers can be added at runtime.
///
/// Usage:
/// ```dart
/// final catalog = ProviderCatalogService(
///   secureStorage: secureStorage,
///   prefs: prefs,
///   builtInProviders: builtInProviders(),
/// );
/// final providers = catalog.getAllProviders();
/// final model = catalog.getModel('openrouter/openai/gpt-4o');
/// await catalog.setApiKey('openrouter', 'sk-...');
/// ```
library;

import 'dart:convert';

import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prefix constants for SharedPreferences keys.
class _PrefKeys {
  static const enabled = 'catalog_provider_enabled_';
  static const baseUrl = 'catalog_provider_base_url_';
  static const apiKey = 'catalog_provider_api_key_';
  static const selectedModels = 'catalog_selected_';
  // Legacy prefixes for migration from old system
  static const legacyEnabled = 'provider_enabled_';
  static const legacyBaseUrl = 'provider_base_url_';
  static const legacyApiKey = 'provider_api_key_';
  static const legacySelectedModels = 'provider_models_';
  static const models = 'catalog_provider_models_';
  static const discoveryAt = 'catalog_discovered_at_';
  static const cacheVersionKey = 'catalog_cache_version';
}

/// Centralized catalog service for AI providers and models.
///
/// Manages built-in provider definitions, user settings (enabled/disabled,
/// API keys, custom base URLs), and provides lookup methods for models
/// and providers. All mutable state is persisted via SharedPreferences and
/// SecureStorage.
class ProviderCatalogService {
  final SecureStorageService _secureStorage;
  SharedPreferences _prefs;

  /// Built-in provider configurations.
  /// These are the default providers shipped with the app.
  final List<ProviderConfig> _builtInProviders;

  /// Cached list of all providers (built-in + custom).
  List<ProviderConfig> _providers = [];

  /// Whether migration from legacy settings has been performed.
  bool _migrated = false;

  /// Map of provider ID to set of selected model IDs.
  /// This is the unified source of truth for which models are selected
  /// for each provider.
  final Map<String, Set<String>> _selectedModelIds = {};

  /// Cache for API keys to avoid repeated SecureStorage reads.
  final Map<String, String?> _apiKeyCache = {};

  /// Discovery timestamps (ms since epoch). null = never discovered.
  final Map<String, int?> _discoveryTimestamps = {};

  /// How long discovered models stay valid before re-fetch.
  final Duration cacheDuration;

  /// Create the catalog service with the given built-in providers.
  ///
  /// [builtInProviders] should be the list from [builtInProviders()] in
  /// [providers/built_in_providers.dart]. Custom providers are persisted separately.
  ProviderCatalogService({
    required SecureStorageService secureStorage,
    required SharedPreferences prefs,
    List<ProviderConfig> builtInProviders = const [],
    this.cacheDuration = const Duration(hours: 24),
  }) : _secureStorage = secureStorage,
       _prefs = prefs,
       _builtInProviders = builtInProviders {
    _providers = List.of(_builtInProviders);
    _loadFromPrefs();
  }

  /// Update the SharedPreferences instance (for async initialization).
  void updatePrefs(SharedPreferences prefs) {
    _prefs = prefs;
    _loadFromPrefs();
  }

  /// Preload all API keys from SecureStorage into the in-memory cache.
  ///
  /// Must be called once after initialization (or after migration) so that
  /// [getApiKeySync] returns correct values for all providers on startup.
  /// Without this, [configuredProvidersProvider] cannot detect providers that
  /// have API keys stored from previous sessions.
  Future<void> preloadApiKeys() async {
    // Read every provider's secure key concurrently instead of sequentially,
    // so startup is bounded by the single slowest read rather than the sum.
    await Future.wait(
      _providers.map((p) async {
        if (_apiKeyCache.containsKey(p.id)) return;
        final key = await _secureStorage.read(
          key: '${_PrefKeys.apiKey}${p.id}',
        );
        if (key != null && key.isNotEmpty) {
          _apiKeyCache[p.id] = key;
        }
      }),
    );
    await _migrateProviderEnabled();
  }

  /// Migration helper: enables providers that were configured before the
  /// `isProviderEnabled` default changed from `true` to `false`.
  ///
  /// Runs once after [preloadApiKeys]. A provider is considered configured
  /// if it has an API key, selected model IDs, or a custom base URL.
  Future<void> _migrateProviderEnabled() async {
    if (_prefs.getBool('_catalog_enabled_migration_v3') == true) return;

    for (final provider in _providers) {
      final hasKey = getApiKeySync(provider.id) != null;
      final hasSelectedIds = getSelectedModelIds(provider.id).isNotEmpty;
      final hasCustomUrl = getCustomBaseUrl(provider.id) != null;
      if (hasKey || hasSelectedIds || hasCustomUrl) {
        await setProviderEnabled(provider.id, true);
      }
    }

    await _prefs.setBool('_catalog_enabled_migration_v3', true);
  }

  /// Discover models from a provider's `/models` endpoint and persist them.
  ///
  /// Returns the list of discovered [ModelConfig] or empty list on error.
  /// Results are cached for 24 hours. Call with [forceRefresh]=true to bypass.
  Future<List<ModelConfig>> discoverModels(
    String providerId, {
    bool forceRefresh = false,
  }) async {
    final provider = getProvider(providerId);
    if (provider == null) return const [];

    // Return cached models if fresh (< 24h)
    if (!forceRefresh) {
      final ts = _discoveryTimestamps[providerId];
      if (ts != null &&
          DateTime.now().millisecondsSinceEpoch - ts <
              cacheDuration.inMilliseconds) {
        LogTags.network.logDebug(
          '[Catalog] discoverModels: cache hit for $providerId (${provider.models.length} models)',
        );
        return provider.models;
      }
    }

    final baseUrl = getCustomBaseUrl(providerId) ?? provider.baseUrl;
    final storedKey = await getApiKey(providerId);
    final apiKey = storedKey ?? provider.auth.apiKey;

    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    headers.addAll(provider.defaultHeaders);

    try {
      LogTags.network.logInfo(
        '[Catalog] discoverModels: provider=$providerId baseUrl=$baseUrl apiKeyPresent=${apiKey != null && apiKey.isNotEmpty}',
      );
      final dio = Dio(BaseOptions(baseUrl: baseUrl, headers: headers));
      final resp = await dio.get('/models');
      LogTags.network.logDebug(
        '[Catalog] discoverModels: response status=${resp.statusCode}',
      );
      final data = resp.data;
      List<dynamic> items = [];
      if (data is Map && data.containsKey('data')) {
        items = data['data'] as List<dynamic>;
      } else if (data is List) {
        items = data;
      } else if (data is Map &&
          data.containsKey('id') &&
          !data.containsKey('data')) {
        // Single-model response (e.g. Venice AI): {id, context_length, model_spec: {...}, ...}
        items = [data as Map<String, dynamic>];
      }

      LogTags.network.logDebug(
        '[Catalog] discoverModels: items found=${items.length} for provider=$providerId',
      );

      final models = items.whereType<Map<String, dynamic>>().map((m) {
        // Handle non-standard single-object responses (e.g. Venice AI)
        final modelSpec = m['model_spec'] as Map<String, dynamic>? ?? {};
        final modelName =
            (m['id'] ?? modelSpec['name'] ?? m['name'] ?? '') as String;

        final source = modelSpec.isNotEmpty ? modelSpec : m;
        final architecture =
            source['architecture'] as Map<String, dynamic>? ??
            m['architecture'] as Map<String, dynamic>?;
        final inputModalities =
            (architecture?['input_modalities'] as List<dynamic>?) ?? [];
        final supportedParams =
            (source['supported_parameters'] as List<dynamic>?) ??
            (m['supported_parameters'] as List<dynamic>?) ??
            [];
        final hasTools =
            supportedParams.contains('tools') ||
            supportedParams.contains('tool_choice');
        final hasReasoning =
            supportedParams.contains('reasoning') ||
            supportedParams.contains('include_reasoning');
        final isMultimodal = inputModalities.contains('image');
        final hasVision = inputModalities.contains('image');
        final display =
            (m['name'] ?? modelSpec['name'] ?? modelName) as String? ??
            modelName;

        double? toDouble(dynamic value) {
          if (value == null) return null;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value);
          return null;
        }

        final pricingRaw =
            (source['pricing'] as Map<String, dynamic>?) ??
            (m['pricing'] as Map<String, dynamic>?);
        final promptPrice =
            toDouble(pricingRaw?['prompt']) ??
            toDouble(pricingRaw?['input']) ??
            toDouble(pricingRaw?['input_cost_per_token']) ??
            toDouble((pricingRaw?['input'] as Map?)?['usd']);
        final completionPrice =
            toDouble(pricingRaw?['completion']) ??
            toDouble(pricingRaw?['output']) ??
            toDouble(pricingRaw?['output_cost_per_token']) ??
            toDouble((pricingRaw?['output'] as Map?)?['usd']);
        final modelPricing = (promptPrice != null || completionPrice != null)
            ? ModelPricing(
                inputCostPer1k: promptPrice ?? 0.0,
                outputCostPer1k: completionPrice ?? 0.0,
              )
            : null;

        final defaultParams =
            source['default_parameters'] as Map<String, dynamic>?;
        final apiDefaultTemperature = defaultParams != null
            ? toDouble(defaultParams['temperature'])
            : null;

        return ModelConfig.basic(
          providerId: providerId,
          modelName: modelName,
          displayName: display,
          description: _stripTruncation(
            (source['description'] as String?) ??
                (m['description'] as String?) ??
                '',
          ),
          capabilities: ModelCapabilities(
            reasoning: hasReasoning,
            multimodal: isMultimodal,
            vision: hasVision,
            tools: hasTools,
          ),
          contextLength: (m['context_length'] is int)
              ? (m['context_length'] as int)
              : 0,
          pricing: modelPricing,
          defaultTemperature: apiDefaultTemperature,
          enabled: true,
        );
      }).toList();

      if (models.isNotEmpty) {
        LogTags.network.logInfo(
          '[Catalog] discoverModels: discovered ${models.length} models for provider=$providerId',
        );
        await updateProviderModels(providerId, models);
        await _saveDiscoveryTimestamp(providerId);
      } else {
        LogTags.network.logInfo(
          '[Catalog] discoverModels: no models discovered for provider=$providerId',
        );
      }
      return models;
    } catch (e, st) {
      LogTags.network.logError(
        '[Catalog] discoverModels: failed for provider=$providerId',
        e,
        st,
      );
      return const [];
    }
  }

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Get all providers (built-in + custom).
  List<ProviderConfig> getAllProviders() =>
      List.unmodifiable(_providers.where((p) => p.enabled));

  /// Get all providers regardless of enabled status.
  List<ProviderConfig> getAllProvidersRaw() => List.unmodifiable(_providers);

  /// Get a provider by ID.
  ProviderConfig? getProvider(String id) {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all models across all enabled providers.
  List<ModelConfig> getAllModels() {
    final models = <ModelConfig>[];
    for (final provider in _providers) {
      if (provider.enabled) {
        models.addAll(provider.models);
      }
    }
    return models;
  }

  /// Get all models across all providers (regardless of enabled).
  List<ModelConfig> getAllModelsRaw() {
    final models = <ModelConfig>[];
    for (final provider in _providers) {
      models.addAll(provider.models);
    }
    return models;
  }

  /// Get a model by its full ID (format: 'providerId/modelName').
  ///
  /// the provider prefix to avoid ambiguity.
  ///
  /// Returns null if provider not found or model not in that provider.
  ModelConfig? getModel(String modelId) {
    if (modelId.contains('/')) {
      final parts = modelId.split('/');
      if (parts.length >= 2) {
        final providerId = parts[0];
        final modelName = parts.sublist(1).join('/');
        final provider = getProvider(providerId);
        return provider?.getModel(modelName);
      }
    }

    // Invalid format: model ID must include provider prefix.
    return null;
  }

  /// Update the cached model list for a provider and persist it.
  ///
  /// [overwriteEnabled] when true, uses the `enabled` value from [models]
  /// instead of preserving existing flags. Set to true when saving user
  /// selection from the dialog; leave false when merging API results.
  Future<void> updateProviderModels(
    String providerId,
    List<ModelConfig> models, {
    bool overwriteEnabled = false,
  }) async {
    final provider = getProvider(providerId);
    if (provider == null) return;

    final existingById = {
      for (final m in provider.models) '$providerId/${m.modelName}': m,
    };

    final merged = models.map((m) {
      final key = '$providerId/${m.modelName}';
      final existing = existingById[key];
      return m.copyWith(
        providerId: providerId,
        enabled: overwriteEnabled
            ? m.enabled
            : (existing?.enabled ?? m.enabled),
      );
    }).toList();

    _updateProviderInCache(providerId, (p) => p.copyWith(models: merged));

    try {
      final key = '${_PrefKeys.models}$providerId';
      final jsonList = merged.map((m) => m.toJson()).toList();
      await _prefs.setString(key, jsonEncode(jsonList));
    } catch (_) {
      // ignore persistence errors
    }
  }

  /// Get API key for a provider from secure storage (with caching).
  Future<String?> getApiKey(String providerId) async {
    if (_apiKeyCache.containsKey(providerId)) {
      final key = _apiKeyCache[providerId];
      LogTags.network.logDebug(
        '[Catalog] getApiKey: provider=$providerId cached=true length=${key?.length ?? -1}',
      );
      return key;
    }
    final key = await _secureStorage.read(
      key: '${_PrefKeys.apiKey}$providerId',
    );
    _apiKeyCache[providerId] = key;
    LogTags.network.logDebug(
      '[Catalog] getApiKey: provider=$providerId cached=false length=${key?.length ?? -1}',
    );
    return key;
  }

  /// Get API key synchronously from cache (may be null if not loaded yet).
  String? getApiKeySync(String providerId) => _apiKeyCache[providerId];

  /// Set API key for a provider in secure storage.
  ///
  /// Config providers are read-only — their key is resolved in memory from
  /// `chatorai.json` (`{env:VAR}`) and must never be written to secure storage.
  Future<void> setApiKey(String providerId, String apiKey) async {
    if (getProvider(providerId)?.isConfig ?? false) return;
    await _secureStorage.write(
      key: '${_PrefKeys.apiKey}$providerId',
      value: apiKey,
    );
    _apiKeyCache[providerId] = apiKey;
  }

  /// Delete API key for a provider.
  Future<void> deleteApiKey(String providerId) async {
    if (getProvider(providerId)?.isConfig ?? false) return;
    await _secureStorage.delete(key: '${_PrefKeys.apiKey}$providerId');
    _apiKeyCache.remove(providerId);
  }

  /// Check if a provider is enabled.
  bool isProviderEnabled(String providerId) {
    return _prefs.getBool('${_PrefKeys.enabled}$providerId') ?? false;
  }

  /// Set whether a provider is enabled.
  ///
  /// Config providers are read-only; their enabled flag is controlled solely
  /// by `chatorai.json`, so this is a no-op for them.
  Future<void> setProviderEnabled(String providerId, bool enabled) async {
    if (getProvider(providerId)?.isConfig ?? false) return;
    await _prefs.setBool('${_PrefKeys.enabled}$providerId', enabled);
    _updateProviderInCache(providerId, (p) => p.copyWith(enabled: enabled));
  }

  /// Get custom base URL for a provider (if overridden).
  String? getCustomBaseUrl(String providerId) {
    return _prefs.getString('${_PrefKeys.baseUrl}$providerId');
  }

  /// Set custom base URL for a provider.
  ///
  /// Config providers are read-only; base URL comes from `chatorai.json`.
  Future<void> setCustomBaseUrl(String providerId, String baseUrl) async {
    if (getProvider(providerId)?.isConfig ?? false) return;
    await _prefs.setString('${_PrefKeys.baseUrl}$providerId', baseUrl);
  }

  /// Add a custom (user-defined) provider.
  ///
  /// Config providers (injected from `chatorai.json`) are read-only and must
  /// never be re-added here — ignore the call to preserve the read-only
  /// guarantee.
  void addCustomProvider(ProviderConfig provider) {
    if (provider.isConfig) return;
    // Remove existing with same ID if present
    _providers.removeWhere((p) => p.id == provider.id);
    _providers.add(provider);
    _saveCustomProviders();
  }

  /// Remove a custom provider.
  ///
  /// Config providers are read-only and must not be removed through this path.
  void removeCustomProvider(String providerId) {
    final provider = _providers.cast<ProviderConfig?>().firstWhere(
      (p) => p?.id == providerId,
      orElse: () => null,
    );
    if (provider?.isConfig ?? false) return;
    _providers.removeWhere((p) => p.id == providerId);
    _saveCustomProviders();
  }

  /// Apply providers declared in `chatorai.json` on top of the current catalog.
  ///
  /// Config providers are read-only: they are not persisted to
  /// SharedPreferences/SecureStorage. A config provider with the same ID as an
  /// existing provider (built-in or custom) overrides it, so the user config
  /// always wins.
  ///
  /// [providers] is the parsed list from [ConfigProviderParser.parse].
  void applyConfigProviders(List<ProviderConfig> providers) {
    for (final provider in providers) {
      _providers.removeWhere((p) => p.id == provider.id);
      _providers.add(provider);
    }
  }

  /// Get the default model (first enabled model, or null).
  ModelConfig? get defaultModel {
    final models = getAllModels();
    return models.isNotEmpty ? models.first : null;
  }

  /// Get the list of selected model IDs for a provider.
  List<String> getSelectedModelIds(String providerId) =>
      List.unmodifiable(_selectedModelIds[providerId] ?? []);

  /// Set the selected model IDs for a provider and persist them.
  Future<void> setSelectedModelIds(
    String providerId,
    List<String> modelIds,
  ) async {
    _selectedModelIds[providerId] = modelIds.toSet();
    final key = '${_PrefKeys.selectedModels}$providerId';
    LogTags.settings.logInfo(
      '[Catalog] setSelectedModelIds: provider=$providerId '
      'count=${modelIds.length} ids=[${modelIds.join(',')}] key=$key',
    );
    await _prefs.setStringList(key, modelIds);
    LogTags.settings.logInfo(
      '[Catalog] setSelectedModelIds: persisted OK, verifying read-back...',
    );
    final verify = _prefs.getStringList(key);
    LogTags.settings.logInfo(
      '[Catalog] setSelectedModelIds: read-back=${verify?.length ?? 0} ids=[${verify?.join(',') ?? ''}]',
    );
  }

  /// Clear the selected model IDs for a provider.
  Future<void> clearSelectedModelIds(String providerId) async {
    _selectedModelIds.remove(providerId);
    await _prefs.remove('${_PrefKeys.selectedModels}$providerId');
  }

  /// Migrate settings from legacy SharedPreferences keys.
  Future<void> migrateFromLegacySettings() async {
    if (_migrated) return;
    _migrated = true;

    final keys = _prefs.getKeys();
    final migratedIds = <String>{};

    for (final key in keys) {
      if (key.startsWith(_PrefKeys.legacyEnabled)) {
        final id = key.substring(_PrefKeys.legacyEnabled.length);
        migratedIds.add(id);
        final enabled = _prefs.getBool(key) ?? false;
        // Only write if not already set in new format
        if (!_prefs.containsKey('${_PrefKeys.enabled}$id')) {
          await _prefs.setBool('${_PrefKeys.enabled}$id', enabled);
        }
      }
    }

    // Migrate API keys from legacy SharedPreferences to SecureStorage
    for (final id in migratedIds) {
      final legacyApiKey = _prefs.getString('${_PrefKeys.legacyApiKey}$id');
      if (legacyApiKey != null) {
        final newKey = '${_PrefKeys.apiKey}$id';
        final existing = await _secureStorage.read(key: newKey);
        if (existing == null) {
          await _secureStorage.write(key: newKey, value: legacyApiKey);
        }
        await _prefs.remove('${_PrefKeys.legacyApiKey}$id');
      }

      // Migrate base URL
      final legacyBaseUrl = _prefs.getString('${_PrefKeys.legacyBaseUrl}$id');
      if (legacyBaseUrl != null) {
        if (!_prefs.containsKey('${_PrefKeys.baseUrl}$id')) {
          await _prefs.setString('${_PrefKeys.baseUrl}$id', legacyBaseUrl);
        }
      }

      // Migrate selected model IDs from legacy format to new format
      final legacyModelsKey = '${_PrefKeys.legacySelectedModels}$id';
      final legacyModelIds = _prefs.getStringList(legacyModelsKey);
      if (legacyModelIds != null && legacyModelIds.isNotEmpty) {
        final newKey = '${_PrefKeys.selectedModels}$id';
        if (!_prefs.containsKey(newKey)) {
          await _prefs.setStringList(newKey, legacyModelIds);
          _selectedModelIds[id] = legacyModelIds.toSet();
        }
      }
    }

    // _selectedModelIds is already updated in-memory during migration;
    // constructor already called _loadFromPrefs, no reload needed.
  }

  // ===========================================================================
  // INTERNAL
  // ===========================================================================

  /// Matches trailing truncation markers (e.g. "..." from OpenRouter-style
  /// 512-char description caps). Compiled once, not per call.
  static final RegExp _truncationPattern = RegExp(r'\.\.\..*$');

  /// Remove provider-side truncation markers (e.g. trailing "..." from
  /// OpenRouter-style 512-char description caps).
  static String _stripTruncation(String desc) {
    final trimmed = desc.trimRight();
    final cleaned = trimmed.replaceAll(_truncationPattern, '').trimRight();
    return cleaned;
  }

  /// Load provider state from SharedPreferences.
  void _loadFromPrefs() {
    // Cache schema v1 → v2: old code used ModelCapabilities.basic()
    // which set only tools=true. Clear all cached models so
    // discoverModels() re-populates with proper capabilities.
    final cacheVersion = _prefs.getInt(_PrefKeys.cacheVersionKey) ?? 0;
    if (cacheVersion < 5) {
      LogTags.network.logInfo(
        '[Catalog] Cache invalidated (v$cacheVersion→5), re-discovery required',
      );
      for (final prov in _builtInProviders) {
        _prefs.remove('${_PrefKeys.models}${prov.id}');
        _prefs.remove('${_PrefKeys.discoveryAt}${prov.id}');
      }
      _prefs.setInt(_PrefKeys.cacheVersionKey, 5);
    }

    _providers = _builtInProviders.map((provider) {
      final enabled = _prefs.getBool('${_PrefKeys.enabled}${provider.id}');
      return provider.copyWith(enabled: enabled ?? false);
    }).toList();

    // Load custom providers from stored JSON
    final customJson = _prefs.getString('catalog_custom_providers');
    if (customJson != null) {
      try {
        final decoded = jsonDecode(customJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            // Backward-compat: providers persisted before the `source` field
            // existed deserialize as builtIn; tag them as custom so they stay
            // editable and are never confused with config-injected providers.
            final parsed = ProviderConfig.fromJson(item);
            _providers.add(
              parsed.source == ProviderSource.custom
                  ? parsed
                  : parsed.copyWith(source: ProviderSource.custom),
            );
          }
        }
      } catch (_) {
        // If deserialization fails, skip custom providers
      }
    }

    // Load per-provider cached models (if any) and merge into providers.
    for (var i = 0; i < _providers.length; i++) {
      final prov = _providers[i];
      final key = '${_PrefKeys.models}${prov.id}';
      final modelsJson = _prefs.getString(key);
      if (modelsJson != null) {
        try {
          final decoded = jsonDecode(modelsJson) as List<dynamic>;
          final models = decoded
              .whereType<Map<String, dynamic>>()
              .map((m) => ModelConfig.fromJson(m))
              .toList();
          _providers[i] = prov.copyWith(models: models);

          if (models.any((m) => (m.description ?? '').endsWith('...'))) {
            final sanitized = models
                .map(
                  (m) => m.copyWith(
                    description: _stripTruncation(m.description ?? ''),
                  ),
                )
                .toList();
            _providers[i] = _providers[i].copyWith(models: sanitized);
          }
        } catch (e) {
          LogTags.settings.logWarning(
            '[Catalog] _loadFromPrefs: failed to load cached models for ${prov.id}: $e',
          );
        }
      }

      // Load selected model IDs for this provider
      final selectedIds = _prefs.getStringList(
        '${_PrefKeys.selectedModels}${prov.id}',
      );
      if (selectedIds != null && selectedIds.isNotEmpty) {
        _selectedModelIds[prov.id] = selectedIds.toSet();
      }
    }

    // Summarize selected-model coverage in a single debug log instead of
    // per-provider info logs (which produced ~40 log lines on every startup).
    final withSelection = _selectedModelIds.keys.length;
    final withoutSelection = _providers.length - withSelection;
    LogTags.settings.logDebug(
      '[Catalog] _loadFromPrefs: selected models loaded for $withSelection providers, '
      '$withoutSelection without selection (total=${_providers.length})',
    );

    // Load discovery timestamps
    for (final prov in _providers) {
      final ts = _prefs.getInt('${_PrefKeys.discoveryAt}${prov.id}');
      if (ts != null) _discoveryTimestamps[prov.id] = ts;
    }
  }

  /// Save custom providers to SharedPreferences as JSON.
  ///
  /// Config providers (source == [ProviderSource.config]) are never persisted —
  /// they live read-only in memory and are re-injected from `chatorai.json`
  /// on each startup.
  void _saveCustomProviders() {
    final customProviders = _providers
        .where(
          (p) =>
              p.source != ProviderSource.config &&
              !_builtInProviders.any((b) => b.id == p.id),
        )
        .toList();
    final jsonList = customProviders.map((p) => p.toJson()).toList();
    _prefs.setString('catalog_custom_providers', jsonEncode(jsonList));
  }

  /// Persist discovery timestamp after successful model fetch.
  Future<void> _saveDiscoveryTimestamp(String providerId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _discoveryTimestamps[providerId] = now;
    await _prefs.setInt('${_PrefKeys.discoveryAt}$providerId', now);
  }

  /// Update a provider in the in-memory cache.
  void _updateProviderInCache(
    String providerId,
    ProviderConfig Function(ProviderConfig) update,
  ) {
    final index = _providers.indexWhere((p) => p.id == providerId);
    if (index >= 0) {
      _providers[index] = update(_providers[index]);
    }
  }
}
