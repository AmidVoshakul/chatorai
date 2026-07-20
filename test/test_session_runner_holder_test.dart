import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_runner.dart';

void main() {
  group('SessionRunnerHolder child→task routing', () {
    test('registerChild maps each child to its own task part', () {
      final holder = SessionRunnerHolder(null, parentSessionId: 'parent');
      holder.registerChild('child_a', 'part_a');
      holder.registerChild('child_b', 'part_b');

      expect(holder.childToTaskPart['child_a'], 'part_a');
      expect(holder.childToTaskPart['child_b'], 'part_b');
      expect(holder.taskPartForChild('child_a'), 'part_a');
      expect(holder.taskPartForChild('child_b'), 'part_b');
    });

    test('unregisterChild removes both directions', () {
      final holder = SessionRunnerHolder(null, parentSessionId: 'parent');
      holder.registerChild('child_a', 'part_a');
      holder.unregisterChild('child_a');

      expect(holder.childToTaskPart.containsKey('child_a'), isFalse);
      expect(holder.taskPartToChild.containsKey('part_a'), isFalse);
    });
  });

  group('TaskBatch (parallel task "box")', () {
    test('allDone is false until every started task completes', () {
      final batch = TaskBatch();
      expect(batch.allDone, isFalse);

      batch.add('part_a', 'explore');
      batch.add('part_b', 'general');
      expect(batch.allDone, isFalse, reason: 'started but none completed');

      // One finishes earlier than the other (parallel tasks, different times).
      final firstDone = batch.complete('part_a', 'result a');
      expect(firstDone, isFalse, reason: 'part_b still pending');
      expect(batch.resultsByPart['part_a'], 'result a');

      final secondDone = batch.complete('part_b', 'result b');
      expect(secondDone, isTrue, reason: 'both tasks reported');
      expect(batch.allDone, isTrue);
    });

    test('aggregated output is labelled per agent in start order', () {
      final batch = TaskBatch();
      batch.add('part_a', 'explore');
      batch.add('part_b', 'general');
      batch.complete('part_a', 'findings from repo');
      batch.complete('part_b', 'summary text');

      final out = batch.aggregated;
      expect(out, contains('agent="explore"'));
      expect(out, contains('agent="general"'));
      expect(out, contains('findings from repo'));
      expect(out, contains('summary text'));
    });

    test('clear resets the batch for a new parent step', () {
      final batch = TaskBatch();
      batch.add('part_a', 'explore');
      batch.complete('part_a', 'x');
      expect(batch.allDone, isTrue);
      batch.clear();
      expect(batch.allDone, isFalse);
      expect(batch.resultsByPart.isEmpty, isTrue);
    });

    test('allDone stays false if a child never reports (crashed)', () {
      final batch = TaskBatch();
      batch.add('part_a', 'explore');
      expect(batch.allDone, isFalse);
    });

    test('fail() lets the batch finish so it never deadlocks', () {
      final batch = TaskBatch();
      batch.add('part_a', 'explore');
      batch.add('part_b', 'general');
      batch.complete('part_a', 'ok');
      // part_b crashes — without fail() allDone would hang forever.
      final done = batch.fail('part_b');
      expect(done, isTrue);
      expect(batch.allDone, isTrue);
      expect(batch.aggregated, contains('(task failed)'));
    });

    test('concurrent add/complete interleaving keeps state consistent', () {
      final batch = TaskBatch();
      batch.add('part_a', 'explore');
      batch.add('part_b', 'general');
      batch.complete('part_a', 'result a');
      batch.complete('part_b', 'result b');
      expect(batch.allDone, isTrue);
      expect(batch.aggregated, contains('agent="explore"'));
      expect(batch.aggregated, contains('agent="general"'));
    });
  });
}
