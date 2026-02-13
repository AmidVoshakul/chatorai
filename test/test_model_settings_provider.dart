import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/providers/model_settings_provider.dart';
import 'package:chatorai/models/model_settings.dart';

void main() {
  group('ModelSettingsProvider Tests', () {
    late ModelSettingsProvider provider;

    setUp(() {
      provider = ModelSettingsProvider();
    });

    test('should initialize with no active settings', () {
      expect(provider.activeSettings, isNull);
      expect(provider.isLoading, false);
    });

    test('should create default settings for a model', () async {
      const modelId = 'test-model';
      
      // This will use the default settings since no stored settings exist
      final result = await provider.loadSettings(modelId);

      expect(result.modelId, modelId);
      expect(result.temperature, 1.0);
      expect(result.maxTokens, 4096);
    });

    test('should set active model', () async {
      const modelId = 'test-model';
      
      await provider.setActiveModel(modelId);

      expect(provider.activeSettings?.modelId, modelId);
      expect(provider.activeSettings?.temperature, 1.0);
    });

    test('should update active settings', () async {
      const modelId = 'test-model';
      final initialSettings = ModelSettings.defaultForModel(modelId);
      final updatedSettings = initialSettings.copyWith(temperature: 0.5);

      await provider.setActiveModel(modelId);
      await provider.updateActiveSettings(updatedSettings);

      expect(provider.activeSettings?.temperature, 0.5);
    });

    test('should update specific parameter', () async {
      const modelId = 'test-model';

      await provider.setActiveModel(modelId);
      await provider.updateActiveParameter(temperature: 0.8, maxTokens: 3000);

      expect(provider.activeSettings?.temperature, 0.8);
      expect(provider.activeSettings?.maxTokens, 3000);
    });

    test('should reset settings to defaults', () async {
      const modelId = 'test-model';
      final customSettings = ModelSettings(
        modelId: modelId,
        temperature: 0.5,
        maxTokens: 3000,
      );

      await provider.setActiveModel(modelId);
      await provider.updateActiveSettings(customSettings);
      await provider.resetActiveSettings();

      expect(provider.activeSettings?.temperature, 1.0);
      expect(provider.activeSettings?.maxTokens, 4096);
    });
  });
}
