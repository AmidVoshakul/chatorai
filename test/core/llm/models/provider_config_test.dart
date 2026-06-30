import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/model_variant.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';

void main() {
  group('ProviderConfig', () {
    final basicProvider = ProviderConfig.basic(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
    );

    test('basic factory sets required fields', () {
      expect(basicProvider.id, 'openai');
      expect(basicProvider.name, 'OpenAI');
      expect(basicProvider.baseUrl, 'https://api.openai.com/v1');
    });

    test('basic factory uses defaults', () {
      expect(basicProvider.description, isNull);
      expect(basicProvider.auth, isA<AuthConfig>());
      expect(basicProvider.auth.type, AuthType.none);
      expect(basicProvider.models, isEmpty);
      expect(basicProvider.enabled, true);
      expect(basicProvider.metadata, isEmpty);
    });

    test('full factory sets all fields', () {
      final provider = ProviderConfig.full(
        id: 'anthropic',
        name: 'Anthropic',
        description: 'Claude API provider',
        baseUrl: 'https://api.anthropic.com',
        auth: AuthConfig.apiKey(apiKey: 'dummy', apiKeyHeader: 'x-api-key'),
        models: [
          ModelConfig.basic(
            providerId: 'anthropic',
            modelName: 'claude-3-5-sonnet',
            displayName: 'Claude 3.5 Sonnet',
            contextLength: 200000,
          ),
        ],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        metadata: {'region': 'us-west-2'},
        defaultBody: {'max_tokens': 4096, 'anthropic_version': '2023-06-01'},
      );

      expect(provider.description, 'Claude API provider');
      expect(provider.auth.type, AuthType.apiKey);
      expect(provider.auth.apiKeyHeader, 'x-api-key');
      expect(provider.models.length, 1);
      expect(provider.models.first.modelName, 'claude-3-5-sonnet');
      expect(provider.metadata['region'], 'us-west-2');
      expect(provider.defaultBody, {
        'max_tokens': 4096,
        'anthropic_version': '2023-06-01',
      });
    });

    test(
      'getModel matches by exact modelName',
      () {
        final provider = ProviderConfig.full(
          id: 'openrouter',
          name: 'OpenRouter',
          baseUrl: 'https://openrouter.ai/api/v1',
          auth: AuthConfig.none(),
          models: [
            ModelConfig.basic(
              providerId: 'openrouter',
              modelName: 'openai/gpt-4o',
              displayName: 'GPT-4o',
              contextLength: 128000,
            ),
          ],
        );

        expect(
          provider.getModel('openai/gpt-4o')?.id,
          'openrouter/openai/gpt-4o',
        );
        expect(provider.getModel('nonexistent'), isNull);
      },
    );

    test('copyWith preserves unchanged fields', () {
      final copied = basicProvider.copyWith(description: 'Updated description');
      expect(copied.id, basicProvider.id);
      expect(copied.name, basicProvider.name);
      expect(copied.description, 'Updated description');
      expect(copied.auth, basicProvider.auth);
      expect(copied.models, basicProvider.models);
    });

    test('equality compares all fields', () {
      final p1 = ProviderConfig.basic(
        id: 'test',
        name: 'Test Provider',
        baseUrl: 'https://test.com',
      );
      final p2 = ProviderConfig.basic(
        id: 'test',
        name: 'Test Provider',
        baseUrl: 'https://test.com',
      );
      final p3 = p1.copyWith(baseUrl: 'https://other.com');

      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('toJson serializes all fields correctly', () {
      final provider = ProviderConfig.full(
        id: 'openrouter',
        name: 'OpenRouter',
        description: 'Aggregated AI provider',
        baseUrl: 'https://openrouter.ai/api/v1',
        auth: AuthConfig.apiKey(
          apiKey: 'sk-or-v1-key',
          apiKeyHeader: 'Authorization',
        ),
        models: [
          ModelConfig.basic(
            providerId: 'openrouter',
            modelName: 'gpt-4o',
            displayName: 'GPT-4o',
            contextLength: 128000,
          ),
        ],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T12:00:00Z'),
        metadata: {'apiKeyPrefix': 'sk-or-'},
        defaultBody: {'max_tokens': 2048},
      );

      final json = provider.toJson();
      expect(json['id'], 'openrouter');
      expect(json['name'], 'OpenRouter');
      expect(json['description'], 'Aggregated AI provider');
      expect(json['baseUrl'], 'https://openrouter.ai/api/v1');
      expect(json['auth'], isA<Map>());
      expect(json['auth']['type'], 'apiKey');
      expect(json['auth']['apiKeyHeader'], 'Authorization');
      expect(json['models'], hasLength(1));
      expect(json['models'][0]['id'], 'openrouter/gpt-4o');
      expect(json['enabled'], true);
      expect(json['addedAt'], '2024-01-01T12:00:00.000Z');
      expect(json['metadata']['apiKeyPrefix'], 'sk-or-');
      expect(json['defaultBody'], {'max_tokens': 2048});
    });

    test('toJson excludes null and empty fields', () {
      final json = basicProvider.toJson();
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('auth'), isFalse);
      expect(json.containsKey('models'), isFalse);
      expect(json.containsKey('addedAt'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('fromJson reconstructs provider with nested objects', () {
      final original = ProviderConfig.full(
        id: 'groq',
        name: 'Groq',
        baseUrl: 'https://api.groq.com/openai/v1',
        auth: AuthConfig.apiKey(
          apiKey: 'gsk-key',
          apiKeyHeader: 'Authorization',
        ),
        models: [
          ModelConfig.basic(
            providerId: 'groq',
            modelName: 'llama-3.1-70b',
            displayName: 'Llama 3.1 70B',
            contextLength: 131072,
          ),
        ],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        metadata: {'fast': true},
        defaultBody: {'max_tokens': 4096},
      );

      final json = original.toJson();
      final restored = ProviderConfig.fromJson(json);
      expect(restored, equals(original));
      expect(restored.defaultBody, {'max_tokens': 4096});
    });

    test('fromJson handles minimal required fields', () {
      final json = {
        'id': 'minimal',
        'name': 'Minimal Provider',
        'baseUrl': 'https://minimal.com',
      };
      final provider = ProviderConfig.fromJson(json);
      expect(provider.id, 'minimal');
      expect(provider.description, isNull);
      expect(provider.auth.type, AuthType.none);
      expect(provider.models, isEmpty);
      expect(provider.enabled, true);
    });

    test('toString includes key information', () {
      final str = basicProvider.toString();
      expect(str, contains('id: openai'));
      expect(str, contains('name: OpenAI'));
      expect(str, contains('baseUrl: https://api.openai.com/v1'));
    });

    test('nested model serialization preserves all fields', () {
      final model = ModelConfig.full(
        providerId: 'test',
        modelName: 'model',
        displayName: 'Model',
        description: 'Test model',
        capabilities: ModelCapabilities(
          reasoning: true,
          vision: true,
          tools: false,
          streaming: true,
        ),
        contextLength: 50000,
        defaultMaxTokens: 4096,
        pricing: ModelPricing.unified(0.01),
        variants: [ModelVariant.basic(id: 'v1', name: 'V1')],
        enabled: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        metadata: {},
      );

      final provider = ProviderConfig.full(
        id: 'test-provider',
        name: 'Test Provider',
        baseUrl: 'https://test.com',
        auth: AuthConfig.none(),
        models: [model],
      );

      final json = provider.toJson();
      expect(json['models'][0]['id'], 'test/model');
      expect(json['models'][0]['capabilities']['reasoning'], true);
      expect(json['models'][0]['variants'][0]['id'], 'v1');
    });
  });
}
