import 'package:test/test.dart';
import 'package:chatorai/core/tools/doom_loop_detector.dart';

void main() {
  group('DoomLoopDetector', () {
    test('returns false for first 3 identical calls, true on 4th', () {
      final detector = DoomLoopDetector();
      final input = {'query': 'test'};

      expect(detector.check('session1', 'tool1', input), isFalse);
      expect(detector.check('session1', 'tool1', input), isFalse);
      expect(detector.check('session1', 'tool1', input), isFalse);
      expect(detector.check('session1', 'tool1', input), isTrue);
    });

    test('null sessionId is bucketed under a single key', () {
      final detector = DoomLoopDetector();
      final input = {'query': 'test'};

      expect(detector.check(null, 'tool1', input), isFalse);
      expect(detector.check(null, 'tool1', input), isFalse);
      expect(detector.check(null, 'tool1', input), isFalse);
      expect(detector.check(null, 'tool1', input), isTrue);
    });

    test('pruneSession removes that session history', () {
      final detector = DoomLoopDetector();
      final input = {'query': 'test'};

      detector.check('session1', 'tool1', input);
      detector.check('session2', 'tool1', input);

      detector.pruneSession('session1');

      // After pruning session1, session1 should start fresh
      expect(detector.check('session1', 'tool1', input), isFalse);
      // session2 should still be tracked (2nd call, still below threshold)
      expect(detector.check('session2', 'tool1', input), isFalse);
    });
  });
}
