import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/models/model_variant.dart';

void main() {
  group('ModelPricing', () {
    test('unified factory creates symmetric pricing', () {
      final pricing = ModelPricing.unified(0.01);
      expect(pricing.inputCostPer1k, 0.01);
      expect(pricing.outputCostPer1k, 0.01);
    });

    test('full factory creates separate input/output costs', () {
      final pricing = ModelPricing(
        inputCostPer1k: 0.005,
        outputCostPer1k: 0.015,
      );
      expect(pricing.inputCostPer1k, 0.005);
      expect(pricing.outputCostPer1k, 0.015);
    });

    test('copyWith modifies fields correctly', () {
      final original = ModelPricing.unified(0.01);
      final copied = original.copyWith(outputCostPer1k: 0.02);
      expect(copied.inputCostPer1k, 0.01);
      expect(copied.outputCostPer1k, 0.02);
    });

    test('equality works correctly', () {
      final p1 = ModelPricing.unified(0.01);
      final p2 = ModelPricing.unified(0.01);
      final p3 = ModelPricing.unified(0.02);
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('toJson and fromJson are symmetric', () {
      final original = ModelPricing(
        inputCostPer1k: 0.005,
        outputCostPer1k: 0.015,
      );
      final json = original.toJson();
      final restored = ModelPricing.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{};
      final pricing = ModelPricing.fromJson(json);
      expect(pricing.inputCostPer1k, isNull);
      expect(pricing.outputCostPer1k, isNull);
    });
  });

  group('ModelVariant', () {
    final basicVariant = ModelVariant.basic(
      id: 'gpt-4o-mini',
      name: 'GPT-4o Mini',
      temperature: 0.7,
      maxTokens: 4096,
    );

    test('basic factory sets required fields', () {
      expect(basicVariant.id, 'gpt-4o-mini');
      expect(basicVariant.name, 'GPT-4o Mini');
      expect(basicVariant.temperature, 0.7);
      expect(basicVariant.maxTokens, 4096);
    });

    test('basic factory uses defaults for optional fields', () {
      expect(basicVariant.description, isNull);
      expect(basicVariant.supportsReasoning, false);
      expect(basicVariant.supportsMultimodal, false);
      expect(basicVariant.supportsTools, true);
      expect(basicVariant.topP, isNull);
    });

    test('full factory sets all fields', () {
      final variant = ModelVariant.full(
        id: 'claude-3-5-sonnet',
        name: 'Claude 3.5 Sonnet',
        description: 'Latest Claude model',
        temperature: 0.8,
        maxTokens: 8192,
        topP: 0.9,
        frequencyPenalty: 0.1,
        presencePenalty: 0.1,
        stopSequences: ['END', 'STOP'],
        supportsReasoning: true,
        supportsMultimodal: true,
        supportsTools: true,
        contextLength: 200000,
        pricing: ModelPricing.unified(0.003),
        headers: {'anthropic-beta': 'thinking-2025-05-14'},
        body: {
          'reasoning': {'type': 'enabled'},
        },
      );

      expect(variant.description, 'Latest Claude model');
      expect(variant.topP, 0.9);
      expect(variant.frequencyPenalty, 0.1);
      expect(variant.presencePenalty, 0.1);
      expect(variant.stopSequences, ['END', 'STOP']);
      expect(variant.supportsReasoning, true);
      expect(variant.contextLength, 200000);
      expect(variant.pricing, isNotNull);
      expect(variant.headers, {'anthropic-beta': 'thinking-2025-05-14'});
      expect(variant.body, {
        'reasoning': {'type': 'enabled'},
      });
    });

    test('copyWith modifies specified fields', () {
      final copied = basicVariant.copyWith(temperature: 1.0, maxTokens: 8192);
      expect(copied.id, basicVariant.id);
      expect(copied.temperature, 1.0);
      expect(copied.maxTokens, 8192);
      expect(copied.name, basicVariant.name);
    });

    test('equality compares all fields', () {
      final v1 = ModelVariant.basic(id: 'test', name: 'Test');
      final v2 = ModelVariant.basic(id: 'test', name: 'Test');
      final v3 = ModelVariant.basic(id: 'test2', name: 'Test2');
      expect(v1, equals(v2));
      expect(v1, isNot(equals(v3)));
    });

    test('toJson includes all non-null fields', () {
      final variant = ModelVariant.full(
        id: 'test-model',
        name: 'Test Model',
        temperature: 0.5,
        maxTokens: 2048,
        topP: 0.8,
        supportsReasoning: true,
        supportsMultimodal: true,
        supportsTools: true,
        contextLength: 4096,
        pricing: ModelPricing.unified(0.01),
        headers: {'X-Custom': 'value'},
        body: {'custom_field': 'test'},
      );

      final json = variant.toJson();
      expect(json['id'], 'test-model');
      expect(json['name'], 'Test Model');
      expect(json['temperature'], 0.5);
      expect(json['maxTokens'], 2048);
      expect(json['topP'], 0.8);
      expect(json['supportsReasoning'], true);
      expect(json['contextLength'], 4096);
      expect(json['pricing'], isA<Map>());
      expect(json['headers'], {'X-Custom': 'value'});
      expect(json['body'], {'custom_field': 'test'});
    });

    test('toJson excludes null fields', () {
      final variant = ModelVariant.basic(id: 'test', name: 'Test');
      final json = variant.toJson();
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('topP'), isFalse);
      expect(json.containsKey('pricing'), isFalse);
    });

    test('fromJson reconstructs variant correctly', () {
      final original = ModelVariant.full(
        id: 'gpt-4o',
        name: 'GPT-4o',
        temperature: 1.0,
        maxTokens: 4096,
        topP: 1.0,
        stopSequences: ['STOP'],
        supportsReasoning: false,
        supportsMultimodal: true,
        supportsTools: true,
        contextLength: 128000,
        pricing: ModelPricing.unified(0.005),
      );

      final json = original.toJson();
      final restored = ModelVariant.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson reconstructs variant with headers and body', () {
      final original = ModelVariant.full(
        id: 'thinking-model',
        name: 'Thinking Model',
        temperature: 0.7,
        maxTokens: 4096,
        supportsReasoning: true,
        contextLength: 200000,
        headers: {'anthropic-beta': 'thinking-2025-05-14', 'X-Custom': 'value'},
        body: {
          'reasoning_config': {'budget': 8192},
        },
      );

      final json = original.toJson();
      final restored = ModelVariant.fromJson(json);

      expect(restored.id, 'thinking-model');
      expect(restored.headers, {
        'anthropic-beta': 'thinking-2025-05-14',
        'X-Custom': 'value',
      });
      expect(restored.body, {
        'reasoning_config': {'budget': 8192},
      });
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'minimal-model',
        'name': 'Minimal',
        'temperature': 0.7,
        'supportsReasoning': false,
        'supportsMultimodal': false,
        'supportsTools': true,
      };
      final variant = ModelVariant.fromJson(json);
      expect(variant.id, 'minimal-model');
      expect(variant.description, isNull);
      expect(variant.maxTokens, isNull);
      expect(variant.pricing, isNull);
    });

    test('toString includes key information', () {
      final variant = ModelVariant.basic(id: 'gpt-4', name: 'GPT-4');
      final str = variant.toString();
      expect(str, contains('id: gpt-4'));
      expect(str, contains('name: GPT-4'));
    });
  });
}
