import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';

void main() {
  group('projectEvent', () {
    late SessionID id;
    late SessionState empty;

    setUp(() {
      id = SessionID.create();
      final created = SessionCreated(sessionId: id, timestamp: DateTime.now());
      empty = SessionState(
        id: id,
        createdAt: created.timestamp,
        updatedAt: created.timestamp,
      );
    });

    test('SessionCreated creates initial state', () {
      final created = SessionCreated(
        sessionId: id,
        title: 'Test',
        agent: 'explore',
        modelRef: 'gpt-4',
        timestamp: DateTime.now(),
      );
      final state = projectEvent(empty, created);

      expect(state.id, id);
      expect(state.parentId, isNull);
      expect(state.title, 'Test');
      expect(state.agent, 'explore');
      expect(state.modelRef, 'gpt-4');
      expect(state.messages, isEmpty);
      expect(state.toolResults, isEmpty);
    });

    test('MessageAdded appends message', () {
      final event = MessageAdded(
        sessionId: id,
        messageId: 'msg_1',
        role: 'user',
        content: 'Hello',
        timestamp: DateTime.now(),
      );
      final state = projectEvent(empty, event);

      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'Hello');
      expect(state.messages.first.role, MessageRole.user);
      expect(state.messages.first.seq, 1);
    });

    test('TextEnded updates message content and model', () {
      var state = projectEvent(
        empty,
        TextStarted(
          sessionId: id,
          messageId: 'msg_2',
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        TextDelta(
          sessionId: id,
          messageId: 'msg_2',
          delta: 'Hel',
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        TextEnded(
          sessionId: id,
          messageId: 'msg_2',
          fullText: 'Hello!',
          model: 'gpt-4',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'Hello!');
      expect(state.messages.first.model, 'gpt-4');
    });

    test('ReasoningEnded updates reasoning', () {
      var state = projectEvent(
        empty,
        TextStarted(
          sessionId: id,
          messageId: 'msg_1',
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        ReasoningStarted(
          sessionId: id,
          messageId: 'msg_1',
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'msg_1',
          delta: 'Think...',
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        ReasoningEnded(
          sessionId: id,
          messageId: 'msg_1',
          fullReasoning: 'Thought process',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.reasoning, 'Thought process');
    });

    test('ToolCalled creates tool message', () {
      final state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_1',
          toolName: 'bash',
          input: {'cmd': 'ls'},
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.role, MessageRole.tool);
      expect(state.messages.first.content, contains('ls'));
    });

    test('ToolSuccess updates message and adds ToolResult', () {
      var state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_1',
          toolName: 'bash',
          input: {},
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        ToolSuccess(
          sessionId: id,
          toolCallId: 'tc_1',
          outputText: 'result',
          durationMs: 100,
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'result');
      expect(state.toolResults.length, 1);
      expect(state.toolResults.first.status, 'success');
      expect(state.toolResults.first.durationMs, 100);
    });

    test('ToolFailed adds error to message', () {
      var state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_1',
          toolName: 'bash',
          input: {},
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        ToolFailed(
          sessionId: id,
          toolCallId: 'tc_1',
          error: 'Command failed',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.first.error, 'Command failed');
      expect(state.toolResults.first.status, 'error');
    });

    test('StepEnded accumulates tokens additively', () {
      var state = projectEvent(
        empty,
        StepEnded(
          sessionId: id,
          stepNumber: 1,
          tokensInput: 100,
          tokensOutput: 50,
          tokensReasoning: 10,
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        StepEnded(
          sessionId: id,
          stepNumber: 2,
          tokensInput: 200,
          tokensOutput: 100,
          tokensReasoning: 20,
          timestamp: DateTime.now(),
        ),
      );

      expect(state.tokensInput, 300);
      expect(state.tokensOutput, 150);
      expect(state.tokensReasoning, 30);
    });

    test('SessionArchived sets archivedAt', () {
      final state = projectEvent(
        empty,
        SessionArchived(sessionId: id, timestamp: DateTime.now()),
      );

      expect(state.archivedAt, isNotNull);
    });

    test('SessionModelSwitched updates modelRef', () {
      final state = projectEvent(
        empty,
        SessionModelSwitched(
          sessionId: id,
          modelRef: 'claude-4',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.modelRef, 'claude-4');
    });

    test('StepFailed updates updatedAt', () {
      final before = empty.updatedAt;
      final state = projectEvent(
        empty,
        StepFailed(
          sessionId: id,
          stepNumber: 1,
          error: 'timeout',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.updatedAt.isAfter(before), isTrue);
    });

    test('CompactionEnded updates updatedAt', () {
      final state = projectEvent(
        empty,
        CompactionEnded(
          sessionId: id,
          summary: 'compressed',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.updatedAt, isNotNull);
    });

    test('TextStarted creates empty message placeholder', () {
      final state = projectEvent(
        empty,
        TextStarted(sessionId: id, messageId: 'm1', timestamp: DateTime.now()),
      );
      expect(state.messages.length, 1);
      expect(state.messages.first.content, '');
      expect(state.messages.first.role, MessageRole.assistant);
    });

    test('TextDelta does not change message count', () {
      var state = projectEvent(
        empty,
        TextStarted(sessionId: id, messageId: 'm1', timestamp: DateTime.now()),
      );
      state = projectEvent(
        state,
        TextDelta(
          sessionId: id,
          messageId: 'm1',
          delta: 'Hello',
          timestamp: DateTime.now(),
        ),
      );
      expect(state.messages.length, 1);
    });

    // ── Phase 3 coverage ─────────────────────────────────────────────────
    test(
      'TextEnded correctly updates content when TextStarted pre-created the message',
      () {
        var state = projectEvent(
          empty,
          TextStarted(
            sessionId: id,
            messageId: 'msg_chain',
            timestamp: DateTime.now(),
          ),
        );
        expect(state.messages.length, 1);
        expect(state.messages.first.content, '');

        state = projectEvent(
          state,
          TextEnded(
            sessionId: id,
            messageId: 'msg_chain',
            fullText: 'Final response text',
            model: 'gpt-4',
            timestamp: DateTime.now(),
          ),
        );

        expect(state.messages.length, 1);
        expect(state.messages.first.content, 'Final response text');
        expect(state.messages.first.model, 'gpt-4');
      },
    );

    test('ToolCalled → ToolSuccess flow publishes correctly', () {
      var state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_full',
          toolName: 'bash',
          input: {'cmd': 'ls -la'},
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.role, MessageRole.tool);
      expect(state.messages.first.content, contains('ls -la'));

      state = projectEvent(
        state,
        ToolSuccess(
          sessionId: id,
          toolCallId: 'tc_full',
          outputText: 'total 42\n-rw-r--r-- 1 file',
          durationMs: 150,
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'total 42\n-rw-r--r-- 1 file');
      expect(state.toolResults.length, 1);
      expect(state.toolResults.first.status, 'success');
      expect(state.toolResults.first.durationMs, 150);
      expect(state.toolResults.first.outputText, 'total 42\n-rw-r--r-- 1 file');
    });

    test(
      'Full chain replay (MessageAdded → TextStarted → TextDelta → TextEnded) produces correct state',
      () {
        final chainId = SessionID.create();
        final now = DateTime.now();
        final events = [
          SessionCreated(
            sessionId: chainId,
            title: 'Chain',
            agent: 'general',
            timestamp: now,
          ),
          MessageAdded(
            sessionId: chainId,
            messageId: 'user_msg',
            role: 'user',
            content: 'Hello, how are you?',
            timestamp: now,
          ),
          TextStarted(
            sessionId: chainId,
            messageId: 'asst_msg',
            timestamp: now,
          ),
          TextDelta(
            sessionId: chainId,
            messageId: 'asst_msg',
            delta: 'I am ',
            timestamp: now,
          ),
          TextDelta(
            sessionId: chainId,
            messageId: 'asst_msg',
            delta: 'doing well, ',
            timestamp: now,
          ),
          TextDelta(
            sessionId: chainId,
            messageId: 'asst_msg',
            delta: 'thank you!',
            timestamp: now,
          ),
          TextEnded(
            sessionId: chainId,
            messageId: 'asst_msg',
            fullText: 'I am doing well, thank you!',
            model: 'claude-4',
            timestamp: now,
          ),
        ];

        final state = replayEvents(events);

        expect(state.title, 'Chain');
        expect(state.messages.length, 2);
        expect(state.messages[0].content, 'Hello, how are you?');
        expect(state.messages[0].role, MessageRole.user);
        expect(state.messages[1].content, 'I am doing well, thank you!');
        expect(state.messages[1].role, MessageRole.assistant);
        expect(state.messages[1].model, 'claude-4');
      },
    );
  });

  group('replayEvents', () {
    test('full chain replay produces correct final state', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final events = [
        SessionCreated(
          sessionId: id,
          title: 'Test',
          agent: 'explore',
          timestamp: now,
        ),
        MessageAdded(
          sessionId: id,
          messageId: 'm1',
          role: 'user',
          content: 'Hi',
          timestamp: now,
        ),
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc1',
          toolName: 'bash',
          input: {'cmd': 'ls'},
          timestamp: now,
        ),
        ToolSuccess(
          sessionId: id,
          toolCallId: 'tc1',
          outputText: 'files',
          durationMs: 50,
          timestamp: now,
        ),
        StepEnded(
          sessionId: id,
          stepNumber: 1,
          tokensInput: 100,
          tokensOutput: 50,
          tokensReasoning: 10,
          timestamp: now,
        ),
      ];

      final state = replayEvents(events);

      expect(state.title, 'Test');
      expect(state.agent, 'explore');
      expect(state.messages.length, 2);
      expect(state.toolResults.length, 1);
      expect(state.tokensInput, 100);
      expect(state.tokensOutput, 50);
    });

    test('replay is idempotent', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final events = [
        SessionCreated(sessionId: id, timestamp: now),
        MessageAdded(
          sessionId: id,
          messageId: 'm1',
          role: 'user',
          content: 'Hello',
          timestamp: now,
        ),
      ];

      final state1 = replayEvents(events);
      final state2 = replayEvents(events);

      expect(state1.messages.length, state2.messages.length);
      expect(state1.messages.first.content, state2.messages.first.content);
    });
  });
}
