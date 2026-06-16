import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/core/llm/catalog/model_resolver.dart';
import 'package:chatorai/core/llm/catalog/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:chatorai/features/chat/domain/services/chat_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class FakeChatAiService extends ChatAiService {
  FakeChatAiService({String fakeSummary = '## Goal\n- Summary generated.'})
    : _fakeSummary = fakeSummary,
      super(resolver: _createFakeResolver(), headers: {});

  final String _fakeSummary;

  static ModelResolver _createFakeResolver() {
    final mockSecureStorage = MockSecureStorageService();
    final mockPrefs = MockSharedPreferences();
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
    return _fakeSummary;
  }
}

void main() {
  group('CompactionService', () {
    late CompactionService service;
    late FakeChatAiService fakeAi;

    setUp(() {
      service = const CompactionService();
      fakeAi = FakeChatAiService();
    });

    test('returns original messages when count < 4', () async {
      final messages = [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: fakeAi,
        model: 'test',
      );
      expect(result, equals(messages));
    });

    test('compacts head into system summary and preserves tail', () async {
      final messages = List.generate(6, (i) {
        final role = i.isEven ? 'user' : 'assistant';
        return {'role': role, 'content': 'Msg $i'};
      });
      final result = await service.compact(
        messages: messages,
        aiService: fakeAi,
        model: 'test',
      );
      // tailTurns=2 => last 4 messages kept, head (2 pairs) replaced by system
      expect(result.length, 5); // system + 4 tail
      expect(result[0]['role'], 'system');
      expect(result[0]['content'], contains('Summary generated'));
      expect(result[1]['content'], 'Msg 2');
      expect(result[4]['content'], 'Msg 5');
    });
  });
}
