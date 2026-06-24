import 'package:chatorai/core/context/token_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TokenCounter', () {
    test('estimate returns max(0, length ~/ 4)', () {
      expect(TokenCounter.estimate(''), 0);
      expect(TokenCounter.estimate('a'), 0); // 1/4=0.25 floor 0
      expect(TokenCounter.estimate('abcd'), 1); // 4/4=1
      expect(TokenCounter.estimate('abcde'), 1); // 5/4=1.25 floor 1
      expect(TokenCounter.estimate('abcdefgh'), 2); // 8/4=2
    });

    test('recordUsage accumulates totalTokens', () {
      final tc = TokenCounter();
      tc.recordUsage(promptTokens: 100, completionTokens: 50);
      expect(tc.totalTokens, 150);
      tc.recordUsage(promptTokens: 10, completionTokens: 5);
      expect(tc.totalTokens, 165);
    });

    test('recordUsage accumulates cache tokens', () {
      final tc = TokenCounter();
      tc.recordUsage(
        promptTokens: 100,
        completionTokens: 50,
        cacheReadTokens: 200,
        cacheWriteTokens: 30,
      );
      expect(tc.totalTokens, 380);
      expect(tc.cacheReadTokens, 200);
      expect(tc.cacheWriteTokens, 30);
    });

    test('addCacheRead and addCacheWrite update totals', () {
      final tc = TokenCounter();
      tc.addCacheRead(500);
      tc.addCacheWrite(100);
      expect(tc.cacheReadTokens, 500);
      expect(tc.cacheWriteTokens, 100);
      expect(tc.totalTokens, 600);
    });

    test('reset clears all buckets including cache', () {
      final tc = TokenCounter();
      tc.addSystem('system prompt');
      tc.addMessage('user message');
      tc.addOutput(50);
      tc.addCacheRead(200);
      tc.addCacheWrite(50);
      expect(tc.totalTokens, greaterThan(0));
      tc.reset();
      expect(tc.totalTokens, 0);
      expect(tc.cacheReadTokens, 0);
      expect(tc.cacheWriteTokens, 0);
    });

    test('addOutput clamps negative values to zero', () {
      final tc = TokenCounter();
      tc.addOutput(-5);
      expect(tc.outputTokens, 0);
    });
  });
}
