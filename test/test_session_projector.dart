import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/database.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/projector.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';

/// Creates an initial [SessionState] for testing.
SessionState _createInitialState() {
  final now = DateTime.now();
  return SessionState(
    id: SessionID.fromString('ses_initial'),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('projectToDb', () {
    late AppDatabase db;
    late SessionID sessionId;
    late DateTime timestamp;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sessionId = SessionID.create();
      timestamp = DateTime.now();
    });

    tearDown(() async {
      await db.close();
    });

    test('SessionCreated inserts a session row', () async {
      final event = SessionCreated(
        sessionId: sessionId,
        title: 'Test Session',
        agent: 'general',
        modelRef: 'claude-3-5-sonnet',
        timestamp: timestamp,
      );

      await projectToDb(db, event);

      final sessions = await db.select(db.sessions).get();
      expect(sessions.length, 1);
      expect(sessions.first.id, sessionId.value);
      expect(sessions.first.title, 'Test Session');
      expect(sessions.first.agent, 'general');
      expect(sessions.first.modelRef, 'claude-3-5-sonnet');
    });

    test('MessageAdded inserts a message row', () async {
      final event = MessageAdded(
        sessionId: sessionId,
        messageId: 'msg_1',
        role: 'user',
        content: 'Hello world',
        timestamp: timestamp,
      );

      await projectToDb(db, event);

      final messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.id, 'msg_1');
      expect(messages.first.role, 'user');
      expect(messages.first.content, 'Hello world');
      expect(messages.first.sessionId, sessionId.value);
    });

    test('TextEnded updates existing message content and model', () async {
      // First create a message via MessageAdded (TextStarted doesn't persist to DB)
      final messageAdded = MessageAdded(
        sessionId: sessionId,
        messageId: 'msg_assistant_1',
        role: 'assistant',
        content: '',
        timestamp: timestamp,
      );
      await projectToDb(db, messageAdded);

      // Then update it via TextEnded
      final textEnded = TextEnded(
        sessionId: sessionId,
        messageId: 'msg_assistant_1',
        fullText: 'This is the complete response',
        model: 'claude-3-5-sonnet',
        timestamp: timestamp,
      );
      await projectToDb(db, textEnded);

      final messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.content, 'This is the complete response');
      expect(messages.first.model, 'claude-3-5-sonnet');
    });

    test('ToolCalled inserts a tool message row', () async {
      final event = ToolCalled(
        sessionId: sessionId,
        toolCallId: 'tool_call_1',
        toolName: 'bash',
        input: {'command': 'ls -la'},
        timestamp: timestamp,
      );

      await projectToDb(db, event);

      final messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.id, 'tool_call_1');
      expect(messages.first.role, 'tool');
      expect(messages.first.sessionId, sessionId.value);
    });

    test('ToolSuccess updates tool message and inserts tool_result', () async {
      // First create a tool call
      final toolCalled = ToolCalled(
        sessionId: sessionId,
        toolCallId: 'tool_call_1',
        toolName: 'bash',
        input: {'command': 'ls -la'},
        timestamp: timestamp,
      );
      await projectToDb(db, toolCalled);

      // Then record success
      final toolSuccess = ToolSuccess(
        sessionId: sessionId,
        toolCallId: 'tool_call_1',
        outputText: 'total 0\ndrwxr-xr-x 2 user user 4096 Jun 24 10:00 .',
        durationMs: 150,
        timestamp: timestamp,
      );
      await projectToDb(db, toolSuccess);

      final messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(
        messages.first.content,
        'total 0\ndrwxr-xr-x 2 user user 4096 Jun 24 10:00 .',
      );

      final toolResults = await db.select(db.toolResults).get();
      expect(toolResults.length, 1);
      expect(toolResults.first.id, 'tool_call_1');
      expect(toolResults.first.toolName, 'bash');
      expect(
        toolResults.first.outputText,
        'total 0\ndrwxr-xr-x 2 user user 4096 Jun 24 10:00 .',
      );
      expect(toolResults.first.durationMs, 150);
      expect(toolResults.first.status, 'success');
    });

    test(
      'ToolFailed updates tool message error and inserts tool_result',
      () async {
        // First create a tool call
        final toolCalled = ToolCalled(
          sessionId: sessionId,
          toolCallId: 'tool_call_1',
          toolName: 'bash',
          input: {'command': 'ls -la'},
          timestamp: timestamp,
        );
        await projectToDb(db, toolCalled);

        // Then record failure
        final toolFailed = ToolFailed(
          sessionId: sessionId,
          toolCallId: 'tool_call_1',
          error: 'Command failed with exit code 1',
          timestamp: timestamp,
        );
        await projectToDb(db, toolFailed);

        final messages = await db.select(db.messages).get();
        expect(messages.length, 1);
        expect(messages.first.error, 'Command failed with exit code 1');

        final toolResults = await db.select(db.toolResults).get();
        expect(toolResults.length, 1);
        expect(toolResults.first.id, 'tool_call_1');
        expect(toolResults.first.outputText, 'Command failed with exit code 1');
        expect(toolResults.first.status, 'error');
      },
    );

    test('StepEnded updates session token counts', () async {
      // First create a session
      final sessionCreated = SessionCreated(
        sessionId: sessionId,
        title: 'Test',
        agent: 'general',
        timestamp: timestamp,
      );
      await projectToDb(db, sessionCreated);

      // Then record step completion
      final stepEnded = StepEnded(
        sessionId: sessionId,
        stepNumber: 1,
        tokensInput: 100,
        tokensOutput: 200,
        tokensReasoning: 50,
        timestamp: timestamp,
      );
      await projectToDb(db, stepEnded);

      final sessions = await db.select(db.sessions).get();
      expect(sessions.length, 1);
      expect(sessions.first.tokensInput, 100);
      expect(sessions.first.tokensOutput, 200);
      expect(sessions.first.tokensReasoning, 50);
    });

    test('multiple events are projected correctly in sequence', () async {
      final events = [
        SessionCreated(
          sessionId: sessionId,
          title: 'Multi-event Session',
          agent: 'general',
          timestamp: timestamp,
        ),
        MessageAdded(
          sessionId: sessionId,
          messageId: 'msg_1',
          role: 'user',
          content: 'Hello',
          timestamp: timestamp,
        ),
        MessageAdded(
          sessionId: sessionId,
          messageId: 'msg_2',
          role: 'assistant',
          content: '',
          timestamp: timestamp,
        ),
      ];

      for (final event in events) {
        await projectToDb(db, event);
      }

      // Then update msg_2 with TextEnded
      final textEnded = TextEnded(
        sessionId: sessionId,
        messageId: 'msg_2',
        fullText: 'Hi there!',
        model: 'claude-3-5-sonnet',
        timestamp: timestamp,
      );
      await projectToDb(db, textEnded);

      final sessions = await db.select(db.sessions).get();
      expect(sessions.length, 1);

      final messages = await db.select(db.messages).get();
      expect(messages.length, 2);
      expect(messages[0].content, 'Hello');
      expect(messages[1].content, 'Hi there!');
    });
  });

  group('InsertMode.insertOrReplace duplicate handling', () {
    late AppDatabase db;
    late SessionID sessionId;
    late DateTime timestamp;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sessionId = SessionID.create();
      timestamp = DateTime.now();
    });

    tearDown(() async {
      await db.close();
    });

    test('insertOrReplace replaces existing message, not duplicate', () async {
      // Insert a message
      final messageAdded = MessageAdded(
        sessionId: sessionId,
        messageId: 'msg_1',
        role: 'user',
        content: 'Original content',
        timestamp: timestamp,
      );
      await projectToDb(db, messageAdded);

      // Verify it was inserted
      var messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.content, 'Original content');

      // Insert again with same ID but different content (simulating duplicate)
      final duplicateMessage = MessageAdded(
        sessionId: sessionId,
        messageId: 'msg_1',
        role: 'user',
        content: 'Updated content',
        timestamp: timestamp,
      );
      await projectToDb(db, duplicateMessage);

      // Should still be 1 message (replaced, not duplicated)
      messages = await db.select(db.messages).get();
      expect(messages.length, 1);
      expect(messages.first.content, 'Updated content');
    });

    test('insertOrReplace replaces tool_result, not duplicate', () async {
      // Create tool call
      final toolCalled = ToolCalled(
        sessionId: sessionId,
        toolCallId: 'tool_1',
        toolName: 'bash',
        input: {'command': 'echo hello'},
        timestamp: timestamp,
      );
      await projectToDb(db, toolCalled);

      // Record success
      final toolSuccess = ToolSuccess(
        sessionId: sessionId,
        toolCallId: 'tool_1',
        outputText: 'hello',
        durationMs: 100,
        timestamp: timestamp,
      );
      await projectToDb(db, toolSuccess);

      var toolResults = await db.select(db.toolResults).get();
      expect(toolResults.length, 1);
      expect(toolResults.first.outputText, 'hello');

      // Record success again with same ID (simulating duplicate)
      final duplicateSuccess = ToolSuccess(
        sessionId: sessionId,
        toolCallId: 'tool_1',
        outputText: 'hello updated',
        durationMs: 200,
        timestamp: timestamp,
      );
      await projectToDb(db, duplicateSuccess);

      // Should still be 1 result (replaced, not duplicated)
      toolResults = await db.select(db.toolResults).get();
      expect(toolResults.length, 1);
      expect(toolResults.first.outputText, 'hello updated');
      expect(toolResults.first.durationMs, 200);
    });

    test(
      'insertOrReplace on Messages table with same id updates row',
      () async {
        // Insert via raw SQL to test insertOrReplace directly
        await db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                id: 'raw_msg_1',
                sessionId: sessionId.value,
                seq: 1,
                role: 'user',
                content: Value('Original'),
                createdAt: timestamp,
              ),
              mode: InsertMode.insertOrReplace,
            );

        var messages = await db.select(db.messages).get();
        expect(messages.length, 1);
        expect(messages.first.content, 'Original');

        // Insert again with same ID
        await db
            .into(db.messages)
            .insert(
              MessagesCompanion.insert(
                id: 'raw_msg_1',
                sessionId: sessionId.value,
                seq: 1,
                role: 'user',
                content: Value('Replaced'),
                createdAt: timestamp,
              ),
              mode: InsertMode.insertOrReplace,
            );

        // Should still be 1 row
        messages = await db.select(db.messages).get();
        expect(messages.length, 1);
        expect(messages.first.content, 'Replaced');
      },
    );
  });

  group('projectEvent (pure function)', () {
    test('SessionCreated creates initial state', () {
      final event = SessionCreated(
        sessionId: SessionID.fromString('ses_test'),
        title: 'Test',
        agent: 'general',
        modelRef: 'claude-3-5-sonnet',
        timestamp: DateTime(2024, 1, 1),
      );

      final state = projectEvent(_createInitialState(), event);

      expect(state.id.value, 'ses_test');
      expect(state.title, 'Test');
      expect(state.agent, 'general');
      expect(state.modelRef, 'claude-3-5-sonnet');
    });

    test('MessageAdded appends message to state', () {
      final event = SessionCreated(
        sessionId: SessionID.fromString('ses_test'),
        timestamp: DateTime(2024, 1, 1),
      );
      var state = projectEvent(_createInitialState(), event);

      final messageAdded = MessageAdded(
        sessionId: SessionID.fromString('ses_test'),
        messageId: 'msg_1',
        role: 'user',
        content: 'Hello',
        timestamp: DateTime(2024, 1, 2),
      );
      state = projectEvent(state, messageAdded);

      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'Hello');
      expect(state.messages.first.role, MessageRole.user);
    });

    test('replayEvents rebuilds state from event list', () {
      final events = [
        SessionCreated(
          sessionId: SessionID.fromString('ses_replay'),
          title: 'Replay Test',
          agent: 'explore',
          timestamp: DateTime(2024, 1, 1),
        ),
        MessageAdded(
          sessionId: SessionID.fromString('ses_replay'),
          messageId: 'msg_1',
          role: 'user',
          content: 'Test message',
          timestamp: DateTime(2024, 1, 2),
        ),
      ];

      final state = replayEvents(events);

      expect(state.id.value, 'ses_replay');
      expect(state.title, 'Replay Test');
      expect(state.agent, 'explore');
      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'Test message');
    });
  });
}
