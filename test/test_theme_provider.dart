import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/providers/theme_provider.dart';
import 'package:chatorai/services/openrouter_service.dart';

void main() {
  group('ThemeProvider Model Support Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    // Test 1: modelSupportsImagesSelected with no selected model
    test('modelSupportsImagesSelected returns false when no model selected', () {
      // No model selected
      expect(themeProvider.modelSupportsImagesSelected(), false);
    });

    // Test 2: modelSupportsImagesSelected with model that supports images
    test('modelSupportsImagesSelected returns true for multimodal model', () {
      // Create a mock model with multimodal support
      final mockModel = OpenRouterModel(
        id: 'test-model-1',
        name: 'Test Multimodal Model',
        description: 'A test model with image support',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: true,
          vision: true,
          tools: false,
        ),
      );

      // Manually set the selected model (bypassing the normal flow for testing)
      themeProvider.updateSelectedModel('test-model-1', mockModel);

      expect(themeProvider.modelSupportsImagesSelected(), true);
    });

    // Test 3: modelSupportsImagesSelected with model that doesn't support images
    test('modelSupportsImagesSelected returns false for text-only model', () {
      // Create a mock model without multimodal support
      final mockModel = OpenRouterModel(
        id: 'test-model-2',
        name: 'Test Text Model',
        description: 'A test model without image support',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: false,
          vision: false,
          tools: false,
        ),
      );

      themeProvider.updateSelectedModel('test-model-2', mockModel);

      expect(themeProvider.modelSupportsImagesSelected(), false);
    });

    // Test 4: modelSupportsImages with specific model ID
    test('modelSupportsImages checks specific model by ID', () {
      // Add models to available list
      final multimodalModel = OpenRouterModel(
        id: 'model-with-images',
        name: 'Multimodal Model',
        description: 'Supports images',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: true,
          vision: true,
          tools: false,
        ),
      );

      final textModel = OpenRouterModel(
        id: 'model-text-only',
        name: 'Text Model',
        description: 'No image support',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: false,
          vision: false,
          tools: false,
        ),
      );

      // Manually add to available models for testing
      themeProvider.addModelForTesting(multimodalModel);
      themeProvider.addModelForTesting(textModel);

      expect(themeProvider.modelSupportsImages('model-with-images'), true);
      expect(themeProvider.modelSupportsImages('model-text-only'), false);
      expect(themeProvider.modelSupportsImages('non-existent'), false);
    });

    // Test 5: checkModelSupportsImages with fallback
    test('checkModelSupportsImages uses fallback correctly', () {
      // Test with model that exists
      final mockModel = OpenRouterModel(
        id: 'test-model',
        name: 'Test Model',
        description: 'Test',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: true,
          vision: true,
          tools: false,
        ),
      );

      themeProvider.addModelForTesting(mockModel);

      // Should return true for multimodal model
      expect(themeProvider.checkModelSupportsImages('test-model'), true);

      // Should return false for non-existent model
      expect(themeProvider.checkModelSupportsImages('unknown'), false);
    });

    // Test 6: Model with only vision capability
    test('modelSupportsImages returns true for vision-only model', () {
      final visionModel = OpenRouterModel(
        id: 'vision-only',
        name: 'Vision Model',
        description: 'Only vision support',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: false,
          vision: true,
          tools: false,
        ),
      );

      themeProvider.updateSelectedModel('vision-only', visionModel);

      expect(themeProvider.modelSupportsImagesSelected(), true);
    });

    // Test 7: Model with only multimodal capability
    test('modelSupportsImages returns true for multimodal-only model', () {
      final multimodalModel = OpenRouterModel(
        id: 'multimodal-only',
        name: 'Multimodal Model',
        description: 'Only multimodal support',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: true,
          vision: false,
          tools: false,
        ),
      );

      themeProvider.updateSelectedModel('multimodal-only', multimodalModel);

      expect(themeProvider.modelSupportsImagesSelected(), true);
    });

    // Test 8: Model with neither capability
    test('modelSupportsImages returns false when both capabilities are false', () {
      final noSupportModel = OpenRouterModel(
        id: 'no-support',
        name: 'No Support Model',
        description: 'No image support',
        capabilities: ModelCapabilities(
          reasoning: false,
          multimodal: false,
          vision: false,
          tools: false,
        ),
      );

      themeProvider.updateSelectedModel('no-support', noSupportModel);

      expect(themeProvider.modelSupportsImagesSelected(), false);
    });
  });
}
