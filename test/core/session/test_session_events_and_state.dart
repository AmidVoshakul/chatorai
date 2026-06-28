import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  // ── SessionEvent hierarchy ─────────────────────────────────────────────

  group('SessionEvent hierarchy', () {
    final testSid = SessionID.create();
    final ts = DateTime.now();

    test('SessionCreated has all fields', () {
      final ts0 = DateTime(2024);
      final event = SessionCreated(
        sessionId: SessionID.fromString('ses_test'),
        parentId: SessionID.fromString('ses_parent'),
        title: 'Test Session',
        agent: 'build',
        modelRef: 'gpt-4o',
        timestamp: ts0,
      );
      expect(event.sessionId.value, equals('ses_test'));
      expect(event.parentId?.value, equals('ses_parent'));
      expect(event.title, equals('Test Session'));
      expect(event.agent, equals('build'));
      expect(event.modelRef, equals('gpt-4o'));
    });

    test('SessionArchived carries sessionId and timestamp', () {
      final event = SessionArchived(sessionId: testSid, timestamp: ts);
      expect(event.sessionId, equals(testSid));
    });

    test('SessionAgentSwitched carries agent name', () {
      final event = SessionAgentSwitched(
        sessionId: testSid,
        agent: 'explore',
        timestamp: ts,
      );
      expect(event.agent, equals('explore'));
    });

    test('SessionModelSwitched carries modelRef', () {
      final event = SessionModelSwitched(
        sessionId: testSid,
        modelRef: 'claude-3',
        timestamp: ts,
      );
      expect(event.modelRef, equals('claude-3'));
    });

    test('MessageAdded carries role and content', () {
      final event = MessageAdded(
        sessionId: testSid,
        messageId: 'msg-1',
        role: 'user',
        content: 'Hello',
        timestamp: ts,
      );
      expect(event.messageId, equals('msg-1'));
      expect(event.role, equals('user'));
      expect(event.content, equals('Hello'));
    });

    test('TextStarted/TextDelta/TextEnded carry messageId', () {
      final started = TextStarted(
        sessionId: testSid,
        messageId: 'msg-2',
        timestamp: ts,
      );
      final delta = TextDelta(
        sessionId: testSid,
        messageId: 'msg-2',
        delta: 'Hi',
        timestamp: ts,
      );
      final ended = TextEnded(
        sessionId: testSid,
        messageId: 'msg-2',
        fullText: 'Hi there',
        model: 'gpt-4o',
        timestamp: ts,
      );

      expect(started.messageId, equals('msg-2'));
      expect(delta.delta, equals('Hi'));
      expect(ended.fullText, equals('Hi there'));
      expect(ended.model, equals('gpt-4o'));
    });

    test('ReasoningStarted/ReasoningDelta/ReasoningEnded', () {
      final started = ReasoningStarted(
        sessionId: testSid,
        messageId: 'msg-3',
        timestamp: ts,
      );
      final delta = ReasoningDelta(
        sessionId: testSid,
        messageId: 'msg-3',
        delta: 'thinking...',
        timestamp: ts,
      );
      final ended = ReasoningEnded(
        sessionId: testSid,
        messageId: 'msg-3',
        fullReasoning: 'I need to...',
        timestamp: ts,
      );

      expect(started.messageId, equals('msg-3'));
      expect(delta.delta, equals('thinking...'));
      expect(ended.fullReasoning, equals('I need to...'));
    });

    test('ToolInputStarted/ToolInputDelta/ToolInputEnded', () {
      final started = ToolInputStarted(
        sessionId: testSid,
        toolCallId: 'tc-1',
        timestamp: ts,
      );
      final delta = ToolInputDelta(
        sessionId: testSid,
        toolCallId: 'tc-1',
        delta: '{"fi',
        timestamp: ts,
      );
      final ended = ToolInputEnded(
        sessionId: testSid,
        toolCallId: 'tc-1',
        fullInput: '{"file": "test.dart"}',
        timestamp: ts,
      );

      expect(started.toolCallId, equals('tc-1'));
      expect(delta.delta, equals('{"fi'));
      expect(ended.fullInput, equals('{"file": "test.dart"}'));
    });

    test('ToolCalled/ToolSuccess/ToolFailed', () {
      final called = ToolCalled(
        sessionId: testSid,
        toolCallId: 'tc-2',
        toolName: 'bash',
        input: {'command': 'ls'},
        timestamp: ts,
      );
      final success = ToolSuccess(
        sessionId: testSid,
        toolCallId: 'tc-2',
        outputText: 'file1.txt',
        durationMs: 150,
        timestamp: ts,
      );
      final failed = ToolFailed(
        sessionId: testSid,
        toolCallId: 'tc-3',
        error: 'Command not found',
        timestamp: ts,
      );

      expect(called.toolName, equals('bash'));
      expect(called.input, equals({'command': 'ls'}));
      expect(success.outputText, equals('file1.txt'));
      expect(success.durationMs, equals(150));
      expect(failed.error, equals('Command not found'));
    });

    test('StepStarted/StepEnded/StepFailed', () {
      final started = StepStarted(
        sessionId: testSid,
        stepNumber: 1,
        timestamp: ts,
      );
      final ended = StepEnded(
        sessionId: testSid,
        stepNumber: 1,
        tokensInput: 100,
        tokensOutput: 50,
        tokensReasoning: 10,
        timestamp: ts,
      );
      final failed = StepFailed(
        sessionId: testSid,
        stepNumber: 2,
        error: 'Timeout',
        timestamp: ts,
      );

      expect(started.stepNumber, equals(1));
      expect(ended.tokensInput, equals(100));
      expect(ended.tokensOutput, equals(50));
      expect(failed.error, equals('Timeout'));
    });

    test('CompactionStarted/CompactionEnded', () {
      final started = CompactionStarted(sessionId: testSid, timestamp: ts);
      final ended = CompactionEnded(
        sessionId: testSid,
        summary: 'Conversation about X',
        timestamp: ts,
      );
      expect(ended.summary, equals('Conversation about X'));
    });

    test('ChildSessionCreated', () {
      final event = ChildSessionCreated(
        sessionId: testSid,
        parentSessionId: testSid,
        childSessionId: SessionID.create(),
        title: 'Sub-task',
        agent: 'general',
        modelRef: 'gpt-4o',
        timestamp: ts,
      );
      expect(event.title, equals('Sub-task'));
      expect(event.agent, equals('general'));
    });

    test('TaskStarted/TaskCompleted', () {
      final started = TaskStarted(
        sessionId: testSid,
        taskId: 'task-1',
        description: 'Review code',
        timestamp: ts,
      );
      final completed = TaskCompleted(
        sessionId: testSid,
        taskId: 'task-1',
        output: 'Code looks good',
        timestamp: ts,
      );
      expect(started.description, equals('Review code'));
      expect(completed.output, equals('Code looks good'));
    });

    test('sequence field defaults to 0', () {
      final event = MessageAdded(
        sessionId: testSid,
        messageId: 'msg',
        role: 'user',
        content: 'hi',
        timestamp: ts,
      );
      expect(event.sequence, equals(0));
    });
  });

  // ── SessionState ───────────────────────────────────────────────────────

  group('SessionState', () {
    test('fromJson/toJson roundtrip', () {
      final now = DateTime.now();
      final state = SessionState(
        id: SessionID.create(),
        parentId: SessionID.create(),
        title: 'Test',
        agent: 'build',
        modelRef: 'gpt-4o',
        cost: 1.5,
        tokensInput: 100,
        tokensOutput: 50,
        tokensReasoning: 10,
        createdAt: now,
        updatedAt: now,
      );

      final json = state.toJson();
      final restored = SessionState.fromJson(json);

      expect(restored.id, equals(state.id));
      expect(restored.parentId, equals(state.parentId));
      expect(restored.title, equals('Test'));
      expect(restored.agent, equals('build'));
      expect(restored.modelRef, equals('gpt-4o'));
      expect(restored.cost, equals(1.5));
      expect(restored.tokensInput, equals(100));
      expect(restored.tokensOutput, equals(50));
    });

    test('copyWith preserves fields', () {
      final now = DateTime.now();
      final state = SessionState(
        id: SessionID.create(),
        title: 'Original',
        agent: 'build',
        createdAt: now,
        updatedAt: now,
      );

      final copy = state.copyWith(title: 'Updated', agent: 'explore');
      expect(copy.title, equals('Updated'));
      expect(copy.agent, equals('explore'));
      expect(copy.id, equals(state.id));
    });

    test('copyWith clearParentId', () {
      final now = DateTime.now();
      final parent = SessionID.create();
      final state = SessionState(
        id: SessionID.create(),
        parentId: parent,
        createdAt: now,
        updatedAt: now,
      );

      final copy = state.copyWith(clearParentId: true);
      expect(copy.parentId, isNull);
    });

    test('copyWith clearModelRef', () {
      final now = DateTime.now();
      final state = SessionState(
        id: SessionID.create(),
        modelRef: 'gpt-4o',
        createdAt: now,
        updatedAt: now,
      );

      final copy = state.copyWith(clearModelRef: true);
      expect(copy.modelRef, isNull);
    });

    test('copyWith clearArchivedAt', () {
      final now = DateTime.now();
      final state = SessionState(
        id: SessionID.create(),
        archivedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final copy = state.copyWith(clearArchivedAt: true);
      expect(copy.archivedAt, isNull);
    });

    test('sessionIdRaw returns raw string', () {
      final state = SessionState(
        id: SessionID.fromString('ses_abc123'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(state.sessionIdRaw, equals('ses_abc123'));
    });

    test('parentIdRaw returns raw string or null', () {
      final now = DateTime.now();
      final state1 = SessionState(
        id: SessionID.create(),
        parentId: SessionID.fromString('ses_parent'),
        createdAt: now,
        updatedAt: now,
      );
      expect(state1.parentIdRaw, equals('ses_parent'));

      final state2 = SessionState(
        id: SessionID.create(),
        createdAt: now,
        updatedAt: now,
      );
      expect(state2.parentIdRaw, isNull);
    });

    test('Equatable props include all fields', () {
      final now = DateTime.now();
      final id = SessionID.create();
      final state1 = SessionState(
        id: id,
        title: 'A',
        createdAt: now,
        updatedAt: now,
      );
      final state2 = SessionState(
        id: id,
        title: 'A',
        createdAt: now,
        updatedAt: now,
      );
      expect(state1, equals(state2));
    });
  });

  // ── SessionMessage ─────────────────────────────────────────────────────

  group('SessionMessage', () {
    test('fromJson/toJson roundtrip', () {
      final now = DateTime.now();
      final msg = SessionMessage(
        id: 'msg-1',
        role: MessageRole.user,
        content: 'Hello',
        seq: 0,
        model: 'gpt-4o',
        reasoning: 'thinking',
        error: null,
        createdAt: now,
      );

      final json = msg.toJson();
      final restored = SessionMessage.fromJson(json);

      expect(restored.id, equals('msg-1'));
      expect(restored.role, equals(MessageRole.user));
      expect(restored.content, equals('Hello'));
      expect(restored.model, equals('gpt-4o'));
      expect(restored.reasoning, equals('thinking'));
    });

    test('copyWith preserves fields', () {
      final now = DateTime.now();
      final now2 = DateTime(2024);
      final msg = SessionMessage(
        id: 'msg-2',
        role: MessageRole.assistant,
        content: 'Hi',
        seq: 1,
        createdAt: now2,
      );

      final copy = msg.copyWith(content: 'Updated');
      expect(copy.content, equals('Updated'));
      expect(copy.id, equals('msg-2'));
    });
  });

  // ── ToolResult ─────────────────────────────────────────────────────────

  group('ToolResult', () {
    test('fromJson/toJson roundtrip', () {
      final now = DateTime.now();
      final result = ToolResult(
        id: 'tr-1',
        toolName: 'bash',
        input: {'command': 'ls'},
        outputText: 'file.txt',
        durationMs: 100,
        status: 'success',
        createdAt: now,
      );

      final json = result.toJson();
      final restored = ToolResult.fromJson(json);

      expect(restored.id, equals('tr-1'));
      expect(restored.toolName, equals('bash'));
      expect(restored.outputText, equals('file.txt'));
      expect(restored.durationMs, equals(100));
    });

    test('copyWith preserves fields', () {
      final now = DateTime.now();
      final result = ToolResult(
        id: 'tr-2',
        toolName: 'read',
        input: {},
        outputText: 'content',
        durationMs: 50,
        status: 'success',
        createdAt: now,
      );

      final copy = result.copyWith(outputText: 'new content');
      expect(copy.outputText, equals('new content'));
      expect(copy.toolName, equals('read'));
    });
  });

  // ── SessionID converters ───────────────────────────────────────────────

  group('SessionIDConverter', () {
    const converter = SessionIDConverter();

    test('fromJson creates SessionID from string', () {
      final id = converter.fromJson('ses_test123');
      expect(id.value, equals('ses_test123'));
    });

    test('toJson converts SessionID to string', () {
      final id = SessionID.fromString('ses_abc');
      expect(converter.toJson(id), equals('ses_abc'));
    });
  });

  group('SessionIDNullableConverter', () {
    const converter = SessionIDNullableConverter();

    test('fromJson creates SessionID from non-null string', () {
      final id = converter.fromJson('ses_test');
      expect(id?.value, equals('ses_test'));
    });

    test('fromJson returns null from null', () {
      final id = converter.fromJson(null);
      expect(id, isNull);
    });

    test('toJson converts SessionID to string', () {
      final id = SessionID.fromString('ses_xyz');
      expect(converter.toJson(id), equals('ses_xyz'));
    });

    test('toJson converts null to null', () {
      expect(converter.toJson(null), isNull);
    });
  });
}
