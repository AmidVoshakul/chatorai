/// TDD: a [ToolCallTracker] guarantees that every tool that received
/// `onToolStart` eventually receives a terminal `onToolEnd`/`onToolError`.
///
/// The underlying `ai_sdk_dart` `streamText` step loop executes the tool
/// calls of a single assistant step sequentially. When one tool executor
/// throws, `_executeToolCall` rethrows, breaking the loop, so sibling tool
/// calls that come AFTER the failing one are never executed and never emit a
/// terminal event — even though their `onToolStart` already fired. This left
/// their `AssistantTool` parts stuck in `ToolState.running` (infinite spinner
/// in the UI). The tracker restores the invariant by finalizing any tool that
/// started but never finished.
import 'package:chatorai/features/chat/services/tool_call_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCallTracker', () {
    test('finalizeDangling reports every tool started but not ended', () {
      final tracker = ToolCallTracker();
      tracker.markStarted('c1', 'shell', DateTime(2024));
      tracker.markStarted('c2', 'grep', DateTime(2024));
      tracker.markStarted('c3', 'read', DateTime(2024));

      // c2 completes normally, c3 errors → only c1 is dangling.
      tracker.markEnded('c2');
      tracker.markErrored('c3');

      final errors = <(String, String)>[];
      tracker.finalizeDangling((id, name) => errors.add((id, name)));

      expect(
        errors,
        equals([('c1', 'shell')]),
        reason: 'only c1 was started and never finalized',
      );
    });

    test('finalizeDangling is idempotent — cleared after finalize', () {
      final tracker = ToolCallTracker();
      tracker.markStarted('c1', 'shell', DateTime(2024));

      final first = <String>[];
      tracker.finalizeDangling((id, _) => first.add(id));

      final second = <String>[];
      tracker.finalizeDangling((id, _) => second.add(id));

      expect(first, equals(['c1']));
      expect(second, isEmpty, reason: 'no tool stays dangling forever');
    });

    test('tool started and ended is not reported as dangling', () {
      final tracker = ToolCallTracker();
      tracker.markStarted('c1', 'shell', DateTime(2024));
      tracker.markEnded('c1');

      final errors = <String>[];
      tracker.finalizeDangling((id, _) => errors.add(id));

      expect(errors, isEmpty);
    });

    test('markErrored then finalizeDangling is a no-op for that tool', () {
      final tracker = ToolCallTracker();
      tracker.markStarted('c1', 'shell', DateTime(2024));
      tracker.markErrored('c1');

      final errors = <String>[];
      tracker.finalizeDangling((id, _) => errors.add(id));

      expect(errors, isEmpty);
    });

    test('markStarted dedups the same toolCallId', () {
      final tracker = ToolCallTracker();
      tracker.markStarted('c1', 'shell', DateTime(2024, 1));
      tracker.markStarted('c1', 'shell', DateTime(2024, 2));

      final errors = <String>[];
      tracker.finalizeDangling((id, _) => errors.add(id));

      expect(errors, equals(['c1']), reason: 'duplicated start counts once');
    });
  });
}
