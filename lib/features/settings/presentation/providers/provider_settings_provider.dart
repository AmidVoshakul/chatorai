import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/features/chat/data/models/provider_settings.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';

final _logger = LogTags.settings;

// =============================================================================
// STATE
// =============================================================================

class ProviderSettingsState {
  final Map<String, ProviderSettings> providers;
  final bool isLoading;

  const ProviderSettingsState({
    this.providers = const {},
    this.isLoading = false,
  });

  /// Convenience getter for a single provider's settings (defaults to empty).
  ProviderSettings getSettings(String id) =>
      providers[id] ?? const ProviderSettings();

  ProviderSettingsState copyWith({
    Map<String, ProviderSettings>? providers,
    bool? isLoading,
  }) {
    return ProviderSettingsState(
      providers: providers ?? this.providers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// =============================================================================
// NOTIFIER
// =============================================================================

class ProviderSettingsNotifier extends Notifier<ProviderSettingsState> {
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  ProviderSettingsState build() {
    _loadAll();
    return const ProviderSettingsState(isLoading: true);
  }

  // ---------------------------------------------------------------------------
  // SharedPreferences helpers (for non-sensitive settings)
  // ---------------------------------------------------------------------------

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String _enabledKey(String id) => 'provider_enabled_$id';
  String _apiKeyKey(String id) => 'provider_api_key_$id';
  String _baseUrlKey(String id) => 'provider_base_url_$id';
  String _modelsKey(String id) => 'provider_models_$id';

  // Get API key from secure storage, migrating from SharedPreferences if needed
  Future<String?> _getOrMigrateApiKey(
    String id,
    SharedPreferences prefs,
  ) async {
    final secureKey = await _secureStorage.read(key: _apiKeyKey(id));
    if (secureKey != null) return secureKey;

    // Migrate from SharedPreferences (legacy)
    final legacyKey = prefs.getString(_apiKeyKey(id));
    if (legacyKey != null) {
      await _secureStorage.write(key: _apiKeyKey(id), value: legacyKey);
      await prefs.remove(_apiKeyKey(id));
      _logger.logInfo(
        '[ProviderSettings] Migrated API key for $id to secure storage',
      );
      return legacyKey;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> _loadAll() async {
    try {
      final prefs = await _prefs;
      // We discover configured providers via SharedPreferences keys with
      // the prefix "provider_enabled_".
      final keys = prefs.getKeys();
      final providerIds = <String>{};
      for (final key in keys) {
        if (key.startsWith('provider_enabled_')) {
          providerIds.add(key.substring('provider_enabled_'.length));
        }
      }

      final map = <String, ProviderSettings>{};
      for (final id in providerIds) {
        final enabled = prefs.getBool(_enabledKey(id)) ?? false;
        // API key from secure storage (with migration fallback)
        final apiKey = await _getOrMigrateApiKey(id, prefs);
        final baseUrl = prefs.getString(_baseUrlKey(id));
        final selectedModelIds =
            prefs.getStringList(_modelsKey(id)) ?? <String>[];
        map[id] = ProviderSettings(
          enabled: enabled,
          apiKey: apiKey,
          baseUrl: baseUrl,
          selectedModelIds: selectedModelIds,
        );
      }

      state = ProviderSettingsState(providers: map, isLoading: false);
      _logger.logInfo('[ProviderSettings] Loaded ${map.length} providers');
    } catch (e) {
      _logger.logError('[ProviderSettings] Failed to load: $e');
      state = const ProviderSettingsState(isLoading: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> setProviderEnabled(String id, bool enabled) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(_enabledKey(id), enabled);

      final current = state.providers[id] ?? const ProviderSettings();
      final updated = current.copyWith(enabled: enabled);
      final newMap = Map<String, ProviderSettings>.from(state.providers);
      newMap[id] = updated;

      state = state.copyWith(providers: newMap);
      _logger.logInfo('[ProviderSettings] $id enabled=$enabled');
    } catch (e) {
      _logger.logError('[ProviderSettings] setProviderEnabled error: $e');
    }
  }

  Future<void> saveApiKey(String id, String apiKey) async {
    try {
      await _secureStorage.write(key: _apiKeyKey(id), value: apiKey);

      final current = state.providers[id] ?? const ProviderSettings();
      final updated = current.copyWith(apiKey: apiKey);
      final newMap = Map<String, ProviderSettings>.from(state.providers);
      newMap[id] = updated;

      state = state.copyWith(providers: newMap);
      _logger.logInfo('[ProviderSettings] API key saved for $id');
    } catch (e) {
      _logger.logError('[ProviderSettings] saveApiKey error: $e');
    }
  }

  Future<void> saveBaseUrl(String id, String baseUrl) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(_baseUrlKey(id), baseUrl);

      final current = state.providers[id] ?? const ProviderSettings();
      final updated = current.copyWith(baseUrl: baseUrl);
      final newMap = Map<String, ProviderSettings>.from(state.providers);
      newMap[id] = updated;

      state = state.copyWith(providers: newMap);
      _logger.logInfo('[ProviderSettings] Base URL saved for $id');
    } catch (e) {
      _logger.logError('[ProviderSettings] saveBaseUrl error: $e');
    }
  }

  Future<void> saveSelectedModelIds(String id, List<String> modelIds) async {
    try {
      final prefs = await _prefs;
      await prefs.setStringList(_modelsKey(id), modelIds);

      final current = state.providers[id] ?? const ProviderSettings();
      final updated = current.copyWith(selectedModelIds: modelIds);
      final newMap = Map<String, ProviderSettings>.from(state.providers);
      newMap[id] = updated;

      state = state.copyWith(providers: newMap);
      _logger.logInfo(
        '[ProviderSettings] ${modelIds.length} models saved for $id',
      );
    } catch (e) {
      _logger.logError('[ProviderSettings] saveSelectedModelIds error: $e');
    }
  }

  Future<void> deleteProvider(String id) async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_enabledKey(id));
      await _secureStorage.delete(key: _apiKeyKey(id)); // Secure delete
      await prefs.remove(_baseUrlKey(id));
      await prefs.remove(_modelsKey(id));

      final newMap = Map<String, ProviderSettings>.from(state.providers);
      newMap.remove(id);

      state = state.copyWith(providers: newMap);
      _logger.logInfo('[ProviderSettings] Deleted provider $id');
    } catch (e) {
      _logger.logError('[ProviderSettings] deleteProvider error: $e');
    }
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final providerSettingsProvider =
    NotifierProvider<ProviderSettingsNotifier, ProviderSettingsState>(
      ProviderSettingsNotifier.new,
    );
