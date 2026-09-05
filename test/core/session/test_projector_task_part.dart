import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/chat/chat/assistant_content.dart';
import 'package:chatorai/core/chat/chat/message_part.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'replayed subtask events anchor a completed AssistantTask to the real placeholder message',
    () {
      const parentSessionRaw = 'ses_test_parent';
      final sessionId = SessionID.fromString(parentSessionRaw);
      final t0 = DateTime.now();
      final events = <SessionEvent>[
        MessageAdded(
          sessionId: sessionId,
          messageId: 'msg_user',
          role: 'user',
          content: '/test hello',
          timestamp: t0,
        ),
        MessageAdded(
          sessionId: sessionId,
          messageId: 'msg_placeholder',
          role: 'assistant',
          content: '',
          timestamp: t0,
        ),
        TaskPartStarted(
          sessionId: sessionId,
          partId: 'task-1',
          description: 'Say hello',
          agent: 'general',
          taskSessionId: 'ses_child',
          timestamp: t0,
        ),
        TaskPartCompleted(
          sessionId: sessionId,
          partId: 'task-1',
          toolCallsCount: 0,
          timestamp: t0.add(const Duration(seconds: 5)),
        ),
        TaskCompleted(
          sessionId: sessionId,
          taskId: 'task-1',
          output: 'hello!',
          timestamp: t0.add(const Duration(seconds: 6)),
        ),
      ];

      final state = replayEvents(events);

      final tasks = state.parts.whereType<AssistantTask>().toList();
      expect(tasks, hasLength(1));
      expect(tasks.single.id, 'task-1');
      // The card must be bound to the REAL assistant placeholder the user sees,
      // not to a synthetic projector-generated message.
      expect(tasks.single.messageId, 'msg_placeholder');
      expect(tasks.single.state, ToolState.completed);
      expect(tasks.single.description, 'Say hello');
      expect(tasks.single.taskSessionId, 'ses_child');
    },
  );
}
