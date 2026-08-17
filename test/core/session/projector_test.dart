import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';

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
          toolName: 'shell',
          input: {'cmd': 'ls'},
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 2);
      expect(state.messages.first.role, MessageRole.assistant);
      expect(state.messages.last.role, MessageRole.tool);
      expect(state.messages.last.content, contains('ls'));
    });

    test('ToolSuccess updates message and adds ToolResult', () {
      var state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_1',
          toolName: 'shell',
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
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 2);
      expect(state.messages.last.content, 'result');
      expect(state.toolResults.length, 1);
      expect(state.toolResults.first.status, 'success');
    });

    test('ToolFailed adds error to message', () {
      var state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_1',
          toolName: 'shell',
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

      expect(state.messages.length, 2);
      expect(state.messages.last.error, 'Command failed');
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

    test(
      'TextStarted → ToolCalled → TextEnded keeps text before tool in parts',
      () {
        final now = DateTime.now();
        // Event order matches real streaming: text starts → text delta →
        // tool call → reasoning → TextEnded → tool result.
        // Parts are created in event order: Text, Tool, Reasoning.
        final events = [
          SessionCreated(sessionId: id, timestamp: now),
          MessageAdded(
            sessionId: id,
            messageId: 'u1',
            role: 'user',
            content: 'hi',
            timestamp: now,
          ),
          TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
          TextDelta(
            sessionId: id,
            messageId: 'a1',
            delta: 'initial ',
            timestamp: now,
          ),
          ToolCalled(
            sessionId: id,
            toolCallId: 'tc1',
            toolName: 'shell',
            input: {'cmd': 'ls'},
            timestamp: now,
          ),
          ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
          ReasoningDelta(
            sessionId: id,
            messageId: 'a1',
            delta: 'thinking',
            timestamp: now,
          ),
          ReasoningEnded(
            sessionId: id,
            messageId: 'a1',
            fullReasoning: 'thought',
            timestamp: now,
          ),
          TextEnded(
            sessionId: id,
            messageId: 'a1',
            fullText: 'initial ok',
            model: 'm1',
            timestamp: now,
          ),
          ToolSuccess(
            sessionId: id,
            toolCallId: 'tc1',
            outputText: 'files',
            timestamp: now,
          ),
        ];

        final state = replayEvents(events);

        expect(state.parts.length, 3);
        // Parts are in creation order: Text → Tool → Reasoning
        expect(state.parts[0], isA<AssistantText>());
        expect(state.parts[1], isA<AssistantTool>());
        expect(state.parts[2], isA<AssistantReasoning>());
        // TextEnded preserves per-part accumulated text (not fullText)
        if (state.parts[0] is AssistantText) {
          expect((state.parts[0] as AssistantText).text, 'initial ');
        }
        if (state.parts[1] is AssistantTool) {
          expect((state.parts[1] as AssistantTool).state, ToolState.completed);
        }
        // Message-level content is fullText
        expect(
          state.messages.firstWhere((m) => m.id == 'a1').content,
          'initial ok',
        );
      },
    );

    test(
      'TextEnded preserves per-part accumulated text across multiple parts',
      () {
        final now = DateTime.now();
        // Simulate multi-step: text → tool → more text → TextEnded
        // The SDK's fullText will contain ALL text concatenated;
        // each part should keep only its own accumulated text.
        final events = [
          SessionCreated(sessionId: id, timestamp: now),
          // Step 1: first text part
          TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
          TextDelta(
            sessionId: id,
            messageId: 'a1',
            delta: 'Hello ',
            timestamp: now,
          ),
          // Tool call closes first text part
          ToolCalled(
            sessionId: id,
            toolCallId: 'tc1',
            toolName: 'shell',
            input: {'cmd': 'ls'},
            timestamp: now,
          ),
          ToolSuccess(
            sessionId: id,
            toolCallId: 'tc1',
            outputText: 'files',
            timestamp: now,
          ),
          // Step 2: second text part (same messageId)
          TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
          TextDelta(
            sessionId: id,
            messageId: 'a1',
            delta: 'World',
            timestamp: now,
          ),
          // TextEnded with fullText = concatenation of all text from SDK
          TextEnded(
            sessionId: id,
            messageId: 'a1',
            fullText: 'Hello World',
            model: 'gpt-4',
            timestamp: now,
          ),
        ];

        final state = replayEvents(events);

        // Message-level content should be the fullText
        expect(state.messages.first.content, 'Hello World');

        // Parts: [AssistantText("Hello "), AssistantTool, AssistantText("World")]
        expect(state.parts.length, 3);
        expect(state.parts[0], isA<AssistantText>());
        expect(state.parts[1], isA<AssistantTool>());
        expect(state.parts[2], isA<AssistantText>());

        // Each text part must preserve its own accumulated text
        // (NOT replaced by fullText)
        expect((state.parts[0] as AssistantText).text, 'Hello ');
        expect((state.parts[2] as AssistantText).text, 'World');
      },
    );

    test('TextDelta updates existing text part in place', () {
      final now = DateTime.now();
      final events = [
        SessionCreated(sessionId: id, timestamp: now),
        TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
        TextDelta(sessionId: id, messageId: 'a1', delta: 'Hel', timestamp: now),
        TextDelta(sessionId: id, messageId: 'a1', delta: 'lo', timestamp: now),
        TextEnded(
          sessionId: id,
          messageId: 'a1',
          fullText: 'Hello',
          model: 'm1',
          timestamp: now,
        ),
      ];

      final state = replayEvents(events);

      expect(state.parts.length, 1);
      expect(state.parts.first, isA<AssistantText>());
      expect((state.parts.first as AssistantText).text, 'Hello');
    });

    test('ReasoningDelta/Ended updates existing reasoning part in place', () {
      final now = DateTime.now();
      // Event order: TextStarted creates AssistantText first,
      // then ReasoningStarted creates AssistantReasoning.
      final events = [
        SessionCreated(sessionId: id, timestamp: now),
        TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
        TextDelta(sessionId: id, messageId: 'a1', delta: 'He', timestamp: now),
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thi',
          timestamp: now,
        ),
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'nk',
          timestamp: now,
        ),
        ReasoningEnded(
          sessionId: id,
          messageId: 'a1',
          fullReasoning: 'think',
          timestamp: now,
        ),
        TextEnded(
          sessionId: id,
          messageId: 'a1',
          fullText: 'Hellothink',
          model: 'm1',
          timestamp: now,
        ),
      ];

      final state = replayEvents(events);

      expect(state.parts.length, 2);
      // Parts in creation order: Text, then Reasoning
      expect(state.parts[0], isA<AssistantText>());
      expect(state.parts[1], isA<AssistantReasoning>());
      // Each part preserves its own accumulated text
      expect((state.parts[0] as AssistantText).text, 'He');
      expect((state.parts[1] as AssistantReasoning).text, 'think');
    });

    test('ReasoningEnded on already closed part replaces text and preserves ended', () {
      final now = DateTime.now();
      final partId = 'part_reasoning_1';
      final events = [
        SessionCreated(sessionId: id, timestamp: now),
        ReasoningStarted(
          sessionId: id,
          messageId: 'a1',
          partId: partId,
          timestamp: now,
        ),
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          partId: partId,
          delta: 'partial',
          timestamp: now,
        ),
        ReasoningEnded(
          sessionId: id,
          messageId: 'a1',
          partId: partId,
          fullReasoning: 'partial',
          timestamp: now,
        ),
        // Second ReasoningEnded for the same part (merge case).
        ReasoningEnded(
          sessionId: id,
          messageId: 'a1',
          partId: partId,
          fullReasoning: 'partial merged',
          timestamp: now,
        ),
      ];

      final state = replayEvents(events);

      expect(state.parts.length, 1);
      expect(state.parts.first, isA<AssistantReasoning>());
      expect((state.parts.first as AssistantReasoning).text, 'partial merged');
      expect((state.parts.first as AssistantReasoning).ended, isNotNull);
    });

    test('TaskPartStarted with same partId updates instead of duplicating', () {
      var state = empty;
      final first = TaskPartStarted(
        sessionId: id,
        partId: 'part_1',
        description: '',
        agent: '',
        taskSessionId: 'ses_child',
        timestamp: DateTime.now(),
      );
      state = projectEvent(state, first);
      expect(state.parts.whereType<AssistantTask>().length, 1);

      final second = TaskPartStarted(
        sessionId: id,
        partId: 'part_1',
        description: 'AI market revenue',
        agent: 'deepresearch',
        taskSessionId: 'ses_child',
        timestamp: DateTime.now(),
      );
      state = projectEvent(state, second);

      final tasks = state.parts.whereType<AssistantTask>().toList();
      expect(tasks.length, 1);
      expect(tasks.single.description, 'AI market revenue');
      expect(tasks.single.agent, 'deepresearch');
      expect(tasks.single.state, ToolState.running);
    });
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
          toolName: 'shell',
          input: {'cmd': 'ls'},
          timestamp: now,
        ),
        ToolSuccess(
          sessionId: id,
          toolCallId: 'tc1',
          outputText: 'files',
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
      expect(state.messages.length, 3);
      expect(state.messages[0].role, MessageRole.user);
      expect(state.messages[1].role, MessageRole.assistant);
      expect(state.messages[2].role, MessageRole.tool);
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

    test('TextEnded marks the text part finalized (synthetic=false)', () {
      final sid = SessionID.fromString('ses_synth');
      final state = replayEvents([
        TextStarted(sessionId: sid, messageId: 'm1', timestamp: DateTime.now()),
        TextDelta(
          sessionId: sid,
          messageId: 'm1',
          delta: 'hi',
          timestamp: DateTime.now(),
        ),
        TextEnded(
          sessionId: sid,
          messageId: 'm1',
          fullText: 'hi',
          timestamp: DateTime.now(),
        ),
      ]);
      final part = state.parts.whereType<AssistantText>().single;
      expect(part.synthetic, isFalse);
      expect(part.text, 'hi');
    });

    test(
      'TextStarted after unclosed synthetic text closes previous synthetic text',
      () {
        final sid = SessionID.fromString('ses_synth');
        final state = replayEvents([
          TextStarted(
            sessionId: sid,
            messageId: 'm1',
            timestamp: DateTime.now(),
          ),
          TextDelta(
            sessionId: sid,
            messageId: 'm1',
            delta: 'first',
            timestamp: DateTime.now(),
          ),
          // Simulate a new TextStarted without an explicit TextEnded for the first.
          TextStarted(
            sessionId: sid,
            messageId: 'm1',
            timestamp: DateTime.now(),
          ),
        ]);
        final texts = state.parts.whereType<AssistantText>().toList();
        expect(texts.length, 2);
        // The first text part must no longer be synthetic (closed by the second start).
        expect(texts[0].synthetic, isFalse);
        expect(texts[0].text, 'first');
        // The second text part is the new open one.
        expect(texts[1].synthetic, isTrue);
        expect(texts[1].text, '');
      },
    );

    test('ToolCalled without prior assistant message creates one', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final empty = SessionState(id: id, createdAt: now, updatedAt: now);
      final state = projectEvent(
        empty,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc_1',
          toolName: 'shell',
          input: {'cmd': 'ls'},
          timestamp: now,
        ),
      );

      expect(state.messages.length, 2);
      expect(state.messages.first.role, MessageRole.assistant);
      expect(state.messages.first.content, '');
      expect(state.messages.last.role, MessageRole.tool);
      final toolParts = state.parts.whereType<AssistantTool>().toList();
      expect(toolParts.length, 1);
      expect(toolParts.single.messageId, state.messages.first.id);
      expect(toolParts.single.messageId, isNot(''));
    });

    test('TaskPartStarted without prior assistant message creates one', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final empty = SessionState(id: id, createdAt: now, updatedAt: now);
      final state = projectEvent(
        empty,
        TaskPartStarted(
          sessionId: id,
          partId: 'part_1',
          description: 'Test task',
          agent: 'general',
          taskSessionId: 'ses_child',
          timestamp: now,
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.role, MessageRole.assistant);
      expect(state.messages.first.content, '');
      final taskParts = state.parts.whereType<AssistantTask>().toList();
      expect(taskParts.length, 1);
      expect(taskParts.single.messageId, state.messages.first.id);
      expect(taskParts.single.messageId, isNot(''));
    });
  });

  group('reasoning stays open across non-reasoning events', () {
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

    test('ToolCalled does not close open reasoning', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        ToolCalled(
          sessionId: id,
          toolCallId: 'tc1',
          toolName: 'shell',
          input: {'cmd': 'ls'},
          timestamp: now,
        ),
      );

      final openReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended == null)
          .toList();
      expect(openReasoning, hasLength(1));
      expect(openReasoning.single.text, 'thinking');
    });

    test('ToolInputStarted does not close open reasoning', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        ToolInputStarted(sessionId: id, toolCallId: 'tc1', timestamp: now),
      );

      final openReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended == null)
          .toList();
      expect(openReasoning, hasLength(1));
    });

    test('TodoPartStarted does not close open reasoning', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        TodoPartStarted(
          sessionId: id,
          partId: 'todo1',
          todos: const [],
          timestamp: now,
        ),
      );

      final openReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended == null)
          .toList();
      expect(openReasoning, hasLength(1));
    });

    test('TaskPartStarted does not close open reasoning', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        TaskPartStarted(
          sessionId: id,
          partId: 'task1',
          description: 'task',
          agent: 'general',
          taskSessionId: 'ses_child',
          timestamp: now,
        ),
      );

      final openReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended == null)
          .toList();
      expect(openReasoning, hasLength(1));
    });

    test('QuestionPartStarted does not close open reasoning', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        QuestionPartStarted(
          sessionId: id,
          partId: 'q1',
          questionText: 'Proceed?',
          options: const [],
          timestamp: now,
        ),
      );

      final openReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended == null)
          .toList();
      expect(openReasoning, hasLength(1));
    });

    test('ReasoningEnded closes the open reasoning part', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        ReasoningEnded(
          sessionId: id,
          messageId: 'a1',
          fullReasoning: 'thinking',
          timestamp: now,
        ),
      );

      final closedReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended != null)
          .toList();
      expect(closedReasoning, hasLength(1));
      expect(closedReasoning.single.text, 'thinking');
    });

    test('TextStarted closes open reasoning before starting text', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );

      final closedReasoning = state.parts
          .whereType<AssistantReasoning>()
          .where((r) => r.ended != null)
          .toList();
      expect(closedReasoning, hasLength(1));
      final openText = state.parts.whereType<AssistantText>().toList();
      expect(openText, hasLength(1));
    });

    test(
      'ReasoningDelta after ToolCalled continues the same reasoning part',
      () {
        final now = DateTime.now();
        var state = projectEvent(
          empty,
          ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
        );
        state = projectEvent(
          state,
          ReasoningDelta(
            sessionId: id,
            messageId: 'a1',
            delta: 'before tool',
            timestamp: now,
          ),
        );
        state = projectEvent(
          state,
          ToolCalled(
            sessionId: id,
            toolCallId: 'tc1',
            toolName: 'shell',
            input: {'cmd': 'ls'},
            timestamp: now,
          ),
        );
        state = projectEvent(
          state,
          ReasoningDelta(
            sessionId: id,
            messageId: 'a1',
            delta: ' after tool',
            timestamp: now,
          ),
        );

        final reasoningParts = state.parts
            .whereType<AssistantReasoning>()
            .toList();
        expect(reasoningParts, hasLength(1));
        expect(reasoningParts.single.text, 'before tool after tool');
        expect(reasoningParts.single.ended, isNull);
      },
    );

    test('ReasoningDelta after ReasoningEnded with same partId is ignored', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thought',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        ReasoningEnded(
          sessionId: id,
          messageId: 'a1',
          fullReasoning: 'thought',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          partId: state.parts.whereType<AssistantReasoning>().last.id,
          delta: ' late delta',
          timestamp: now,
        ),
      );

      final reasoningParts = state.parts
          .whereType<AssistantReasoning>()
          .toList();
      expect(reasoningParts, hasLength(1));
      expect(reasoningParts.single.text, 'thought');
      expect(reasoningParts.single.ended, isNotNull);
    });
  });

  group('MessageDeleted', () {
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

    test('removes the deleted message from state.messages', () {
      var state = empty;
      state = projectEvent(
        state,
        MessageAdded(
          sessionId: id,
          messageId: 'm1',
          role: 'user',
          content: 'Hello',
          timestamp: DateTime.now(),
        ),
      );
      state = projectEvent(
        state,
        MessageAdded(
          sessionId: id,
          messageId: 'm2',
          role: 'assistant',
          content: 'Hi',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages, hasLength(2));

      state = projectEvent(
        state,
        MessageDeleted(
          sessionId: id,
          messageId: 'm1',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages, hasLength(1));
      expect(state.messages.first.id, 'm2');
    });

    test('removes parts belonging to the deleted message from state.parts', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        MessageAdded(
          sessionId: id,
          messageId: 'm1',
          role: 'user',
          content: 'Hello',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        TextDelta(sessionId: id, messageId: 'a1', delta: 'Hi', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        ReasoningDelta(
          sessionId: id,
          messageId: 'a1',
          delta: 'thinking',
          timestamp: now,
        ),
      );

      // Parts for a1 exist
      expect(state.parts.where((p) => p.messageId == 'a1'), isNotEmpty);

      state = projectEvent(
        state,
        MessageDeleted(
          sessionId: id,
          messageId: 'a1',
          timestamp: now,
        ),
      );

      // Parts for a1 are removed
      expect(state.parts.where((p) => p.messageId == 'a1'), isEmpty);
      // Parts for other messages (if any) remain
    });

    test('leaves parts of other messages intact after deleting one message', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        MessageAdded(
          sessionId: id,
          messageId: 'm1',
          role: 'user',
          content: 'Hello',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        TextStarted(sessionId: id, messageId: 'a1', timestamp: now),
      );
      state = projectEvent(
        state,
        TextDelta(sessionId: id, messageId: 'a1', delta: 'Hi', timestamp: now),
      );
      state = projectEvent(
        state,
        MessageAdded(
          sessionId: id,
          messageId: 'a2',
          role: 'assistant',
          content: 'Bye',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        TextStarted(sessionId: id, messageId: 'a2', timestamp: now),
      );
      state = projectEvent(
        state,
        TextDelta(sessionId: id, messageId: 'a2', delta: 'Bye', timestamp: now),
      );

      expect(state.parts.where((p) => p.messageId == 'a1'), hasLength(1));
      expect(state.parts.where((p) => p.messageId == 'a2'), hasLength(1));

      state = projectEvent(
        state,
        MessageDeleted(
          sessionId: id,
          messageId: 'a1',
          timestamp: now,
        ),
      );

      expect(state.parts.where((p) => p.messageId == 'a1'), isEmpty);
      expect(state.parts.where((p) => p.messageId == 'a2'), hasLength(1));
    });

    test('MessageDeleted is idempotent when parts are already absent', () {
      final now = DateTime.now();
      var state = projectEvent(
        empty,
        MessageAdded(
          sessionId: id,
          messageId: 'm1',
          role: 'user',
          content: 'Hello',
          timestamp: now,
        ),
      );

      state = projectEvent(
        state,
        MessageDeleted(
          sessionId: id,
          messageId: 'm1',
          timestamp: now,
        ),
      );
      state = projectEvent(
        state,
        MessageDeleted(
          sessionId: id,
          messageId: 'm1',
          timestamp: now,
        ),
      );

      expect(state.messages, isEmpty);
      expect(state.parts, isEmpty);
    });
  });
}
