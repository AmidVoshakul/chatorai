import 'dart:convert';

import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_snapshot_codec.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:chatorai/features/chat/data/models/chat/question_part.dart';
import 'package:chatorai/features/chat/data/models/chat/reasoning_part.dart';
import 'package:chatorai/features/chat/data/models/chat/task_part.dart';
import 'package:chatorai/features/chat/data/models/chat/text_part.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/features/chat/data/models/chat/todo_part.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatSnapshotCodec', () {
    test('round-trip empty list', () {
      final encoded = encodeChatSnapshot(const []);
      expect(encoded, '[]');
      final decoded = decodeChatSnapshot(encoded);
      expect(decoded, isNotNull);
      expect(decoded, isEmpty);
    });

    test('round-trip UserMessage', () {
      final messages = <ChatMessage>[
        UserMessage(
          id: 'u1',
          content: 'Hello',
          files: const ['a.txt'],
          imageData: 'img',
          imageType: 'image/png',
          attachedDocName: 'doc.pdf',
          attachedDocPath: '/tmp/doc.pdf',
          timestamp: DateTime(2025, 1, 1),
        ),
      ];
      final encoded = encodeChatSnapshot(messages);
      final decoded = decodeChatSnapshot(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.length, 1);
      expect(decoded.single, isA<UserMessage>());
      final u = decoded.single as UserMessage;
      expect(u.id, 'u1');
      expect(u.content, 'Hello');
      expect(u.files, ['a.txt']);
      expect(u.imageData, 'img');
      expect(u.imageType, 'image/png');
      expect(u.attachedDocName, 'doc.pdf');
      expect(u.attachedDocPath, '/tmp/doc.pdf');
    });

    test('round-trip AssistantMessage with mixed parts', () {
      final messages = <ChatMessage>[
        AssistantMessage(
          id: 'a1',
          parts: const [
            TextPart(content: 'Hi', isStreaming: false),
            ReasoningPart(content: 'thinking', isStreaming: false),
            ToolResultPart(
              toolCallId: 'tc1',
              toolName: 'search',
              result: 'result text',
              state: ToolState.completed,
              isStreaming: false,
            ),
            TaskPart(
              description: 'do task',
              agent: 'general',
              status: TaskStatus.completed,
              sessionId: 'ses_1',
              toolCallsCount: 2,
            ),
            QuestionPart(
              question: 'Pick one',
              options: const [
                QuestionOption(label: 'A'),
                QuestionOption(label: 'B'),
              ],
              answer: 'A',
              multiple: false,
            ),
            TodoPart(
              todos: const [
                TodoItem(
                  id: 't1',
                  description: 'step1',
                  status: TodoStatus.completed,
                ),
              ],
            ),
          ],
          model: 'gpt-4',
          timestamp: DateTime(2025, 1, 1),
          tokensInput: 10,
          tokensOutput: 20,
          tokensReasoning: 5,
          contextLength: 100,
          agent: 'general',
          isCompactionSummary: false,
        ),
      ];
      final encoded = encodeChatSnapshot(messages);
      final decoded = decodeChatSnapshot(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.length, 1);
      expect(decoded.single, isA<AssistantMessage>());
      final a = decoded.single as AssistantMessage;
      expect(a.id, 'a1');
      expect(a.model, 'gpt-4');
      expect(a.parts.length, 6);
      expect(a.parts.whereType<TextPart>().single.content, 'Hi');
      expect(a.parts.whereType<ReasoningPart>().single.content, 'thinking');
      expect(a.parts.whereType<ToolResultPart>().single.toolName, 'search');
      expect(a.parts.whereType<TaskPart>().single.description, 'do task');
      expect(a.parts.whereType<QuestionPart>().single.question, 'Pick one');
      expect(a.parts.whereType<TodoPart>().single.todos.first.id, 't1');
    });

    test('round-trip SystemMessage and ErrorMessage', () {
      final messages = <ChatMessage>[
        SystemMessage(
          id: 's1',
          content: 'sys',
          timestamp: DateTime(2025, 1, 1),
        ),
        ErrorMessage(
          id: 'e1',
          content: 'oops',
          code: 'ERR',
          type: 'runtime',
          timestamp: DateTime(2025, 1, 1),
        ),
      ];
      final encoded = encodeChatSnapshot(messages);
      final decoded = decodeChatSnapshot(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.length, 2);
      expect(decoded[0], isA<SystemMessage>());
      expect(decoded[1], isA<ErrorMessage>());
      expect((decoded[1] as ErrorMessage).content, 'oops');
    });

    test('returns null for malformed JSON', () {
      expect(decodeChatSnapshot('not json'), isNull);
      expect(decodeChatSnapshot('{"bad": true}'), isNull);
    });

    test('returns null for unknown message type', () {
      final json = jsonEncode([
        {
          'type': 'unknown_type',
          'id': 'x',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ]);
      expect(decodeChatSnapshot(json), isNull);
    });
  });
}
