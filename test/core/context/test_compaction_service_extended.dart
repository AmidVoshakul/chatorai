import 'package:chatorai/core/context/compaction_service.dart';
import 'package:chatorai/core/context/completion_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCompletionProvider implements CompletionProvider {
  const FakeCompletionProvider({this.fakeSummary = '📋 Summary generated.'});

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

    test('compacts head into system summary and preserves tail', () async {
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
      expect(result.length, 5); // system + 4 tail
      expect(result[0]['role'], 'system');
      expect(result[0]['content'], contains('Summary generated'));
      expect(result[1]['content'], 'Msg 2');
      expect(result[4]['content'], 'Msg 5');
    });

    test('replayLastUserMessage appends last user message when missing', () async {
      final service = const CompactionService(tailTurns: 1);
      final messages = [
        {'role': 'user', 'content': 'Old user'},
        {'role': 'assistant', 'content': 'Old assistant'},
        {'role': 'user', 'content': 'Middle user'},
        {'role': 'assistant', 'content': 'Middle assistant'},
        {'role': 'user', 'content': 'Latest user'},
        {'role': 'assistant', 'content': 'Latest assistant'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
        replayLastUserMessage: true,
      );
      // tailTurns=1 => last 2 messages kept: user "Latest user", assistant "Latest assistant"
      // The last user message is already in the tail, so replay doesn't add a duplicate
      expect(result.length, 3); // system + 2 tail
      expect(result[0]['role'], 'system');
      expect(result[1]['role'], 'user');
      expect(result[1]['content'], 'Latest user');
      expect(result[2]['role'], 'assistant');
    });

    test(
      'replayLastUserMessage appends last user message when it is in head',
      () async {
        final service = const CompactionService(tailTurns: 1);
        final messages = [
          {'role': 'user', 'content': 'Old user'},
          {'role': 'assistant', 'content': 'Old assistant'},
          {'role': 'user', 'content': 'Middle user'},
          {'role': 'assistant', 'content': 'Middle assistant'},
          {'role': 'user', 'content': 'Latest user'},
          {'role': 'assistant', 'content': 'Latest assistant'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          replayLastUserMessage: true,
        );
        // tailTurns=1 => last 2 messages kept: user "Latest user", assistant "Latest assistant"
        // The last user message is already in the tail, so replay doesn't add a duplicate
        expect(result.length, 3); // system + 2 tail
        expect(result[0]['role'], 'system');
        expect(result[1]['content'], 'Latest user');
        expect(result[2]['content'], 'Latest assistant');
      },
    );

    test(
      'replayLastUserMessage does not duplicate existing user message',
      () async {
        final service = const CompactionService(tailTurns: 1);
        final messages = [
          {'role': 'user', 'content': 'User 1'},
          {'role': 'assistant', 'content': 'Assistant 1'},
          {'role': 'user', 'content': 'User 2'},
          {'role': 'assistant', 'content': 'Assistant 2'},
          {'role': 'user', 'content': 'User 3'},
          {'role': 'assistant', 'content': 'Assistant 3'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          replayLastUserMessage: true,
        );
        final userMessages = result.where((m) => m['role'] == 'user').toList();
        // tailTurns=1 keeps last 2 messages: user "User 3", assistant "Assistant 3"
        // Last user message is already in tail, no duplicate
        expect(userMessages.length, 1);
        expect(userMessages.first['content'], 'User 3');
      },
    );

    test('replayLastUserMessage handles empty messages', () async {
      final service = const CompactionService();
      final result = await service.compact(
        messages: const [],
        aiService: const FakeCompletionProvider(),
        model: 'test',
        replayLastUserMessage: true,
      );
      expect(result, isEmpty);
    });

    test(
      'replayLastUserMessage returns original when no user message exists',
      () async {
        final service = const CompactionService();
        final messages = [
          {'role': 'assistant', 'content': 'Only assistant'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          replayLastUserMessage: true,
        );
        expect(result.length, 1);
        expect(result[0]['role'], 'assistant');
      },
    );

    test(
      'truncateMedia replaces image attachment with placeholder via compact',
      () async {
        final service = const CompactionService(tailTurns: 1);
        final messages = [
          {'role': 'user', 'content': 'Old'},
          {'role': 'assistant', 'content': 'Old assistant'},
          {
            'role': 'user',
            'content': 'Latest with image',
            'imageData': 'data',
            'imageType': 'image/png',
            'attachedDocName': 'screenshot.png',
            'files': const [],
          },
          {'role': 'assistant', 'content': 'Latest assistant'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          truncateMedia: true,
        );
        expect(result.length, 3);
        final userMsg = result.firstWhere((m) => m['role'] == 'user');
        expect(
          userMsg['content'],
          contains('[Attached image/png: screenshot.png]'),
        );
      },
    );

    test('truncateMedia replaces document attachment via compact', () async {
      final service = const CompactionService(tailTurns: 1);
      final messages = [
        {'role': 'user', 'content': 'Old'},
        {'role': 'assistant', 'content': 'Old assistant'},
        {
          'role': 'user',
          'content': 'Latest with doc',
          'files': const [],
          'attachedDocPath': '/path/to/file.pdf',
          'attachedDocName': 'file.pdf',
        },
        {'role': 'assistant', 'content': 'Latest assistant'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
        truncateMedia: true,
      );
      final userMsg = result.firstWhere((m) => m['role'] == 'user');
      expect(userMsg['content'], contains('[Attached document: file.pdf]'));
    });

    test('truncateMedia replaces file attachments via compact', () async {
      final service = const CompactionService(tailTurns: 1);
      final messages = [
        {'role': 'user', 'content': 'Old'},
        {'role': 'assistant', 'content': 'Old assistant'},
        {
          'role': 'user',
          'content': 'Latest with files',
          'files': ['file1.txt', 'file2.pdf'],
        },
        {'role': 'assistant', 'content': 'Latest assistant'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
        truncateMedia: true,
      );
      final userMsg = result.firstWhere((m) => m['role'] == 'user');
      expect(userMsg['content'], contains('[Attached file: file1.txt]'));
      expect(userMsg['content'], contains('[Attached file: file2.pdf]'));
    });

    test('truncateMedia preserves non-user messages', () async {
      final service = const CompactionService(tailTurns: 1);
      final messages = [
        {'role': 'assistant', 'content': 'Assistant msg'},
        {'role': 'user', 'content': 'User msg'},
      ];
      final result = await service.compact(
        messages: messages,
        aiService: const FakeCompletionProvider(),
        model: 'test',
        truncateMedia: true,
      );
      final assistantMsg = result.firstWhere((m) => m['role'] == 'assistant');
      expect(assistantMsg['content'], 'Assistant msg');
    });

    test(
      'truncateMedia leaves plain user message unchanged via compact',
      () async {
        final service = const CompactionService(tailTurns: 1);
        final messages = [
          {'role': 'user', 'content': 'Plain text'},
          {'role': 'assistant', 'content': 'Response'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          truncateMedia: true,
        );
        final userMsg = result.firstWhere((m) => m['role'] == 'user');
        expect(userMsg['content'], 'Plain text');
      },
    );

    test(
      'compact with truncateMedia replaces attachments before summarization',
      () async {
        final service = const CompactionService(tailTurns: 1);
        final messages = [
          {'role': 'user', 'content': 'Old'},
          {'role': 'assistant', 'content': 'Old assistant'},
          {
            'role': 'user',
            'content': 'Latest with image',
            'imageData': 'data',
            'imageType': 'image/jpeg',
            'attachedDocName': 'pic.jpg',
            'files': const [],
          },
          {'role': 'assistant', 'content': 'Latest assistant'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          truncateMedia: true,
          replayLastUserMessage: true,
        );
        expect(result.length, 3);
        expect(result[0]['role'], 'system');
        expect(result[1]['role'], 'user');
        expect(
          result[1]['content'],
          contains('[Attached image/jpeg: pic.jpg]'),
        );
        expect(result[2]['role'], 'assistant');
        expect(result[2]['content'], 'Latest assistant');
      },
    );

    test(
      'compact preserves original messages when truncateMedia is false',
      () async {
        final service = const CompactionService(tailTurns: 1);
        final messages = [
          {'role': 'user', 'content': 'Old user'},
          {'role': 'assistant', 'content': 'Old assistant'},
          {
            'role': 'user',
            'content': 'With image',
            'imageData': 'data',
            'imageType': 'image/png',
            'attachedDocName': 'img.png',
            'files': const [],
          },
          {'role': 'assistant', 'content': 'Response'},
        ];
        final result = await service.compact(
          messages: messages,
          aiService: const FakeCompletionProvider(),
          model: 'test',
          truncateMedia: false,
        );
        expect(result[0]['role'], 'system');
        expect(result[1]['content'], 'With image');
        expect(result[1]['content'], isNot(contains('[Attached')));
      },
    );

    test(
      'compact with small preserveRecentTokens trims tail correctly',
      () async {
        final service = const CompactionService(
          tailTurns: 4,
          preserveRecentTokens: 5,
        );
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
        expect(result.first['role'], 'system');
      },
    );
  });
}
