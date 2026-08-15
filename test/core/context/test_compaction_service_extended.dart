import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/core/context/completion_provider.dart';
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

class RecordingCompletionProvider implements CompletionProvider {
  RecordingCompletionProvider({this.fakeSummary = '## Goal\n- New summary.'});

  final String fakeSummary;
  int callCount = 0;
  List<Map<String, dynamic>> lastMessages = [];

  @override
  Future<String> generateCompletion({
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
  }) async {
    callCount++;
    lastMessages = List.of(messages);
    return fakeSummary;
  }
}

void main() {
  group('CompactionService.compact', () {
    test('returns original messages when count < 4', () async {
      final service = const CompactionService();
      final messages = [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      expect(result, equals(messages));
    });

    test('strips ephemeral system prompts in early return', () async {
      final service = const CompactionService();
      final messages = [
        {'role': 'system', 'content': 'Agent prompt'},
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      expect(result, [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
      ]);
    });

    test('preserves ## Goal compaction summary in early return', () async {
      final service = const CompactionService();
      final messages = [
        {'role': 'system', 'content': '## Goal\n- Previous summary'},
        {'role': 'user', 'content': 'Hi'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      expect(result, equals(messages));
    });

    test('strips ephemeral system prompts from tail in success path', () async {
      final service = const CompactionService();
      final messages = [
        {'role': 'user', 'content': 'Msg 0'},
        {'role': 'assistant', 'content': 'Msg 1'},
        {'role': 'user', 'content': 'Msg 2'},
        {'role': 'assistant', 'content': 'Msg 3'},
        {'role': 'system', 'content': 'Agent prompt'},
        {'role': 'user', 'content': 'Msg 4'},
        {'role': 'assistant', 'content': 'Msg 5'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      // summary + last 2 pairs (Msg 2..Msg 5); the ephemeral system prompt
      // inside the tail must be dropped.
      expect(result.length, 5);
      expect(result[0]['role'], 'assistant');
      expect(result[0]['isCompactionSummary'], isTrue);
      expect(result[0]['agent'], 'compaction');
      expect(result[0]['content'], contains('Summary generated'));
      expect(result[1]['content'], 'Msg 2');
      expect(result[4]['content'], 'Msg 5');
      expect(result.where((m) => m['role'] == 'system').length, 0);
      expect(result.where((m) => m['isCompactionSummary'] == true).length, 1);
    });

    test('compacts head into assistant summary and preserves tail', () async {
      final service = const CompactionService();
      final messages = List.generate(6, (i) {
        final role = i.isEven ? 'user' : 'assistant';
        return {'role': role, 'content': 'Msg $i'};
      });
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      expect(result.length, 5);
      expect(result[0]['role'], 'assistant');
      expect(result[0]['isCompactionSummary'], isTrue);
      expect(result[0]['agent'], 'compaction');
      expect(result[0]['content'], contains('Summary generated'));
      expect(result[1]['content'], 'Msg 2');
      expect(result[4]['content'], 'Msg 5');
    });

    test('compact with small tailTurns trims tail correctly', () async {
      final service = const CompactionService(tailTurns: 1);
      final messages = List.generate(8, (i) {
        final role = i.isEven ? 'user' : 'assistant';
        return {'role': role, 'content': 'Msg $i'};
      });
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      expect(result.length, lessThan(8));
      expect(result.first['role'], 'assistant');
      expect(result.first['isCompactionSummary'], isTrue);
    });

    test('strips system prompts from head before summarizing', () async {
      final service = const CompactionService();
      final provider = RecordingCompletionProvider();
      // tailTurns=2 keeps the last 4 user/assistant messages as the tail, so
      // the head is [2 system prompts + 3 user/assistant pairs] — the prompts
      // must be stripped before the LLM sees the head.
      final messages = [
        {'role': 'system', 'content': 'Agent prompt'},
        {'role': 'system', 'content': 'User system prompt'},
        {'role': 'user', 'content': 'Msg 0'},
        {'role': 'assistant', 'content': 'Msg 1'},
        {'role': 'user', 'content': 'Msg 2'},
        {'role': 'assistant', 'content': 'Msg 3'},
        {'role': 'user', 'content': 'Msg 4'},
        {'role': 'assistant', 'content': 'Msg 5'},
        {'role': 'user', 'content': 'Msg 6'},
        {'role': 'assistant', 'content': 'Msg 7'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: provider,
        model: 'test',
      );
      expect(provider.callCount, 1);
      final headText =
          provider.lastMessages.firstWhere(
                (m) => m['role'] == 'user',
              )['content']
              as String;
      expect(headText, isNot(contains('Agent prompt')));
      expect(headText, isNot(contains('User system prompt')));
      expect(headText, contains('[user]: Msg 0'));
      expect(headText, contains('[assistant]: Msg 1'));
      expect(result.first['isCompactionSummary'], isTrue);
    });

    test(
      'returns stripped messages without LLM when head is only system prompts',
      () async {
        final service = const CompactionService();
        final provider = RecordingCompletionProvider();
        final messages = [
          {'role': 'system', 'content': 'Agent prompt 1'},
          {'role': 'system', 'content': 'Agent prompt 2'},
          {'role': 'system', 'content': 'Agent prompt 3'},
          {'role': 'system', 'content': 'Agent prompt 4'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: provider,
          model: 'test',
        );
        expect(provider.callCount, 0);
        expect(result, isEmpty);
      },
    );

    test('finds previous summary by isCompactionSummary flag', () async {
      final service = const CompactionService();
      final provider = RecordingCompletionProvider();
      final messages = [
        {'role': 'user', 'content': 'Msg 0'},
        {'role': 'assistant', 'content': 'Msg 1'},
        {'role': 'user', 'content': 'Msg 2'},
        {'role': 'assistant', 'content': 'Msg 3'},
        {
          'role': 'assistant',
          'content': '## Goal\n- Old summary.',
          'isCompactionSummary': true,
          'agent': 'compaction',
        },
        {'role': 'user', 'content': 'Msg 4'},
        {'role': 'assistant', 'content': 'Msg 5'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: provider,
        model: 'test',
      );
      expect(provider.callCount, 1);
      final headText =
          provider.lastMessages.firstWhere(
                (m) => m['role'] == 'user',
              )['content']
              as String;
      expect(headText, contains('<previous-summary>'));
      expect(headText, contains('Old summary.'));
      expect(result.first['isCompactionSummary'], isTrue);
    });

    test('prune clears old tool outputs when pruneEnabled is true', () async {
      final service = const CompactionService(
        tailTurns: 2,
        pruneProtectTokens: 10,
        pruneEnabled: true,
      );
      final messages = [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
        {'role': 'user', 'content': 'Old user'},
        {'role': 'assistant', 'content': 'Old assistant'},
        {'role': 'tool', 'content': 'A' * 100},
        {'role': 'assistant', 'content': 'Done'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      final toolMsg = result.firstWhere((m) => m['role'] == 'tool');
      expect(toolMsg['content'], '[Old tool result content cleared]');
    });

    test('prune is skipped when pruneEnabled is false', () async {
      final service = const CompactionService(
        tailTurns: 2,
        pruneProtectTokens: 10,
        pruneEnabled: false,
      );
      final messages = [
        {'role': 'user', 'content': 'Hi'},
        {'role': 'assistant', 'content': 'Hello'},
        {'role': 'user', 'content': 'Old user'},
        {'role': 'assistant', 'content': 'Old assistant'},
        {'role': 'tool', 'content': 'A' * 100},
        {'role': 'assistant', 'content': 'Done'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
      );
      final toolMsg = result.firstWhere((m) => m['role'] == 'tool');
      expect(toolMsg['content'], 'A' * 100);
    });

    test('fromConfig reads tailTurns from config', () async {
      final service = CompactionService.fromConfig(
        const CompactionConfig(tailTurns: 3, prune: true),
      );
      expect(service.tailTurns, 3);
      expect(service.pruneEnabled, isTrue);
    });
  });
}
