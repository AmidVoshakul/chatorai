import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/features/settings/data/models/model_settings.dart';
import 'package:chatorai/shared/utils/logger.dart';

final _logger = LogTags.settings;

class ModelSettingsState {
  final Map<String, ModelSettings> settingsCache;
  final ModelSettings? activeSettings;
  final bool isLoading;

  const ModelSettingsState({
    this.settingsCache = const {},
    this.activeSettings,
    this.isLoading = false,
  });

  ModelSettingsState copyWith({
    Map<String, ModelSettings>? settingsCache,
    ModelSettings? activeSettings,
    bool? isLoading,
    bool clearActiveSettings = false,
  }) {
    return ModelSettingsState(
      settingsCache: settingsCache ?? this.settingsCache,
      activeSettings: clearActiveSettings
          ? null
          : (activeSettings ?? this.activeSettings),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ModelSettingsNotifier extends Notifier<ModelSettingsState> {
  static const String _settingsPrefix = 'model_settings_';

  @override
  ModelSettingsState build() {
    _logger.logInfo('[ModelSettingsNotifier] Initialized');
    return const ModelSettingsState();
  }

  Future<void> _loadSettingsAsync(String modelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      final jsonString = prefs.getString(key);

      double? catalogDefaultTemp;
      try {
        final catalog = ref.read(providerCatalogServiceProvider);
        catalogDefaultTemp = catalog.getModel(modelId)?.defaultTemperature;
      } catch (_) {}

      ModelSettings settings;
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
          settings = ModelSettings.fromJson(jsonMap);
        } catch (e) {
          settings = ModelSettings.defaultForModel(
            modelId,
            defaultTemperature: catalogDefaultTemp,
          );
        }
      } else {
        settings = ModelSettings.defaultForModel(
          modelId,
          defaultTemperature: catalogDefaultTemp,
        );
      }

      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[modelId] = settings;

      state = state.copyWith(
        settingsCache: newCache,
        activeSettings: settings,
        isLoading: false,
      );

      _logger.logInfo('[ModelSettingsNotifier] Loaded settings for $modelId');
    } catch (e) {
      _logger.logError(
        '[ModelSettingsNotifier] Error loading settings for $modelId: $e',
      );
      final defaultSettings = ModelSettings.defaultForModel(modelId);
      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[modelId] = defaultSettings;
      state = state.copyWith(settingsCache: newCache, isLoading: false);
    }
  }

  Future<void> loadSettings(String modelId) async {
    if (state.settingsCache.containsKey(modelId)) {
      return;
    }

    state = state.copyWith(isLoading: true);
    await _loadSettingsAsync(modelId);
  }

  Future<void> saveSettings(ModelSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix${settings.modelId}';
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(key, jsonString);

      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[settings.modelId] = settings;

      ModelSettings? activeSettings = state.activeSettings;
      if (activeSettings?.modelId == settings.modelId) {
        activeSettings = settings;
      }

      state = state.copyWith(
        settingsCache: newCache,
        activeSettings: activeSettings,
      );

      _logger.logInfo(
        '[ModelSettingsNotifier] Saved settings for ${settings.modelId}',
      );
    } catch (e) {
      _logger.logError('[ModelSettingsNotifier] Error saving settings: $e');
      rethrow;
    }
  }

  Future<void> setActiveModel(String modelId) async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      final jsonString = prefs.getString(key);

      double? catalogDefaultTemp;
      try {
        final catalog = ref.read(providerCatalogServiceProvider);
        catalogDefaultTemp = catalog.getModel(modelId)?.defaultTemperature;
      } catch (_) {}

      ModelSettings settings;
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        settings = ModelSettings.fromJson(jsonMap);
      } else {
        settings = ModelSettings.defaultForModel(
          modelId,
          defaultTemperature: catalogDefaultTemp,
        );
      }

      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[modelId] = settings;

      state = state.copyWith(
        settingsCache: newCache,
        activeSettings: settings,
        isLoading: false,
      );

      _logger.logInfo(
        '[ModelSettingsNotifier] Active model set to $modelId with settings: $settings',
      );
    } catch (e) {
      _logger.logError(
        '[ModelSettingsNotifier] Error setting active model: $e',
      );
      final defaultSettings = ModelSettings.defaultForModel(modelId);
      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[modelId] = defaultSettings;
      state = state.copyWith(
        settingsCache: newCache,
        activeSettings: defaultSettings,
        isLoading: false,
      );
    }
  }

  Future<void> updateActiveSettings(ModelSettings settings) async {
    state = state.copyWith(activeSettings: settings);
    await saveSettings(settings);
  }

  Future<void> updateActiveParameter({
    double? temperature,
    String? systemPrompt,
    bool? stream,
    bool? reasoningEnabled,
  }) async {
    if (state.activeSettings == null) {
      _logger.logWarning('[ModelSettingsNotifier] No active model to update');
      return;
    }

    final updated = state.activeSettings!.copyWith(
      temperature: temperature,
      systemPrompt: systemPrompt,
      stream: stream,
      reasoningEnabled: reasoningEnabled,
    );

    await updateActiveSettings(updated);
  }

  Future<ModelSettings> getSettings(String modelId) async {
    if (state.settingsCache.containsKey(modelId)) {
      return state.settingsCache[modelId]!;
    }
    await _loadSettingsAsync(modelId);
    return state.settingsCache[modelId] ??
        ModelSettings.defaultForModel(modelId);
  }

  Future<void> deleteSettings(String modelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      await prefs.remove(key);

      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache.remove(modelId);

      ModelSettings? activeSettings = state.activeSettings;
      if (activeSettings?.modelId == modelId) {
        activeSettings = null;
      }

      state = state.copyWith(
        settingsCache: newCache,
        clearActiveSettings: activeSettings == null,
      );

      _logger.logInfo('[ModelSettingsNotifier] Deleted settings for $modelId');
    } catch (e) {
      _logger.logError('[ModelSettingsNotifier] Error deleting settings: $e');
    }
  }

  Future<void> resetSettings(String modelId) async {
    double? catalogDefaultTemp;
    try {
      final catalog = ref.read(providerCatalogServiceProvider);
      catalogDefaultTemp = catalog.getModel(modelId)?.defaultTemperature;
    } catch (_) {}

    final defaultSettings = ModelSettings.defaultForModel(
      modelId,
      defaultTemperature: catalogDefaultTemp,
    );
    await saveSettings(defaultSettings);

    if (state.activeSettings?.modelId == modelId) {
      state = state.copyWith(activeSettings: defaultSettings);
    }

    _logger.logInfo(
      '[ModelSettingsNotifier] Reset settings for $modelId'
      ' to defaultTemperature=$catalogDefaultTemp',
    );
  }

  Future<void> resetActiveSettings() async {
    if (state.activeSettings == null) return;
    await resetSettings(state.activeSettings!.modelId);
  }

  Future<void> clearAll() async {
    final newCache = <String, ModelSettings>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_settingsPrefix)) {
          await prefs.remove(key);
        }
      }
      _logger.logInfo('[ModelSettingsNotifier] Cleared all model settings');
      state = state.copyWith(
        settingsCache: newCache,
        clearActiveSettings: true,
      );
    } catch (e) {
      _logger.logError(
        '[ModelSettingsNotifier] Error clearing all settings: $e',
      );
    }
  }
}

final modelSettingsProvider =
    NotifierProvider<ModelSettingsNotifier, ModelSettingsState>(
      ModelSettingsNotifier.new,
    );
