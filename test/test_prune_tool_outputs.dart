import 'package:chatorai/core/context/compaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompactionService.prune', () {
    test('returns original list when empty', () {
      final service = const CompactionService();
      expect(service.prune([]), equals(<Map<String, dynamic>>[]));
    });

    test('clears tool message older than prune window', () {
      final service = const CompactionService(pruneProtectTokens: 20);
      final messages = [
        {'role': 'user', 'content': 'msg 1'},
        {'role': 'assistant', 'content': 'msg 2'},
        {
          'role': 'tool',
          'content': 'this is a tool output that exceeds twenty chars',
        },
      ];
      final result = service.prune(messages);
      expect(result[0]['content'], 'msg 1');
      expect(result[1]['content'], 'msg 2');
      expect(result[2]['content'], '[Old tool result content cleared]');
    });

    test('preserves tool message within prune window', () {
      final service = const CompactionService(pruneProtectTokens: 9999);
      final messages = [
        {'role': 'user', 'content': 'hi'},
        {
          'role': 'tool',
          'content': 'short tool output',
        },
      ];
      final result = service.prune(messages);
      expect(result[1]['content'], 'short tool output');
    });

    test('does not mutate input list', () {
      final service = const CompactionService(pruneProtectTokens: 10);
      final original = [
        {'role': 'tool', 'content': 'a very long tool output that should be pruned'},
      ];
      final result = service.prune(original);
      expect(original[0]['content'], 'a very long tool output that should be pruned');
      expect(result[0]['content'], '[Old tool result content cleared]');
    });

    test('ignores non-tool messages outside window', () {
      final service = const CompactionService(pruneProtectTokens: 10);
      final messages = [
        {'role': 'user', 'content': 'a very long user message that exceeds the limit'},
      ];
      final result = service.prune(messages);
      expect(result[0]['content'],
          'a very long user message that exceeds the limit');
    });

    test('pruneProtectTokens parameter controls window size', () {
      final smallService = const CompactionService(pruneProtectTokens: 5);
      final largeService = const CompactionService(pruneProtectTokens: 9999);
      final messages = [
        {'role': 'tool', 'content': 'tool output that is definitely long enough'},
      ];
      expect(smallService.prune(messages)[0]['content'],
          '[Old tool result content cleared]');
      expect(largeService.prune(messages)[0]['content'],
          'tool output that is definitely long enough');
    });
  });
}
