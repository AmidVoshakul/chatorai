import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/models/model_settings.dart';
import 'package:chatorai/providers/model_settings_provider.dart';

void main() {
  // Initialize Flutter binding for tests that use SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelSettings Tests', () {
    test('should create default settings for a model', () {
      final settings = ModelSettings.defaultForModel('test-model');
      
      expect(settings.modelId, 'test-model');
      expect(settings.temperature, 1.0);
      expect(settings.maxTokens, 4096);
      expect(settings.topP, 1.0);
      expect(settings.frequencyPenalty, 0.0);
      expect(settings.presencePenalty, 0.0);
      expect(settings.stream, true);
      expect(settings.systemPrompt, isNull);
    });

    test('should create settings from API model information', () {
      final settings = ModelSettings.fromApiModel('test-model', 8192, 4000);
      
      expect(settings.modelId, 'test-model');
      expect(settings.maxContextLength, 8192);
      expect(settings.apiContextLength, 8192);
      expect(settings.apiMaxTokens, 4000);
      expect(settings.temperature, 1.0); // Default
      expect(settings.maxTokens, 4000); // From API
      expect(settings.reasoningEnabled, true); // Default
    });

    test('should use 97% of context length when maxTokens not provided', () {
      final settings = ModelSettings.fromApiModel('test-model', 262144, null);
      
      // 262144 * 0.97 = 254279.68 -> 254279
      expect(settings.maxTokens, 254279);
      expect(settings.apiContextLength, 262144);
      expect(settings.apiMaxTokens, 262144);
    });

    test('should handle reasoningEnabled field', () {
      final settings = ModelSettings(
        modelId: 'test-model',
        reasoningEnabled: false,
      );
      
      expect(settings.reasoningEnabled, false);
      
      final settings2 = ModelSettings.defaultForModel('test-model');
      expect(settings2.reasoningEnabled, true);
    });

    test('should create settings with all parameters', () {
      final settings = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
        topP: 0.9,
        frequencyPenalty: 0.5,
        presencePenalty: 0.3,
        systemPrompt: 'You are helpful',
        stream: false,
        maxContextLength: 8192,
        apiMaxTokens: 4000,
        apiMaxTemperature: 2.0,
        apiMinTemperature: 0.0,
        apiContextLength: 8192,
      );
      
      expect(settings.temperature, 0.7);
      expect(settings.maxTokens, 2000);
      expect(settings.topP, 0.9);
      expect(settings.frequencyPenalty, 0.5);
      expect(settings.presencePenalty, 0.3);
      expect(settings.systemPrompt, 'You are helpful');
      expect(settings.stream, false);
      expect(settings.maxContextLength, 8192);
      expect(settings.apiMaxTokens, 4000);
      expect(settings.apiMaxTemperature, 2.0);
      expect(settings.apiMinTemperature, 0.0);
      expect(settings.apiContextLength, 8192);
    });

    test('copyWith should update specified fields', () {
      final original = ModelSettings.defaultForModel('test-model');
      final updated = original.copyWith(
        temperature: 0.5,
        maxTokens: 3000,
        systemPrompt: 'New prompt',
        reasoningEnabled: false,
      );
      
      expect(updated.modelId, 'test-model'); // Unchanged
      expect(updated.temperature, 0.5); // Changed
      expect(updated.maxTokens, 3000); // Changed
      expect(updated.systemPrompt, 'New prompt'); // Changed
      expect(updated.reasoningEnabled, false); // Changed
      expect(updated.topP, 1.0); // Unchanged
    });

    test('toJson should serialize correctly', () {
      final settings = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
        topP: 0.9,
        frequencyPenalty: 0.5,
        presencePenalty: 0.3,
        systemPrompt: 'You are helpful',
        stream: false,
        reasoningEnabled: false,
        maxContextLength: 8192,
        apiMaxTokens: 4000,
        apiMaxTemperature: 2.0,
        apiMinTemperature: 0.0,
        apiContextLength: 8192,
      );
      
      final json = settings.toJson();
      
      expect(json['modelId'], 'test-model');
      expect(json['temperature'], 0.7);
      expect(json['maxTokens'], 2000);
      expect(json['topP'], 0.9);
      expect(json['frequencyPenalty'], 0.5);
      expect(json['presencePenalty'], 0.3);
      expect(json['systemPrompt'], 'You are helpful');
      expect(json['reasoningEnabled'], false);
      expect(json['stream'], false);
      expect(json['maxContextLength'], 8192);
      expect(json['apiMaxTokens'], 4000);
      expect(json['apiMaxTemperature'], 2.0);
      expect(json['apiMinTemperature'], 0.0);
      expect(json['apiContextLength'], 8192);
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'modelId': 'test-model',
        'temperature': 0.7,
        'maxTokens': 2000,
        'topP': 0.9,
        'frequencyPenalty': 0.5,
        'presencePenalty': 0.3,
        'systemPrompt': 'You are helpful',
        'stream': false,
        'reasoningEnabled': false,
        'maxContextLength': 8192,
        'apiMaxTokens': 4000,
        'apiMaxTemperature': 2.0,
        'apiMinTemperature': 0.0,
        'apiContextLength': 8192,
      };
      
      final settings = ModelSettings.fromJson(json);
      
      expect(settings.modelId, 'test-model');
      expect(settings.temperature, 0.7);
      expect(settings.maxTokens, 2000);
      expect(settings.topP, 0.9);
      expect(settings.frequencyPenalty, 0.5);
      expect(settings.presencePenalty, 0.3);
      expect(settings.systemPrompt, 'You are helpful');
      expect(settings.stream, false);
      expect(settings.reasoningEnabled, false);
      expect(settings.maxContextLength, 8192);
      expect(settings.apiMaxTokens, 4000);
      expect(settings.apiMaxTemperature, 2.0);
      expect(settings.apiMinTemperature, 0.0);
      expect(settings.apiContextLength, 8192);
    });

    test('equality should work correctly', () {
      final settings1 = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
      );
      
      final settings2 = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
      );
      
      final settings3 = ModelSettings(
        modelId: 'test-model',
        temperature: 0.8, // Different
        maxTokens: 2000,
      );
      
      expect(settings1 == settings2, true);
      expect(settings1 == settings3, false);
    });

    test('hashCode should be consistent with equality', () {
      final settings1 = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
      );
      
      final settings2 = ModelSettings(
        modelId: 'test-model',
        temperature: 0.7,
        maxTokens: 2000,
      );
      
      expect(settings1.hashCode, settings2.hashCode);
    });

    test('toString should include all fields', () {
      final settings = ModelSettings.defaultForModel('test-model');
      final str = settings.toString();
      
      expect(str, contains('test-model'));
      expect(str, contains('temperature'));
      expect(str, contains('maxTokens'));
    });

    test('should handle null systemPrompt in JSON', () {
      final json = {
        'modelId': 'test-model',
        'temperature': 1.0,
        'maxTokens': 4096,
        'topP': 1.0,
        'frequencyPenalty': 0.0,
        'presencePenalty': 0.0,
        'stream': true,
      };
      
      final settings = ModelSettings.fromJson(json);
      
      expect(settings.systemPrompt, isNull);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'modelId': 'test-model',
        'temperature': 1.0,
        'maxTokens': 4096,
      };
      
      final settings = ModelSettings.fromJson(json);
      
      expect(settings.modelId, 'test-model');
      expect(settings.temperature, 1.0);
      expect(settings.maxTokens, 4096);
      expect(settings.topP, 1.0); // Default
      expect(settings.frequencyPenalty, 0.0); // Default
      expect(settings.presencePenalty, 0.0); // Default
      expect(settings.stream, true); // Default
    });
  });

  group('ModelSettingsProvider Tests', () {
    setUp(() {
      // Mock SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should initialize with empty cache', () {
      final provider = ModelSettingsProvider();
      expect(provider.isLoading, false);
      expect(provider.activeSettings, isNull);
    });

    test('should load default settings for new model', () async {
      final provider = ModelSettingsProvider();
      final settings = await provider.loadSettings('new-model');
      
      expect(settings.modelId, 'new-model');
      expect(settings.temperature, 1.0);
      expect(settings.maxTokens, 4096);
    });

    test('should cache loaded settings', () async {
      final provider = ModelSettingsProvider();
      
      // First load
      final settings1 = await provider.loadSettings('cached-model');
      
      // Second load should return cached version
      final settings2 = await provider.loadSettings('cached-model');
      
      expect(settings1.modelId, settings2.modelId);
      expect(settings1.temperature, settings2.temperature);
    });

    test('should save and retrieve settings', () async {
      final provider = ModelSettingsProvider();
      
      final settings = ModelSettings(
        modelId: 'saved-model',
        temperature: 0.8,
        maxTokens: 2048,
      );
      
      await provider.saveSettings(settings);
      
      // Load from cache
      final loaded = await provider.loadSettings('saved-model');
      
      expect(loaded.temperature, 0.8);
      expect(loaded.maxTokens, 2048);
    });

    test('should set active model', () async {
      final provider = ModelSettingsProvider();
      final settings = ModelSettings.defaultForModel('active-model');
      await provider.saveSettings(settings);
      
      await provider.setActiveModel('active-model');
      
      expect(provider.activeSettings?.modelId, 'active-model');
    });

    test('should update active settings', () async {
      final provider = ModelSettingsProvider();
      await provider.setActiveModel('test-model');
      
      final updated = ModelSettings(
        modelId: 'test-model',
        temperature: 0.5,
        maxTokens: 1024,
      );
      
      await provider.updateActiveSettings(updated);
      
      expect(provider.activeSettings?.temperature, 0.5);
      expect(provider.activeSettings?.maxTokens, 1024);
    });

    test('should update individual parameters', () async {
      final provider = ModelSettingsProvider();
      await provider.setActiveModel('test-model');
      
      await provider.updateActiveParameter(
        temperature: 0.7,
        maxTokens: 2048,
      );
      
      expect(provider.activeSettings?.temperature, 0.7);
      expect(provider.activeSettings?.maxTokens, 2048);
    });

    test('should delete settings', () async {
      final provider = ModelSettingsProvider();
      final settings = ModelSettings.defaultForModel('to-delete');
      await provider.saveSettings(settings);
      
      await provider.deleteSettings('to-delete');
      
      // Should return defaults after deletion
      final loaded = await provider.loadSettings('to-delete');
      expect(loaded.temperature, 1.0);
    });

    test('should reset settings to defaults', () async {
      final provider = ModelSettingsProvider();
      await provider.setActiveModel('test-model');
      
      // Update to custom values
      await provider.updateActiveParameter(
        temperature: 0.3,
        maxTokens: 500,
      );
      
      // Reset
      await provider.resetActiveSettings();
      
      expect(provider.activeSettings?.temperature, 1.0);
      expect(provider.activeSettings?.maxTokens, 4096);
    });

    test('should get all stored model IDs', () async {
      final provider = ModelSettingsProvider();
      
      await provider.saveSettings(ModelSettings.defaultForModel('model1'));
      await provider.saveSettings(ModelSettings.defaultForModel('model2'));
      await provider.saveSettings(ModelSettings.defaultForModel('model3'));
      
      final ids = await provider.getAllStoredModelIds();
      
      expect(ids.length, 3);
      expect(ids, contains('model1'));
      expect(ids, contains('model2'));
      expect(ids, contains('model3'));
    });

    test('should clear all settings', () async {
      final provider = ModelSettingsProvider();
      
      await provider.saveSettings(ModelSettings.defaultForModel('model1'));
      await provider.setActiveModel('model1');
      
      await provider.clearAll();
      
      final ids = await provider.getAllStoredModelIds();
      expect(ids.length, 0);
      expect(provider.activeSettings, isNull);
    });
  });

  group('ModelSettings Integration Tests', () {
    test('full flow: API model -> settings -> save -> load', () async {
      // Simulate getting model from API
      final apiModelContextLength = 8192;
      final modelId = 'api-model';
      
      // Create settings from API info
      final settings = ModelSettings.fromApiModel(
        modelId,
        apiModelContextLength,
        null,
      );
      
      expect(settings.apiContextLength, 8192);
      expect(settings.maxContextLength, 8192);
      
      // Save settings
      final provider = ModelSettingsProvider();
      await provider.saveSettings(settings);
      
      // Load settings
      final loaded = await provider.loadSettings(modelId);
      
      expect(loaded.modelId, modelId);
      expect(loaded.apiContextLength, 8192);
      expect(loaded.maxContextLength, 8192);
    });

    test('settings persist across provider instances', () async {
      // First instance
      final provider1 = ModelSettingsProvider();
      final settings = ModelSettings(
        modelId: 'persistent',
        temperature: 0.6,
        maxTokens: 1500,
      );
      await provider1.saveSettings(settings);
      
      // Second instance (simulates app restart)
      final provider2 = ModelSettingsProvider();
      final loaded = await provider2.loadSettings('persistent');
      
      expect(loaded.temperature, 0.6);
      expect(loaded.maxTokens, 1500);
    });

    test('active settings are preserved in cache', () async {
      final provider = ModelSettingsProvider();
      
      // Set active model
      await provider.setActiveModel('active-model');
      
      // Update active settings
      await provider.updateActiveParameter(temperature: 0.9);
      
      // Access active settings multiple times
      expect(provider.activeSettings?.temperature, 0.9);
      expect(provider.activeSettings?.modelId, 'active-model');
    });
  });
}
