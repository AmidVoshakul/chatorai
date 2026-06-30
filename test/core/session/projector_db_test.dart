import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  group('projectToDb', () {
    late AppDatabase db;
    late SessionID sessionId;
    late DateTime timestamp;

    setUp(() {
      db = AppDatabase.inMemory();
      sessionId = SessionID.create();
      timestamp = DateTime.now();
    });

    tearDown(() async {
      await db.close();
    });

    test('SessionArchived updates session row', () async {
      // First create a session
      await projectToDb(
        db,
        SessionCreated(
          sessionId: sessionId,
          title: 'To Archive',
          agent: 'general',
          timestamp: timestamp,
        ),
      );

      // Then archive it
      await projectToDb(
        db,
        SessionArchived(sessionId: sessionId, timestamp: timestamp),
      );

      final sessions = await db.select(db.sessions).get();
      expect(sessions.length, 1);
      expect(sessions.first.archivedAt, isA<DateTime>());
      // SQLite stores timestamps with second precision
      expect(
        sessions.first.updatedAt.difference(timestamp).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('SessionAgentSwitched updates agent', () async {
      await projectToDb(
        db,
        SessionCreated(
          sessionId: sessionId,
          agent: 'general',
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        SessionAgentSwitched(
          sessionId: sessionId,
          agent: 'code-reviewer',
          timestamp: timestamp,
        ),
      );

      final sessions = await db.select(db.sessions).get();
      expect(sessions.first.agent, 'code-reviewer');
    });

    test('SessionModelSwitched updates modelRef', () async {
      await projectToDb(
        db,
        SessionCreated(
          sessionId: sessionId,
          modelRef: 'gpt-4',
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        SessionModelSwitched(
          sessionId: sessionId,
          modelRef: 'claude-4',
          timestamp: timestamp,
        ),
      );

      final sessions = await db.select(db.sessions).get();
      expect(sessions.first.modelRef, 'claude-4');
    });

    test('TextEnded updates message content and model', () async {
      await projectToDb(
        db,
        MessageAdded(
          sessionId: sessionId,
          messageId: 'msg_1',
          role: 'assistant',
          content: '',
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        TextEnded(
          sessionId: sessionId,
          messageId: 'msg_1',
          fullText: 'Final response',
          model: 'gpt-4',
          timestamp: timestamp,
        ),
      );

      final messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.content, 'Final response');
      expect(messages.first.model, 'gpt-4');
    });

    test('ReasoningEnded updates message reasoning', () async {
      await projectToDb(
        db,
        MessageAdded(
          sessionId: sessionId,
          messageId: 'msg_1',
          role: 'assistant',
          content: 'Answer',
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        ReasoningEnded(
          sessionId: sessionId,
          messageId: 'msg_1',
          fullReasoning: 'I think...',
          timestamp: timestamp,
        ),
      );

      final messages = await db.select(db.messages).get();
      expect(messages.first.reasoning, 'I think...');
    });

    test('ToolCalled inserts tool message', () async {
      await projectToDb(
        db,
        ToolCalled(
          sessionId: sessionId,
          toolCallId: 'tc_1',
          toolName: 'bash',
          input: {'cmd': 'ls'},
          timestamp: timestamp,
        ),
      );

      final messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.id, 'tc_1');
      expect(messages.first.role, 'tool');
      expect(messages.first.content, '{"cmd":"ls"}');
    });

    test('ToolSuccess updates message and inserts tool_result', () async {
      await projectToDb(
        db,
        ToolCalled(
          sessionId: sessionId,
          toolCallId: 'tc_1',
          toolName: 'bash',
          input: {'cmd': 'ls'},
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        ToolSuccess(
          sessionId: sessionId,
          toolCallId: 'tc_1',
          outputText: 'file1.txt',
          durationMs: 100,
          timestamp: timestamp,
        ),
      );

      final messages = await db.select(db.messages).get();
      expect(messages.first.content, 'file1.txt');

      final toolResults = await db.select(db.toolResults).get();
      expect(toolResults.length, 1);
      expect(toolResults.first.id, 'tc_1');
      expect(toolResults.first.toolName, 'bash');
      expect(toolResults.first.outputText, 'file1.txt');
      expect(toolResults.first.durationMs, 100);
      expect(toolResults.first.status, 'success');
    });

    test('ToolFailed updates message error and inserts tool_result', () async {
      await projectToDb(
        db,
        ToolCalled(
          sessionId: sessionId,
          toolCallId: 'tc_1',
          toolName: 'bash',
          input: {'cmd': 'ls'},
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        ToolFailed(
          sessionId: sessionId,
          toolCallId: 'tc_1',
          error: 'Command not found',
          timestamp: timestamp,
        ),
      );

      final messages = await db.select(db.messages).get();
      expect(messages.first.error, 'Command not found');

      final toolResults = await db.select(db.toolResults).get();
      expect(toolResults.first.status, 'error');
      expect(toolResults.first.outputText, 'Command not found');
    });

    test('StepEnded accumulates tokens on session row', () async {
      await projectToDb(
        db,
        SessionCreated(sessionId: sessionId, timestamp: timestamp),
      );

      await projectToDb(
        db,
        StepEnded(
          sessionId: sessionId,
          stepNumber: 1,
          tokensInput: 100,
          tokensOutput: 50,
          tokensReasoning: 10,
          timestamp: timestamp,
        ),
      );

      await projectToDb(
        db,
        StepEnded(
          sessionId: sessionId,
          stepNumber: 2,
          tokensInput: 200,
          tokensOutput: 100,
          tokensReasoning: 20,
          timestamp: timestamp,
        ),
      );

      final sessions = await db.select(db.sessions).get();
      expect(sessions.first.tokensInput, 300);
      expect(sessions.first.tokensOutput, 150);
      expect(sessions.first.tokensReasoning, 30);
    });

    test('ChildSessionCreated updates parent session updatedAt', () async {
      await projectToDb(
        db,
        SessionCreated(
          sessionId: sessionId,
          title: 'Parent',
          timestamp: timestamp,
        ),
      );

      final childId = SessionID.create();
      final later = timestamp.add(const Duration(seconds: 2));

      await projectToDb(
        db,
        ChildSessionCreated(
          sessionId: sessionId,
          parentSessionId: sessionId,
          childSessionId: childId,
          title: 'Child',
          timestamp: later,
        ),
      );

      final sessions = await db.select(db.sessions).get();
      // SQLite stores timestamps with second precision
      expect(
        sessions.first.updatedAt.difference(later).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('ToolSuccess without prior ToolCalled uses empty toolName', () async {
      // Simulate a ToolSuccess without a preceding ToolCalled
      await projectToDb(
        db,
        ToolSuccess(
          sessionId: sessionId,
          toolCallId: 'orphan_tc',
          outputText: 'some result',
          durationMs: 50,
          timestamp: timestamp,
        ),
      );

      final toolResults = await db.select(db.toolResults).get();
      expect(toolResults.length, 1);
      // _lookupToolName returns empty string when no message row exists
      expect(toolResults.first.toolName, '');
    });

    test('ToolFailed without prior ToolCalled uses empty toolName', () async {
      await projectToDb(
        db,
        ToolFailed(
          sessionId: sessionId,
          toolCallId: 'orphan_tc',
          error: 'Failed',
          timestamp: timestamp,
        ),
      );

      final toolResults = await db.select(db.toolResults).get();
      expect(toolResults.first.toolName, '');
    });
  });

  group('projectEvent uncovered branches', () {
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

    test('CompactionStarted is a no-op on state', () {
      final state = projectEvent(
        empty,
        CompactionStarted(sessionId: id, timestamp: DateTime.now()),
      );
      // Should be unchanged (same as empty)
      expect(state.updatedAt, empty.updatedAt);
    });

    test('TaskStarted is a no-op on state', () {
      final state = projectEvent(
        empty,
        TaskStarted(
          sessionId: id,
          taskId: 'task-1',
          description: 'Do something',
          timestamp: DateTime.now(),
        ),
      );
      expect(state.messages, isEmpty);
      expect(state.updatedAt, empty.updatedAt);
    });

    test('TaskCompleted appends assistant message', () {
      final state = projectEvent(
        empty,
        TaskCompleted(
          sessionId: id,
          taskId: 'task-1',
          output: 'Task result',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages.length, 1);
      expect(state.messages.first.role, MessageRole.assistant);
      expect(state.messages.first.content, 'Task result');
    });

    test('ChildSessionCreated updates updatedAt', () {
      final before = empty.updatedAt;
      final childId = SessionID.create();
      final state = projectEvent(
        empty,
        ChildSessionCreated(
          sessionId: id,
          parentSessionId: id,
          childSessionId: childId,
          title: 'Child',
          timestamp: DateTime.now(),
        ),
      );
      expect(state.updatedAt.isAfter(before), isTrue);
    });

    test('ToolSuccess for unknown toolCallId does not crash', () {
      // ToolSuccess references a toolCallId not in messages
      final state = projectEvent(
        empty,
        ToolSuccess(
          sessionId: id,
          toolCallId: 'unknown_tc',
          outputText: 'result',
          durationMs: 100,
          timestamp: DateTime.now(),
        ),
      );

      // No message to update, but ToolResult is still added
      expect(state.toolResults.length, 1);
      expect(state.toolResults.first.outputText, 'result');
      expect(state.toolResults.first.status, 'success');
    });

    test('ToolFailed for unknown toolCallId does not crash', () {
      final state = projectEvent(
        empty,
        ToolFailed(
          sessionId: id,
          toolCallId: 'unknown_tc',
          error: 'Failed',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.toolResults.length, 1);
      expect(state.toolResults.first.status, 'error');
      expect(state.toolResults.first.outputText, 'Failed');
    });

    test('TextEnded for unknown messageId leaves messages unchanged', () {
      final state = projectEvent(
        empty,
        TextEnded(
          sessionId: id,
          messageId: 'nonexistent',
          fullText: 'Should not apply',
          timestamp: DateTime.now(),
        ),
      );

      // No message with that ID — nothing updated
      expect(state.messages, isEmpty);
    });

    test('ReasoningEnded for unknown messageId leaves messages unchanged', () {
      final state = projectEvent(
        empty,
        ReasoningEnded(
          sessionId: id,
          messageId: 'nonexistent',
          fullReasoning: 'Should not apply',
          timestamp: DateTime.now(),
        ),
      );

      expect(state.messages, isEmpty);
    });
  });

  group('replayEvents edge cases', () {
    test('single event list works', () {
      final id = SessionID.create();
      final events = [SessionCreated(sessionId: id, timestamp: DateTime.now())];

      final state = replayEvents(events);
      expect(state.id, id);
    });

    test('handles different message roles correctly', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final events = [
        SessionCreated(sessionId: id, timestamp: now),
        MessageAdded(
          sessionId: id,
          messageId: 'user_msg',
          role: 'user',
          content: 'Hi',
          timestamp: now,
        ),
        MessageAdded(
          sessionId: id,
          messageId: 'assistant_msg',
          role: 'assistant',
          content: 'Hello',
          timestamp: now,
        ),
        MessageAdded(
          sessionId: id,
          messageId: 'tool_msg',
          role: 'tool',
          content: 'result',
          timestamp: now,
        ),
      ];

      final state = replayEvents(events);
      expect(state.messages.length, 3);
      expect(state.messages[0].role, MessageRole.user);
      expect(state.messages[1].role, MessageRole.assistant);
      expect(state.messages[2].role, MessageRole.tool);
    });
  });
}
