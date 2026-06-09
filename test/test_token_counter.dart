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
  });
}
