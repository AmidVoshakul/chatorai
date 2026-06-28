import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/event_store.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';

void main() {
  late AppDatabase db;
  late EventStore store;
  late SessionID sid;
  late DateTime ts;

  setUp(() {
    db = AppDatabase.inMemory();
    store = EventStore(db);
    sid = SessionID.create();
    ts = DateTime(2025, 6, 15, 10, 30, 45);
  });

  tearDown(() async {
    await db.close();
  });

  group('EventStore serialization roundtrip', () {
    test('SessionCreated with all fields', () async {
      final parentId = SessionID.create();
      final permission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final event = SessionCreated(
        sessionId: sid,
        parentId: parentId,
        title: 'Test Session',
        agent: 'code-reviewer',
        modelRef: 'gpt-4',
        permission: permission,
        timestamp: ts,
      );

      await store.append(event);
      final events = await store.getEvents(sid);

      expect(events.length, 1);
      final restored = events.first as SessionCreated;
      expect(restored.sessionId, sid);
      expect(restored.parentId, parentId);
      expect(restored.title, 'Test Session');
      expect(restored.agent, 'code-reviewer');
      expect(restored.modelRef, 'gpt-4');
      expect(restored.permission, isNotNull);
      expect(restored.permission!.rules.length, 1);
      expect(restored.permission!.rules.first.permission, 'bash');
      expect(restored.timestamp, ts);
    });

    test('SessionCreated with null permission', () async {
      final event = SessionCreated(
        sessionId: sid,
        title: 'No Perm',
        timestamp: ts,
      );

      await store.append(event);
      final events = await store.getEvents(sid);
      final restored = events.first as SessionCreated;
      expect(restored.permission, isNull);
    });

    test('SessionArchived', () async {
      await store.append(SessionArchived(sessionId: sid, timestamp: ts));
      final events = await store.getEvents(sid);
      expect(events.first, isA<SessionArchived>());
      expect(events.first.sessionId, sid);
    });

    test('SessionAgentSwitched', () async {
      await store.append(
        SessionAgentSwitched(sessionId: sid, agent: 'explore', timestamp: ts),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as SessionAgentSwitched;
      expect(restored.agent, 'explore');
    });

    test('SessionModelSwitched', () async {
      await store.append(
        SessionModelSwitched(
          sessionId: sid,
          modelRef: 'claude-4',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as SessionModelSwitched;
      expect(restored.modelRef, 'claude-4');
    });

    test('MessageAdded', () async {
      await store.append(
        MessageAdded(
          sessionId: sid,
          messageId: 'msg-1',
          role: 'user',
          content: 'Hello world',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as MessageAdded;
      expect(restored.messageId, 'msg-1');
      expect(restored.role, 'user');
      expect(restored.content, 'Hello world');
    });

    test('TextStarted', () async {
      await store.append(
        TextStarted(sessionId: sid, messageId: 'msg-2', timestamp: ts),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as TextStarted;
      expect(restored.messageId, 'msg-2');
    });

    test('TextDelta', () async {
      await store.append(
        TextDelta(
          sessionId: sid,
          messageId: 'msg-2',
          delta: 'Hello',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as TextDelta;
      expect(restored.messageId, 'msg-2');
      expect(restored.delta, 'Hello');
    });

    test('TextEnded', () async {
      await store.append(
        TextEnded(
          sessionId: sid,
          messageId: 'msg-2',
          fullText: 'Hello world!',
          model: 'gpt-4',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as TextEnded;
      expect(restored.fullText, 'Hello world!');
      expect(restored.model, 'gpt-4');
    });

    test('TextEnded with null model', () async {
      await store.append(
        TextEnded(
          sessionId: sid,
          messageId: 'msg-2',
          fullText: 'No model',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as TextEnded;
      expect(restored.model, isNull);
    });

    test('ReasoningStarted', () async {
      await store.append(
        ReasoningStarted(sessionId: sid, messageId: 'msg-3', timestamp: ts),
      );
      final events = await store.getEvents(sid);
      expect(events.first, isA<ReasoningStarted>());
    });

    test('ReasoningDelta', () async {
      await store.append(
        ReasoningDelta(
          sessionId: sid,
          messageId: 'msg-3',
          delta: 'thinking...',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ReasoningDelta;
      expect(restored.delta, 'thinking...');
    });

    test('ReasoningEnded', () async {
      await store.append(
        ReasoningEnded(
          sessionId: sid,
          messageId: 'msg-3',
          fullReasoning: 'I need to...',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ReasoningEnded;
      expect(restored.fullReasoning, 'I need to...');
    });

    test('ToolInputStarted', () async {
      await store.append(
        ToolInputStarted(sessionId: sid, toolCallId: 'tc-1', timestamp: ts),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ToolInputStarted;
      expect(restored.toolCallId, 'tc-1');
    });

    test('ToolInputDelta', () async {
      await store.append(
        ToolInputDelta(
          sessionId: sid,
          toolCallId: 'tc-1',
          delta: '{"fi',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ToolInputDelta;
      expect(restored.delta, '{"fi');
    });

    test('ToolInputEnded', () async {
      await store.append(
        ToolInputEnded(
          sessionId: sid,
          toolCallId: 'tc-1',
          fullInput: '{"file": "test.dart"}',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ToolInputEnded;
      expect(restored.fullInput, '{"file": "test.dart"}');
    });

    test('ToolCalled', () async {
      await store.append(
        ToolCalled(
          sessionId: sid,
          toolCallId: 'tc-2',
          toolName: 'bash',
          input: {'command': 'ls'},
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ToolCalled;
      expect(restored.toolName, 'bash');
      expect(restored.input, {'command': 'ls'});
    });

    test('ToolSuccess', () async {
      await store.append(
        ToolSuccess(
          sessionId: sid,
          toolCallId: 'tc-2',
          outputText: 'file1.txt',
          durationMs: 150,
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ToolSuccess;
      expect(restored.outputText, 'file1.txt');
      expect(restored.durationMs, 150);
    });

    test('ToolFailed', () async {
      await store.append(
        ToolFailed(
          sessionId: sid,
          toolCallId: 'tc-3',
          error: 'Command not found',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ToolFailed;
      expect(restored.error, 'Command not found');
    });

    test('StepStarted', () async {
      await store.append(
        StepStarted(sessionId: sid, stepNumber: 1, timestamp: ts),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as StepStarted;
      expect(restored.stepNumber, 1);
    });

    test('StepEnded', () async {
      await store.append(
        StepEnded(
          sessionId: sid,
          stepNumber: 1,
          tokensInput: 100,
          tokensOutput: 50,
          tokensReasoning: 10,
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as StepEnded;
      expect(restored.tokensInput, 100);
      expect(restored.tokensOutput, 50);
      expect(restored.tokensReasoning, 10);
    });

    test('StepFailed', () async {
      await store.append(
        StepFailed(
          sessionId: sid,
          stepNumber: 2,
          error: 'Timeout',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as StepFailed;
      expect(restored.stepNumber, 2);
      expect(restored.error, 'Timeout');
    });

    test('CompactionStarted', () async {
      await store.append(CompactionStarted(sessionId: sid, timestamp: ts));
      final events = await store.getEvents(sid);
      expect(events.first, isA<CompactionStarted>());
    });

    test('CompactionEnded', () async {
      await store.append(
        CompactionEnded(
          sessionId: sid,
          summary: 'Conversation about X',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as CompactionEnded;
      expect(restored.summary, 'Conversation about X');
    });

    test('ChildSessionCreated', () async {
      final childId = SessionID.create();
      await store.append(
        ChildSessionCreated(
          sessionId: sid,
          parentSessionId: sid,
          childSessionId: childId,
          title: 'Sub-task',
          agent: 'general',
          modelRef: 'gpt-4',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as ChildSessionCreated;
      expect(restored.childSessionId, childId);
      expect(restored.title, 'Sub-task');
      expect(restored.agent, 'general');
      expect(restored.modelRef, 'gpt-4');
    });

    test('TaskStarted', () async {
      await store.append(
        TaskStarted(
          sessionId: sid,
          taskId: 'task-1',
          description: 'Review code',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as TaskStarted;
      expect(restored.taskId, 'task-1');
      expect(restored.description, 'Review code');
    });

    test('TaskCompleted', () async {
      await store.append(
        TaskCompleted(
          sessionId: sid,
          taskId: 'task-1',
          output: 'Code looks good',
          timestamp: ts,
        ),
      );
      final events = await store.getEvents(sid);
      final restored = events.first as TaskCompleted;
      expect(restored.taskId, 'task-1');
      expect(restored.output, 'Code looks good');
    });

    test('sequence is preserved on roundtrip', () async {
      await store.append(SessionCreated(sessionId: sid, timestamp: ts));
      await store.append(
        MessageAdded(
          sessionId: sid,
          messageId: 'm1',
          role: 'user',
          content: 'Hi',
          timestamp: ts,
        ),
      );
      await store.append(
        MessageAdded(
          sessionId: sid,
          messageId: 'm2',
          role: 'assistant',
          content: 'Hello',
          timestamp: ts,
        ),
      );

      final events = await store.getEvents(sid);
      expect(events[0].sequence, 1);
      expect(events[1].sequence, 2);
      expect(events[2].sequence, 3);
    });

    test('unknown event type throws on deserialize', () async {
      // Insert a raw row with an unknown type
      await db
          .into(db.events)
          .insert(
            EventsCompanion.insert(
              sessionId: sid.value,
              eventType: 'UnknownEvent',
              eventData: '{"type": "UnknownEvent"}',
              sequence: 1,
              createdAt: ts,
            ),
          );

      expect(() => store.getEvents(sid), throwsArgumentError);
    });
  });

  group('EventStore permission serialization', () {
    test('permission with both rules and sessionApproved', () async {
      final permission = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
          const PermissionRule(
            permission: 'read',
            pattern: '*.dart',
            action: PermissionAction.allow,
          ),
        ],
        sessionApproved: [
          const PermissionRule(
            permission: 'edit',
            pattern: 'lib/**',
            action: PermissionAction.allow,
          ),
        ],
      );

      final event = SessionCreated(
        sessionId: sid,
        permission: permission,
        timestamp: ts,
      );

      await store.append(event);
      final events = await store.getEvents(sid);
      final restored = events.first as SessionCreated;

      expect(restored.permission!.rules.length, 2);
      expect(restored.permission!.sessionApproved.length, 1);
      expect(restored.permission!.sessionApproved.first.permission, 'edit');
    });

    test('empty permission serializes to null', () async {
      final permission = PermissionRuleset(rules: [], sessionApproved: []);
      final event = SessionCreated(
        sessionId: sid,
        permission: permission,
        timestamp: ts,
      );

      await store.append(event);
      final events = await store.getEvents(sid);
      final restored = events.first as SessionCreated;

      // Empty rules + empty sessionApproved → serialized as null
      expect(restored.permission, isNull);
    });
  });
}
