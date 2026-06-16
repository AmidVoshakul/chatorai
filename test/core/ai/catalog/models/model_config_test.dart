import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/catalog/models/model_config.dart';
import 'package:chatorai/core/llm/catalog/models/model_variant.dart';

void main() {
  group('ModelConfig', () {
    final basicModel = ModelConfig.basic(
      id: 'openai/gpt-4o-mini',
      providerId: 'openai',
      modelName: 'gpt-4o-mini',
      displayName: 'GPT-4o Mini',
      contextLength: 128000,
    );

    test('basic factory sets required fields', () {
      expect(basicModel.id, 'openai/gpt-4o-mini');
      expect(basicModel.providerId, 'openai');
      expect(basicModel.modelName, 'gpt-4o-mini');
      expect(basicModel.displayName, 'GPT-4o Mini');
      expect(basicModel.contextLength, 128000);
    });

    test('basic factory uses defaults', () {
      expect(basicModel.description, isNull);
      expect(basicModel.capabilities, isA<ModelCapabilities>());
      expect(basicModel.capabilities.tools, true);
      expect(basicModel.capabilities.streaming, true);
      expect(basicModel.defaultMaxTokens, isNull);
      expect(basicModel.pricing, isNull);
      expect(basicModel.variants, isEmpty);
      expect(basicModel.enabled, true);
      expect(basicModel.metadata, isEmpty);
    });

    test('full factory sets all fields', () {
      final model = ModelConfig.full(
        id: 'anthropic/claude-3-5-sonnet',
        providerId: 'anthropic',
        modelName: 'claude-3-5-sonnet',
        displayName: 'Claude 3.5 Sonnet',
        description: 'Most capable Claude model',
        capabilities: ModelCapabilities.full(),
        contextLength: 200000,
        defaultMaxTokens: 4096,
        pricing: ModelPricing.unified(0.003),
        variants: [ModelVariant.basic(id: 'v1', name: 'Default')],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        metadata: {'region': 'us-east-1'},
      );

      expect(model.description, 'Most capable Claude model');
      expect(model.capabilities.reasoning, true);
      expect(model.capabilities.multimodal, true);
      expect(model.defaultMaxTokens, 4096);
      expect(model.variants.length, 1);
      expect(model.metadata['region'], 'us-east-1');
    });

    test('defaultVariant returns first variant or null', () {
      final modelWithVariants = basicModel.copyWith(
        variants: [
          ModelVariant.basic(id: 'v1', name: 'Variant 1'),
          ModelVariant.basic(id: 'v2', name: 'Variant 2'),
        ],
      );
      expect(modelWithVariants.defaultVariant?.id, 'v1');

      final modelWithoutVariants = basicModel;
      expect(modelWithoutVariants.defaultVariant, isNull);
    });

    test('getVariant returns correct variant by ID', () {
      final model = basicModel.copyWith(
        variants: [
          ModelVariant.basic(id: 'v1', name: 'Variant 1'),
          ModelVariant.basic(id: 'v2', name: 'Variant 2'),
        ],
      );
      expect(model.getVariant('v1')?.name, 'Variant 1');
      expect(model.getVariant('v2')?.name, 'Variant 2');
      expect(model.getVariant('nonexistent'), isNull);
    });

    test('getModelByVariantId finds model containing variant', () {
      final model = basicModel.copyWith(
        variants: [ModelVariant.basic(id: 'special-variant', name: 'Special')],
      );
      expect(model.getModelByVariantId('special-variant'), equals(model));
      expect(model.getModelByVariantId('other-variant'), isNull);
    });

    test('addModel appends to variants list', () {
      final model = basicModel.copyWith(variants: []);
      final newVariant = ModelVariant.basic(id: 'new', name: 'New Variant');
      final updated = model.addModel(newVariant);
      expect(updated.variants.length, 1);
      expect(updated.variants.first.id, 'new');
    });

    test('removeModel filters out variant', () {
      final model = basicModel.copyWith(
        variants: [
          ModelVariant.basic(id: 'keep', name: 'Keep'),
          ModelVariant.basic(id: 'remove', name: 'Remove'),
        ],
      );
      final updated = model.removeModel('remove');
      expect(updated.variants.length, 1);
      expect(updated.variants.first.id, 'keep');
    });

    test('updateModel replaces variant', () {
      final model = basicModel.copyWith(
        variants: [ModelVariant.basic(id: 'old', name: 'Old')],
      );
      final updatedVariant = ModelVariant.basic(id: 'old', name: 'Updated');
      final updated = model.updateModel('old', updatedVariant);
      expect(updated.variants.first.name, 'Updated');
    });

    test('copyWith preserves unchanged fields', () {
      final copied = basicModel.copyWith(description: 'New description');
      expect(copied.id, basicModel.id);
      expect(copied.providerId, basicModel.providerId);
      expect(copied.description, 'New description');
      expect(copied.capabilities, basicModel.capabilities);
    });

    test('equality compares all fields', () {
      final m1 = ModelConfig.basic(
        id: 'test',
        providerId: 'test-provider',
        modelName: 'test-model',
        displayName: 'Test Model',
        contextLength: 1000,
      );
      final m2 = ModelConfig.basic(
        id: 'test',
        providerId: 'test-provider',
        modelName: 'test-model',
        displayName: 'Test Model',
        contextLength: 1000,
      );
      final m3 = m1.copyWith(contextLength: 2000);

      expect(m1, equals(m2));
      expect(m1, isNot(equals(m3)));
    });

    test('toJson serializes all fields correctly', () {
      final model = ModelConfig.full(
        id: 'test/model',
        providerId: 'test',
        modelName: 'model',
        displayName: 'Model',
        description: 'Test model',
        capabilities: ModelCapabilities(reasoning: true, vision: true),
        contextLength: 50000,
        defaultMaxTokens: 4096,
        pricing: ModelPricing.unified(0.01),
        variants: [ModelVariant.basic(id: 'v1', name: 'V1')],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T12:00:00Z'),
        metadata: {'key': 'value'},
      );

      final json = model.toJson();
      expect(json['id'], 'test/model');
      expect(json['providerId'], 'test');
      expect(json['modelName'], 'model');
      expect(json['displayName'], 'Model');
      expect(json['description'], 'Test model');
      expect(json['capabilities'], isA<Map>());
      expect(json['contextLength'], 50000);
      expect(json['defaultMaxTokens'], 4096);
      expect(json['pricing'], isA<Map>());
      expect(json['variants'], hasLength(1));
      expect(json['enabled'], true);
      expect(json['addedAt'], '2024-01-01T12:00:00.000Z');
      expect(json['metadata'], {'key': 'value'});
    });

    test('toJson excludes null and empty fields', () {
      final json = basicModel.toJson();
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('defaultMaxTokens'), isFalse);
      expect(json.containsKey('pricing'), isFalse);
      expect(json.containsKey('variants'), isFalse);
      expect(json.containsKey('addedAt'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson reconstructs model correctly', () {
      final original = ModelConfig.full(
        id: 'openai/gpt-4o',
        providerId: 'openai',
        modelName: 'gpt-4o',
        displayName: 'GPT-4o',
        description: 'Multimodal model',
        capabilities: ModelCapabilities.full(),
        contextLength: 128000,
        defaultMaxTokens: 4096,
        pricing: ModelPricing.unified(0.005),
        variants: [ModelVariant.basic(id: 'default', name: 'Default')],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        metadata: {'test': true},
      );

      final json = original.toJson();
      final restored = ModelConfig.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson handles minimal required fields', () {
      final json = {
        'id': 'minimal',
        'providerId': 'provider',
        'modelName': 'model',
        'displayName': 'Display',
        'capabilities': {'tools': true, 'streaming': true},
        'contextLength': 1000,
      };
      final model = ModelConfig.fromJson(json);
      expect(model.id, 'provider/minimal');
      expect(model.description, isNull);
      expect(model.variants, isEmpty);
      expect(model.enabled, true);
    });

    test('toString includes key information', () {
      final str = basicModel.toString();
      expect(str, contains('id: openai/gpt-4o-mini'));
      expect(str, contains('providerId: openai'));
      expect(str, contains('modelName: gpt-4o-mini'));
      expect(str, contains('contextLength: 128000'));
    });
  });
}
