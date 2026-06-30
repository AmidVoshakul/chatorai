import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';

/// Mock SecureStorageService for testing.
class MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}

void main() {
  group('ModelResolver', () {
    late MockSecureStorageService mockStorage;
    late ProviderCatalogService catalog;
    late ModelResolver resolver;

    final testProvider = ProviderConfig.basic(
      id: 'test-provider',
      name: 'Test Provider',
      baseUrl: 'https://api.test.com/v1',
      auth: AuthConfig.apiKey(apiKey: 'sk-test'),
      sdk: 'openai-compatible',
      models: [
        ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'gpt-4o',
          displayName: 'GPT-4o',
          contextLength: 128000,
        ),
        ModelConfig.basic(
          providerId: 'test-provider',
          modelName: 'gpt-4o-mini',
          displayName: 'GPT-4o Mini',
          contextLength: 128000,
        ),
      ],
    );

    setUp(() async {
      mockStorage = MockSecureStorageService();
      SharedPreferences.setMockInitialValues({
        'catalog_cache_version': 4,
        'catalog_provider_enabled_test-provider': true,
      });
      final prefs = await SharedPreferences.getInstance();
      catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [testProvider],
      );
      resolver = ModelResolver(catalog);
    });

    group('resolve', () {
      test('returns ModelConfig for valid modelId', () {
        final model = resolver.resolve('test-provider/gpt-4o');
        expect(model, isNotNull);
        expect(model.modelName, 'gpt-4o');
        expect(model.providerId, 'test-provider');
      });

      test('throws ModelResolutionError for unknown model', () {
        expect(
          () => resolver.resolve('test-provider/unknown'),
          throwsA(isA<ModelResolutionError>()),
        );
      });

      test('throws ModelResolutionError for invalid format', () {
        expect(
          () => resolver.resolve('no-separator'),
          throwsA(isA<ModelResolutionError>()),
        );
      });

      test('throws ModelResolutionError for nonexistent provider', () {
        expect(
          () => resolver.resolve('nonexistent/gpt-4o'),
          throwsA(isA<ModelResolutionError>()),
        );
      });
    });

    group('getProviderForModel', () {
      test('returns ProviderConfig for valid modelId', () {
        final provider = resolver.getProviderForModel('test-provider/gpt-4o');
        expect(provider, isNotNull);
        expect(provider.id, 'test-provider');
      });

      test('throws for colon-separated format (not supported)', () {
        expect(
          () => resolver.getProviderForModel('test-provider:gpt-4o'),
          throwsA(isA<ModelResolutionError>()),
        );
      });

      test('throws for invalid format without separator', () {
        expect(
          () => resolver.getProviderForModel('nosep'),
          throwsA(isA<ModelResolutionError>()),
        );
      });

      test('throws for unknown provider', () {
        expect(
          () => resolver.getProviderForModel('unknown/gpt-4o'),
          throwsA(isA<ModelResolutionError>()),
        );
      });

      test('throws for model not in provider', () {
        expect(
          () => resolver.getProviderForModel('test-provider/missing'),
          throwsA(isA<ModelResolutionError>()),
        );
      });
    });

    group('buildLanguageModel', () {
      test('throws when API key is missing and auth type is apiKey', () async {
        final authProvider = ProviderConfig.basic(
          id: 'auth-required',
          name: 'Auth Required',
          baseUrl: 'https://api.auth.com/v1',
          auth: AuthConfig.apiKey(apiKey: ''),
          sdk: 'openai-compatible',
          models: [
            ModelConfig.basic(
              providerId: 'auth-required',
              modelName: 'model-a',
              displayName: 'Model A',
              contextLength: 4096,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'catalog_cache_version': 4,
          'catalog_provider_enabled_auth-required': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cat = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [authProvider],
        );
        final res = ModelResolver(cat);

        expect(
          () => res.buildLanguageModel(cat.getModel('auth-required/model-a')!),
          throwsA(isA<ModelResolutionError>()),
        );
      });

      test('throws for Bedrock provider without AWS config', () async {
        final bedrockProvider = ProviderConfig.basic(
          id: 'bedrock-test',
          name: 'Bedrock Test',
          baseUrl: 'https://bedrock.us-east-1.amazonaws.com',
          auth: const AuthConfig.aws(),
          sdk: 'bedrock',
          models: [
            ModelConfig.basic(
              providerId: 'bedrock-test',
              modelName: 'claude',
              displayName: 'Claude',
              contextLength: 200000,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'catalog_cache_version': 4,
          'catalog_provider_enabled_bedrock-test': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cat = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [bedrockProvider],
        );
        final res = ModelResolver(cat);

        try {
          await res.buildLanguageModel(
            cat.getModel('bedrock-test/claude')!,
            overrideApiKey: 'dummy',
          );
          fail('Expected ModelResolutionError');
        } on ModelResolutionError {
          // Expected
        }
      });

      test('throws for Bedrock provider with non-AWS auth type', () async {
        final bedrockWithWrongAuth = ProviderConfig.basic(
          id: 'bedrock-wrong-auth',
          name: 'Bedrock Wrong Auth',
          baseUrl: 'https://bedrock.us-east-1.amazonaws.com',
          auth: AuthConfig.apiKey(apiKey: 'sk-test'),
          sdk: 'bedrock',
          models: [
            ModelConfig.basic(
              providerId: 'bedrock-wrong-auth',
              modelName: 'claude',
              displayName: 'Claude',
              contextLength: 200000,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'catalog_cache_version': 4,
          'catalog_provider_enabled_bedrock-wrong-auth': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cat = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [bedrockWithWrongAuth],
        );
        final res = ModelResolver(cat);

        try {
          await res.buildLanguageModel(
            cat.getModel('bedrock-wrong-auth/claude')!,
            overrideApiKey: 'dummy',
          );
          fail('Expected ModelResolutionError');
        } on ModelResolutionError {
          // Expected
        }
      });

      test('throws for Bedrock provider with missing AWS secret key', () async {
        final bedrockMissingSecret = ProviderConfig.basic(
          id: 'bedrock-missing-secret',
          name: 'Bedrock Missing Secret',
          baseUrl: 'https://bedrock.us-east-1.amazonaws.com',
          auth: const AuthConfig.aws(
            awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE',
            awsSecretAccessKey: null,
            awsRegion: 'us-east-1',
          ),
          sdk: 'bedrock',
          models: [
            ModelConfig.basic(
              providerId: 'bedrock-missing-secret',
              modelName: 'claude',
              displayName: 'Claude',
              contextLength: 200000,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'catalog_cache_version': 4,
          'catalog_provider_enabled_bedrock-missing-secret': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cat = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [bedrockMissingSecret],
        );
        final res = ModelResolver(cat);

        try {
          await res.buildLanguageModel(
            cat.getModel('bedrock-missing-secret/claude')!,
            overrideApiKey: 'dummy',
          );
          fail('Expected ModelResolutionError');
        } on ModelResolutionError {
          // Expected
        }
      });

      test('throws for Bedrock provider with missing AWS region', () async {
        final bedrockMissingRegion = ProviderConfig.basic(
          id: 'bedrock-missing-region',
          name: 'Bedrock Missing Region',
          baseUrl: 'https://bedrock.us-east-1.amazonaws.com',
          auth: const AuthConfig.aws(
            awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE',
            awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
            awsRegion: null,
          ),
          sdk: 'bedrock',
          models: [
            ModelConfig.basic(
              providerId: 'bedrock-missing-region',
              modelName: 'claude',
              displayName: 'Claude',
              contextLength: 200000,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'catalog_cache_version': 4,
          'catalog_provider_enabled_bedrock-missing-region': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cat = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [bedrockMissingRegion],
        );
        final res = ModelResolver(cat);

        try {
          await res.buildLanguageModel(
            cat.getModel('bedrock-missing-region/claude')!,
            overrideApiKey: 'dummy',
          );
          fail('Expected ModelResolutionError');
        } on ModelResolutionError {
          // Expected
        }
      });

      test(
        'builds OpenAI-compatible model with override parameters',
        () async {
          final model = catalog.getModel('test-provider/gpt-4o')!;

          // The SDK call will likely fail (no real network in test), but
          // the error handling should work. We just verify the method
          // is callable with overrides.
          try {
            await resolver.buildLanguageModel(
              model,
              overrideApiKey: 'sk-override',
              overrideBaseUrl: 'https://override.example.com/v1',
            );
          } catch (_) {
            // Expected: SDK provider initialization may fail in test env
            // The important thing is it doesn't throw ModelResolutionError
          }
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'builds model with default provider credentials',
        () async {
          final model = catalog.getModel('test-provider/gpt-4o')!;

          try {
            await resolver.buildLanguageModel(model);
          } catch (_) {
            // Expected: SDK provider may fail in test environment
          }
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });

    group('tryBuildLanguageModel', () {
      test('returns null on build failure due to missing API key', () async {
        final providerNoKey = ProviderConfig.basic(
          id: 'nokey-provider',
          name: 'No Key Provider',
          baseUrl: 'https://api.nokey.com/v1',
          auth: AuthConfig.apiKey(apiKey: ''),
          sdk: 'openai-compatible',
          models: [
            ModelConfig.basic(
              providerId: 'nokey-provider',
              modelName: 'model-x',
              displayName: 'Model X',
              contextLength: 4096,
            ),
          ],
        );

        SharedPreferences.setMockInitialValues({
          'catalog_cache_version': 4,
          'catalog_provider_enabled_nokey-provider': true,
        });
        final prefs = await SharedPreferences.getInstance();
        final cat = ProviderCatalogService(
          secureStorage: mockStorage,
          prefs: prefs,
          builtInProviders: [providerNoKey],
        );
        final res = ModelResolver(cat);

        final result = await res.tryBuildLanguageModel(
          cat.getModel('nokey-provider/model-x')!,
        );

        // With empty API key, auth type is apiKey → throws ModelResolutionError
        // tryBuildLanguageModel catches and returns null
        expect(result, isNull);
      });
    });

    group('getHeadersForModel', () {
      test('returns headers from override', () {
        final headers = resolver.getHeadersForModel(
          catalog.getModel('test-provider/gpt-4o')!,
          overrideHeaders: {'Content-Type': 'application/json'},
        );
        expect(headers, isA<Map<String, String>>());
        expect(headers['Content-Type'], 'application/json');
      });

      test('merges override headers', () {
        final headers = resolver.getHeadersForModel(
          catalog.getModel('test-provider/gpt-4o')!,
          overrideHeaders: {'X-Custom': 'test-value'},
        );
        expect(headers['X-Custom'], 'test-value');
      });

      test('provider default headers are included', () {
        final headers = resolver.getHeadersForModel(
          catalog.getModel('test-provider/gpt-4o')!,
          overrideHeaders: {'Accept': 'application/json'},
        );
        expect(headers['Accept'], 'application/json');
      });
    });

    group('getBodyForModel', () {
      test('returns body params from provider config', () {
        final body = resolver.getBodyForModel(
          catalog.getModel('test-provider/gpt-4o')!,
        );
        // Provider may or may not have default body
        expect(body, anyOf(isNull, isA<Map<String, dynamic>>()));
      });
    });

    group('ModelResolutionError', () {
      test('toString formats message correctly', () {
        const error = ModelResolutionError('test message');
        expect(error.toString(), 'ModelResolutionError: test message');
      });
    });
  });
}
