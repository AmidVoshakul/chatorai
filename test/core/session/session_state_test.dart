import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart';

void main() {
  group('SessionState', () {
    test('create with required fields', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final state = SessionState(id: id, createdAt: now, updatedAt: now);

      expect(state.id, id);
      expect(state.title, '');
      expect(state.agent, 'general');
      expect(state.messages, isEmpty);
      expect(state.toolResults, isEmpty);
    });

    test('copyWith updates fields', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final state = SessionState(id: id, createdAt: now, updatedAt: now);

      final updated = state.copyWith(title: 'New Title', agent: 'explore');
      expect(updated.title, 'New Title');
      expect(updated.agent, 'explore');
    });

    test('copyWith clears parentId', () {
      final id = SessionID.create();
      final parentId = SessionID.create();
      final now = DateTime.now();
      final state = SessionState(
        id: id,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      );

      final cleared = state.copyWith(clearParentId: true);
      expect(cleared.parentId, isNull);
    });

    test('messages are immutable via copyWith', () {
      final id = SessionID.create();
      final now = DateTime.now();
      final state = SessionState(id: id, createdAt: now, updatedAt: now);

      final withMsg = state.copyWith(
        messages: [
          SessionMessage(
            id: 'm1',
            role: MessageRole.user,
            content: 'Hi',
            seq: 1,
            createdAt: now,
          ),
        ],
      );
      expect(withMsg.messages.length, 1);
      expect(state.messages, isEmpty);
    });
  });

  group('SessionMessage', () {
    test('copyWith updates content', () {
      final msg = SessionMessage(
        id: 'm1',
        role: MessageRole.user,
        content: 'Hi',
        seq: 1,
        createdAt: DateTime.now(),
      );
      final updated = msg.copyWith(content: 'Hello');
      expect(updated.content, 'Hello');
      expect(updated.id, 'm1');
    });

    test('equality works', () {
      final now = DateTime.now();
      final a = SessionMessage(
        id: 'm1',
        role: MessageRole.user,
        content: 'Hi',
        seq: 1,
        createdAt: now,
      );
      final b = SessionMessage(
        id: 'm1',
        role: MessageRole.user,
        content: 'Hi',
        seq: 1,
        createdAt: now,
      );
      expect(a, b);
    });

    test('different content breaks equality', () {
      final now = DateTime.now();
      final a = SessionMessage(
        id: 'm1',
        role: MessageRole.user,
        content: 'Hi',
        seq: 1,
        createdAt: now,
      );
      final b = SessionMessage(
        id: 'm1',
        role: MessageRole.user,
        content: 'Hello',
        seq: 1,
        createdAt: now,
      );
      expect(a, isNot(b));
    });
  });

  group('ToolResult', () {
    test('create tool result', () {
      final now = DateTime.now();
      final result = ToolResult(
        id: 'tr1',
        toolName: 'shell',
        input: {'cmd': 'ls'},
        outputText: 'files',
        durationMs: 100,
        status: 'success',
        createdAt: now,
      );
      expect(result.toolName, 'shell');
      expect(result.status, 'success');
    });
  });

  group('MessageRole', () {
    test('user toString', () {
      expect(MessageRole.user.toString(), 'MessageRole.user');
    });

    test('assistant toString', () {
      expect(MessageRole.assistant.toString(), 'MessageRole.assistant');
    });

    test('tool toString', () {
      expect(MessageRole.tool.toString(), 'MessageRole.tool');
    });
  });
}
