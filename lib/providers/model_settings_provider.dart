import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/providers/model_provider.dart';

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

  ModelState get _modelState => ref.read(modelProvider);

  Future<ModelSettings> loadSettings(
    String modelId, [
    bool mounted = true,
  ]) async {
    if (state.settingsCache.containsKey(modelId)) {
      return state.settingsCache[modelId]!;
    }

    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      final jsonString = prefs.getString(key);

      ModelSettings settings;
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
          settings = ModelSettings.fromJson(jsonMap);

          if (settings.apiContextLength == null ||
              settings.apiMaxTokens == null) {
            final freshSettings = await _createSettingsFromModelInfo(modelId);

            settings = settings.copyWith(
              maxContextLength: freshSettings.maxContextLength,
              apiMaxTokens: freshSettings.apiMaxTokens,
              apiContextLength: freshSettings.apiContextLength,
              apiMaxTemperature: freshSettings.apiMaxTemperature,
              apiMinTemperature: freshSettings.apiMinTemperature,
            );

            await saveSettings(settings);
          }
        } catch (e) {
          settings = ModelSettings.defaultForModel(modelId);
        }
      } else {
        settings = await _createSettingsFromModelInfo(modelId);
      }

      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[modelId] = settings;

      state = state.copyWith(settingsCache: newCache, isLoading: false);

      _logger.logInfo(
        '[ModelSettingsNotifier] Loaded settings for $modelId: $settings',
      );

      return settings;
    } catch (e) {
      _logger.logError(
        '[ModelSettingsNotifier] Error loading settings for $modelId: $e',
      );
      final defaultSettings = ModelSettings.defaultForModel(modelId);

      final newCache = Map<String, ModelSettings>.from(state.settingsCache);
      newCache[modelId] = defaultSettings;

      state = state.copyWith(settingsCache: newCache, isLoading: false);
      return defaultSettings;
    }
  }

  Future<ModelSettings> _createSettingsFromModelInfo(String modelId) async {
    try {
      final model = _modelState.availableModels.firstWhere(
        (m) => m.id == modelId,
        orElse: () => throw Exception('Model not found'),
      );

      _logger.logInfo(
        '[ModelSettingsNotifier] Got model info from ModelProvider: ${model.name}, context: ${model.contextLength}',
      );

      final contextLength = model.contextLength ?? 4096;
      final safeMaxTokens = max(256, (contextLength * 0.7).floor());

      return ModelSettings.fromApiModel(modelId, contextLength, safeMaxTokens);
    } catch (e) {
      _logger.logWarning(
        '[ModelSettingsNotifier] Could not get model info: $e',
      );
      return ModelSettings.defaultForModel(modelId);
    }
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
    if (state.activeSettings?.modelId == modelId) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_settingsPrefix$modelId';
      final jsonString = prefs.getString(key);

      ModelSettings settings;
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        settings = ModelSettings.fromJson(jsonMap);

        if (settings.apiContextLength == null ||
            settings.apiMaxTokens == null) {
          final freshSettings = await _createSettingsFromModelInfo(modelId);

          settings = settings.copyWith(
            maxContextLength: freshSettings.maxContextLength,
            apiMaxTokens: freshSettings.apiMaxTokens,
            apiContextLength: freshSettings.apiContextLength,
            apiMaxTemperature: freshSettings.apiMaxTemperature,
            apiMinTemperature: freshSettings.apiMinTemperature,
          );

          await saveSettings(settings);
        }
      } else {
        settings = await _createSettingsFromModelInfo(modelId);
        await saveSettings(settings);
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
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String? systemPrompt,
    bool? stream,
    int? maxContextLength,
    bool? reasoningEnabled,
  }) async {
    if (state.activeSettings == null) {
      _logger.logWarning('[ModelSettingsNotifier] No active model to update');
      return;
    }

    final updated = state.activeSettings!.copyWith(
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      systemPrompt: systemPrompt,
      stream: stream,
      maxContextLength: maxContextLength,
      reasoningEnabled: reasoningEnabled,
    );

    await updateActiveSettings(updated);
  }

  Future<ModelSettings> getSettings(String modelId) async {
    return await loadSettings(modelId);
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
        activeSettings: activeSettings,
        clearActiveSettings: activeSettings == null,
      );

      _logger.logInfo('[ModelSettingsNotifier] Deleted settings for $modelId');
    } catch (e) {
      _logger.logError('[ModelSettingsNotifier] Error deleting settings: $e');
    }
  }

  Future<void> resetSettings(String modelId) async {
    final defaultSettings = ModelSettings.defaultForModel(modelId);
    await saveSettings(defaultSettings);

    if (state.activeSettings?.modelId == modelId) {
      state = state.copyWith(activeSettings: defaultSettings);
    }

    _logger.logInfo(
      '[ModelSettingsNotifier] Reset settings for $modelId to defaults',
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
