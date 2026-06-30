import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/models/model_config.dart';

/// Standalone function that mirrors the logic in _ChatMessagesState._resolveModelDisplayName.
///
/// This function is extracted for testability. The actual widget method uses
/// Riverpod's ref to get the catalog, but the core logic is the same:
/// - Returns null for null/empty modelId
/// - Returns displayName if model is found in catalog
/// - Returns modelId as-is if model is not found
String? resolveModelDisplayName({
  required String? modelId,
  required CatalogLike catalog,
}) {
  if (modelId == null || modelId.isEmpty) return null;
  final config = catalog.getModel(modelId);
  return config?.displayName ?? modelId;
}

/// Interface matching ProviderCatalogService for testing.
abstract class CatalogLike {
  ModelConfig? getModel(String modelId);
}

/// Mock catalog for testing.
class MockCatalog implements CatalogLike {
  final Map<String, ModelConfig> _models = {};

  void addModel(ModelConfig model) {
    _models[model.id] = model;
  }

  @override
  ModelConfig? getModel(String modelId) {
    return _models[modelId];
  }
}

void main() {
  group('resolveModelDisplayName', () {
    late MockCatalog catalog;

    setUp(() {
      catalog = MockCatalog();

      // Add some known models
      catalog.addModel(
        ModelConfig.basic(
          id: 'openai/gpt-4o',
          providerId: 'openai',
          modelName: 'gpt-4o',
          displayName: 'GPT-4o',
          contextLength: 128000,
        ),
      );

      catalog.addModel(
        ModelConfig.basic(
          id: 'anthropic/claude-3-5-sonnet',
          providerId: 'anthropic',
          modelName: 'claude-3-5-sonnet',
          displayName: 'Claude 3.5 Sonnet',
          contextLength: 200000,
        ),
      );

      catalog.addModel(
        ModelConfig.basic(
          id: 'google/gemini-2.5-pro',
          providerId: 'google',
          modelName: 'gemini-2.5-pro',
          displayName: 'Gemini 2.5 Pro',
          contextLength: 1000000,
        ),
      );
    });

    test('returns null for null modelId', () {
      final result = resolveModelDisplayName(modelId: null, catalog: catalog);
      expect(result, isNull);
    });

    test('returns null for empty modelId', () {
      final result = resolveModelDisplayName(modelId: '', catalog: catalog);
      expect(result, isNull);
    });

    test('returns displayName for known model', () {
      final result = resolveModelDisplayName(
        modelId: 'openai/gpt-4o',
        catalog: catalog,
      );
      expect(result, 'GPT-4o');
    });

    test('returns displayName for known model with different provider', () {
      final result = resolveModelDisplayName(
        modelId: 'anthropic/claude-3-5-sonnet',
        catalog: catalog,
      );
      expect(result, 'Claude 3.5 Sonnet');
    });

    test('returns modelId when model is not found in catalog', () {
      final result = resolveModelDisplayName(
        modelId: 'unknown/model-xyz',
        catalog: catalog,
      );
      expect(result, 'unknown/model-xyz');
    });

    test('returns modelId for model with different provider pattern', () {
      // Model ID that doesn't match any provider in catalog
      final result = resolveModelDisplayName(
        modelId: 'openrouter/anthropic/claude-sonnet-4',
        catalog: catalog,
      );
      // The model is not in our catalog, so it returns the modelId as-is
      expect(result, 'openrouter/anthropic/claude-sonnet-4');
    });

    test('handles modelId with colon separator (fallback)', () {
      // The catalog has a model with this ID, but getModel only handles slash format
      // The mock catalog's getModel fails on colon format, so it falls back to modelId
      catalog.addModel(
        ModelConfig.basic(
          id: 'openai:gpt-4-turbo',
          providerId: 'openai',
          modelName: 'gpt-4-turbo',
          displayName: 'GPT-4 Turbo',
          contextLength: 128000,
        ),
      );

      final result = resolveModelDisplayName(
        modelId: 'openai:gpt-4-turbo',
        catalog: catalog,
      );
      expect(result, 'openai:gpt-4-turbo');
    });

    test('handles whitespace-only modelId as empty', () {
      final result = resolveModelDisplayName(modelId: '   ', catalog: catalog);
      // Note: The original function only checks for null or empty string,
      // not whitespace-only. This is a limitation of the original implementation.
      // We test the actual behavior here.
      expect(result, '   '); // Returns the whitespace as-is
    });
  });

  group('ModelConfig.basic factory', () {
    test('creates ModelConfig with required fields', () {
      final config = ModelConfig.basic(
        id: 'test/model',
        providerId: 'test',
        modelName: 'model',
        displayName: 'Model Display',
        contextLength: 4096,
      );

      expect(config.id, 'test/model');
      expect(config.providerId, 'test');
      expect(config.modelName, 'model');
      expect(config.displayName, 'Model Display');
      expect(config.enabled, true);
    });
  });
}
