import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/chat/services/chat_ai_service.dart';
import 'package:chatorai/core/llm/model_resolver.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class _FakeChatAiService extends ChatAiService {
  _FakeChatAiService() : super(resolver: _createFakeResolver());

  static ModelResolver _createFakeResolver() {
    final mockSecureStorage = MockSecureStorageService();
    final mockPrefs = MockSharedPreferences();

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

  @override
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  }) async {
    // Simulate model responses for cleaning tests.
    final prompt = messages.single['content'] as String;
    if (prompt.contains('boom')) {
      throw Exception('model unavailable');
    }
    if (prompt.contains('long')) {
      return 'This is a very long title that definitely exceeds sixty characters limit';
    }
    if (prompt.contains('think')) {
      return '<think>some reasoning</think>\nReal title here';
    }
    if (prompt.contains('empty')) {
      return '   \n\n   ';
    }
    return 'Short title';
  }
}

void main() {
  group('ChatAiService.generateSessionTitle', () {
    test('cleans and truncates long titles to ~60 chars', () async {
      final service = _FakeChatAiService();
      final result = await service.generateSessionTitle(
        modelId: 'any',
        userMessage: 'long',
      );

      expect(result, isNotNull);
      expect(result.length, lessThanOrEqualTo(60));
      expect(result, isNot(contains('think')));
    });

    test('strips think tags and trims whitespace', () async {
      final service = _FakeChatAiService();
      final result = await service.generateSessionTitle(
        modelId: 'any',
        userMessage: 'think',
      );

      expect(result, 'Real title here');
    });

    test(
      'falls back to the user message when cleaned title is empty',
      () async {
        final service = _FakeChatAiService();
        final result = await service.generateSessionTitle(
          modelId: 'any',
          userMessage: 'empty',
        );

        expect(result, 'empty');
      },
    );

    test('falls back to the user message when the model call fails', () async {
      final service = _FakeChatAiService();
      final result = await service.generateSessionTitle(
        modelId: 'any',
        userMessage: 'boom fallback title',
      );

      expect(result, 'boom fallback title');
    });

    test(
      'falls back to the truncated user message when it exceeds 60 chars',
      () async {
        final service = _FakeChatAiService();
        final result = await service.generateSessionTitle(
          modelId: 'any',
          userMessage: 'a' * 100,
        );

        expect(result.length, lessThanOrEqualTo(60));
      },
    );

    test('returns a short title for normal input', () async {
      final service = _FakeChatAiService();
      final result = await service.generateSessionTitle(
        modelId: 'any',
        userMessage: 'Hello world',
      );

      expect(result, 'Short title');
    });
  });
}
