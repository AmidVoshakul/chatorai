import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AssistantTask round-trips through partsJson maps', () {
    final started = DateTime.utc(2026, 1, 1, 12);
    final ended = started.add(const Duration(seconds: 7));
    final task = AssistantTask(
      id: 'task-1',
      sessionId: 'ses_parent',
      messageId: 'msg_placeholder',
      description: 'Say hello',
      agent: 'general',
      state: ToolState.completed,
      taskSessionId: 'ses_child',
      toolCallsCount: 2,
      startedAt: started,
      endedAt: ended,
    );

    final map = task.toJson();
    expect(map['type'], 'task');

    final restored = AssistantTask.fromJson(map);

    expect(restored.id, task.id);
    expect(restored.sessionId, task.sessionId);
    // The card stays bound to the assistant bubble it was created under.
    expect(restored.messageId, 'msg_placeholder');
    expect(restored.description, task.description);
    expect(restored.agent, task.agent);
    expect(restored.state, ToolState.completed);
    expect(restored.taskSessionId, 'ses_child');
    expect(restored.toolCallsCount, 2);
    expect(restored.startedAt, started);
    expect(restored.endedAt, ended);
  });

  test('running state survives a round-trip without end timestamp', () {
    final task = AssistantTask(
      id: 'task-2',
      sessionId: 'ses_parent',
      messageId: 'msg_placeholder',
      description: 'Explore',
      agent: 'explore',
      state: ToolState.running,
    );

    final restored = AssistantTask.fromJson(task.toJson());

    expect(restored.state, ToolState.running);
    expect(restored.endedAt, isNull);
    expect(restored.toolCallsCount, 0);
  });
}
