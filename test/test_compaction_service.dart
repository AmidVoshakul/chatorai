import 'package:chatorai/core/context/completion_provider.dart';
import 'package:chatorai/core/context/compaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCompletionProvider implements CompletionProvider {
  const FakeCompletionProvider({
    this.fakeSummary = '## Goal\n- Summary generated.',
  });

  final String fakeSummary;

  @override
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  }) async {
    return fakeSummary;
  }
}

void main() {
  group('CompactionService', () {
    late CompactionService service;
    late FakeCompletionProvider fakeAi;

    setUp(() {
      service = const CompactionService();
      fakeAi = const FakeCompletionProvider();
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
