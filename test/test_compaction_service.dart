import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/services/chat_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChatAiService extends ChatAiService {
  final String _fakeSummary;
  FakeChatAiService({String fakeSummary = '## Goal\n- Summary generated.'})
    : _fakeSummary = fakeSummary,
      super(
        modelFactory: (_) => throw StateError('Fake modelFactory not used'),
        headers: {},
      );

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
