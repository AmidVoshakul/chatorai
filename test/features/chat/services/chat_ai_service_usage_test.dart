import 'package:flutter_test/flutter_test.dart';
import 'package:ai_sdk_provider/ai_sdk_provider.dart';
import 'package:chatorai/features/chat/services/chat_ai_service.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorageService {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

class _TestableChatAiService extends ChatAiService {
  _TestableChatAiService() : super(resolver: _createFakeResolver());

  static ModelResolver _createFakeResolver() {
    final mockSecureStorage = _MockSecureStorage();
    final mockPrefs = _MockSharedPreferences();

    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getInt(any())).thenReturn(null);

    final catalog = ProviderCatalogService(
      secureStorage: mockSecureStorage,
      prefs: mockPrefs,
      builtInProviders: [],
    );
    return ModelResolver(catalog);
  }
}

void main() {
  group('ChatAiService.resolveUsage', () {
    late _TestableChatAiService service;

    setUp(() {
      service = _TestableChatAiService();
    });

    test('prefers captured raw usage over SDK buckets', () {
      final rawUsage = {
        'prompt_tokens': 13261,
        'completion_tokens': 100,
        'prompt_tokens_details': {'cached_tokens': 11520},
        'cache_creation_input_tokens': 0,
        'completion_tokens_details': {'reasoning_tokens': 27},
      };
      final sdkUsage = LanguageModelV4Usage(
        inputTokens: const LanguageModelV4InputTokenUsage(
          total: 500,
          cacheRead: 0,
          cacheWrite: 0,
        ),
        outputTokens: const LanguageModelV4OutputTokenUsage(
          total: 50,
          reasoning: 0,
        ),
      );

      final resolved = service.resolveUsage(sdkUsage, rawUsage);

      expect(resolved['inputTotal'], 13261);
      expect(resolved['outputTotal'], 100);
      expect(resolved['cacheRead'], 11520);
      expect(resolved['cacheWrite'], 0);
      expect(resolved['reasoning'], 27);
    });

    test('falls back to SDK buckets when raw usage is absent', () {
      final sdkUsage = LanguageModelV4Usage(
        inputTokens: const LanguageModelV4InputTokenUsage(
          total: 500,
          cacheRead: 100,
          cacheWrite: 50,
        ),
        outputTokens: const LanguageModelV4OutputTokenUsage(
          total: 50,
          reasoning: 10,
        ),
      );

      final resolved = service.resolveUsage(sdkUsage, null);

      expect(resolved['inputTotal'], 500);
      expect(resolved['outputTotal'], 50);
      expect(resolved['cacheRead'], 100);
      expect(resolved['cacheWrite'], 50);
      expect(resolved['reasoning'], 10);
    });

    test('falls back to SDK buckets when raw usage is empty map', () {
      final sdkUsage = LanguageModelV4Usage(
        inputTokens: const LanguageModelV4InputTokenUsage(
          total: 500,
          cacheRead: 100,
          cacheWrite: 50,
        ),
        outputTokens: const LanguageModelV4OutputTokenUsage(
          total: 50,
          reasoning: 10,
        ),
      );

      final resolved = service.resolveUsage(
        sdkUsage,
        const <String, dynamic>{},
      );

      expect(resolved['inputTotal'], 500);
      expect(resolved['outputTotal'], 50);
      expect(resolved['cacheRead'], 100);
      expect(resolved['cacheWrite'], 50);
      expect(resolved['reasoning'], 10);
    });

    test('handles null SDK usage with raw usage present', () {
      final rawUsage = {
        'prompt_tokens': 1000,
        'completion_tokens': 200,
        'prompt_tokens_details': {'cached_tokens': 800},
        'completion_tokens_details': {'reasoning_tokens': 15},
      };

      final resolved = service.resolveUsage(null, rawUsage);

      expect(resolved['inputTotal'], 1000);
      expect(resolved['outputTotal'], 200);
      expect(resolved['cacheRead'], 800);
      expect(resolved['cacheWrite'], 0);
      expect(resolved['reasoning'], 15);
    });

    test('returns zeros when both SDK usage and raw usage are absent', () {
      final resolved = service.resolveUsage(null, null);

      expect(resolved['inputTotal'], 0);
      expect(resolved['outputTotal'], 0);
      expect(resolved['cacheRead'], 0);
      expect(resolved['cacheWrite'], 0);
      expect(resolved['reasoning'], 0);
    });

    test('OpenRouter-style raw map with input_tokens/output_tokens', () {
      final rawUsage = {
        'input_tokens': 5000,
        'output_tokens': 200,
        'input_tokens_details': {'cached_tokens': 3000},
        'completion_tokens_details': {'reasoning_tokens': 50},
      };
      final sdkUsage = const LanguageModelV4Usage(
        inputTokens: LanguageModelV4InputTokenUsage(
          total: 0,
          cacheRead: 0,
          cacheWrite: 0,
        ),
        outputTokens: LanguageModelV4OutputTokenUsage(total: 0, reasoning: 0),
      );

      final resolved = service.resolveUsage(sdkUsage, rawUsage);

      expect(resolved['inputTotal'], 5000);
      expect(resolved['outputTotal'], 200);
      expect(resolved['cacheRead'], 3000);
      expect(resolved['cacheWrite'], 0);
      expect(resolved['reasoning'], 50);
    });
  });
}
