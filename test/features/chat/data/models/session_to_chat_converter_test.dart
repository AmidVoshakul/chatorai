import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_state.dart' as session_state;
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart'
    show
        AssistantReasoning,
        AssistantText,
        AssistantTool,
        AssistantTask,
        AssistantQuestion,
        AssistantTodo,
        AssistantFile;
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart'
    show ToolState;
import 'package:chatorai/features/chat/data/models/chat/message_converter.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';

void main() {
  group('assistantContentToMessagePart', () {
    test(
      'AssistantReasoning converts with isStreaming=true when ended is null',
      () {
        final p = AssistantReasoning(
          id: 'p1',
          sessionId: 'ses',
          messageId: 'm',
          text: 'thinking',
          started: DateTime.now(),
          ended: null,
        );
        final json = assistantContentToPartMaps([p]).first;

        expect(json['type'], 'reasoning');
        expect(
          json['content'],
          'thinking',
          reason: 'must use MessagePart schema "content" key',
        );
        expect(
          json['isStreaming'],
          true,
          reason: 'streaming reasoning must be marked as such',
        );
        expect(
          json['durationMs'],
          isNull,
          reason: 'duration cannot be computed when ended is null',
        );
      },
    );

    test(
      'AssistantReasoning converts with isStreaming=false and duration set',
      () {
        final now = DateTime.now();
        final p = AssistantReasoning(
          id: 'p1',
          sessionId: 'ses',
          messageId: 'm',
          text: 'thinking',
          started: now.subtract(const Duration(seconds: 2)),
          ended: now,
        );
        final json = assistantContentToPartMaps([p]).first;

        expect(json['isStreaming'], false);
        expect(
          json['durationMs'],
          isA<int>(),
          reason: 'completed reasoning has durationMs',
        );
        expect(json['durationMs'], greaterThan(1500));
      },
    );

    test('AssistantText converts to TextPart with content', () {
      final p = AssistantText(
        id: 'p1',
        sessionId: 'ses',
        messageId: 'm',
        text: 'hello',
        synthetic: true,
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['type'], 'text');
      expect(json['content'], 'hello');
    });

    test('AssistantTool converts to ToolResultPart schema', () {
      final p = AssistantTool(
        id: 'p1',
        sessionId: 'ses',
        messageId: 'm',
        callId: 'tc_x',
        tool: 'shell',
        state: ToolState.completed,
        input: {'cmd': 'ls'},
        output: 'file1.txt',
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(
        json['type'],
        'tool_result',
        reason: 'must use "tool_result" type, not "tool"',
      );
      expect(
        json['toolName'],
        'shell',
        reason: 'must use "toolName" key, not "tool"',
      );
      expect(
        json['toolCallId'],
        'tc_x',
        reason: 'must use "toolCallId" key, not "callId"',
      );
      expect(
        json['result'],
        'file1.txt',
        reason: 'must use "result" key, not "output"',
      );
      expect(json['state'], 'completed');
    });

    test('AssistantTool with error state has error field set', () {
      final p = AssistantTool(
        id: 'p1',
        sessionId: 'ses',
        messageId: 'm',
        callId: 'tc_x',
        tool: 'shell',
        state: ToolState.error,
        input: {},
        output: 'command not found',
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['state'], 'error');
      expect(json['error'], 'command not found');
    });

    test('AssistantTask converts with status (not state) — critical fix', () {
      final p = AssistantTask(
        id: 'task_1',
        sessionId: 'ses',
        messageId: 'm',
        description: 'Do thing',
        agent: 'explore',
        state: ToolState.completed,
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        endedAt: DateTime.now(),
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['type'], 'task');
      expect(
        json['status'],
        'completed',
        reason:
            'must use "status" key — TaskPart.fromJson parses this to '
            'avoid stale TaskStatus.running default',
      );
      expect(json['description'], 'Do thing');
      expect(json['agent'], 'explore');
      // durationMs may be null in schema — TaskPart computes from startedAt when needed
      expect(json.containsKey('durationMs'), isTrue);
    });

    test('AssistantTask with running state serializes as status=running', () {
      final p = AssistantTask(
        id: 'task_1',
        sessionId: 'ses',
        messageId: 'm',
        description: 'Do thing',
        agent: 'explore',
        state: ToolState.running,
        startedAt: DateTime.now(),
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['status'], 'running');
    });

    test('AssistantQuestion converts to QuestionPart with options', () {
      final p = AssistantQuestion(
        id: 'q1',
        sessionId: 'ses',
        messageId: 'm',
        question: 'Pick one',
        options: const [
          QuestionOption(label: 'A', description: null),
          QuestionOption(label: 'B', description: null),
          QuestionOption(label: 'C', description: null),
        ],
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['type'], 'question');
      expect(json['question'], 'Pick one');
      expect(json['options'], [
        {'label': 'A'},
        {'label': 'B'},
        {'label': 'C'},
      ]);
    });

    test('AssistantTodo converts to TodoPart', () {
      final p = AssistantTodo(
        id: 'todo_1',
        sessionId: 'ses',
        messageId: 'm',
        todos: const [],
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['type'], 'todo');
    });

    test('AssistantFile converts to placeholder TextPart with filename', () {
      final p = AssistantFile(
        id: 'f1',
        sessionId: 'ses',
        messageId: 'm',
        filename: 'doc.pdf',
        mimeType: 'application/pdf',
        url: '/local/path',
      );
      final json = assistantContentToPartMaps([p]).first;

      expect(json['type'], 'text');
      expect(json['content'], '[File: doc.pdf]');
    });

    test('natural provider order: full block of 8 parts JSON shape', () {
      // Simulation of: reasoning -> text -> reasoning -> tool -> tool ->
      // tool -> reasoning -> text. Verifies the deliberate block boundaries.
      final fixed = DateTime.now();
      final parts = [
        AssistantReasoning(
          id: 'r1',
          sessionId: 'ses',
          messageId: 'm',
          text: 'reasoning 1',
          started: fixed.subtract(const Duration(seconds: 1)),
          ended: fixed,
        ),
        AssistantText(
          id: 't1',
          sessionId: 'ses',
          messageId: 'm',
          text: 'text 1',
          synthetic: false,
        ),
        AssistantReasoning(
          id: 'r2',
          sessionId: 'ses',
          messageId: 'm',
          text: 'reasoning 2',
          started: fixed.subtract(const Duration(milliseconds: 500)),
          ended: fixed,
        ),
        AssistantTool(
          id: 'tc1',
          sessionId: 'ses',
          messageId: 'm',
          callId: 'tc_1',
          tool: 'shell',
          state: ToolState.completed,
          input: {},
          output: 'out1',
        ),
        AssistantTool(
          id: 'tc2',
          sessionId: 'ses',
          messageId: 'm',
          callId: 'tc_2',
          tool: 'cat',
          state: ToolState.completed,
          input: {},
          output: 'out2',
        ),
        AssistantTool(
          id: 'tc3',
          sessionId: 'ses',
          messageId: 'm',
          callId: 'tc_3',
          tool: 'grep',
          state: ToolState.running,
          input: {},
        ),
        AssistantReasoning(
          id: 'r3',
          sessionId: 'ses',
          messageId: 'm',
          text: 'reasoning 3',
          started: fixed,
        ),
        AssistantText(
          id: 't2',
          sessionId: 'ses',
          messageId: 'm',
          text: 'text 2',
          synthetic: false,
        ),
      ];

      final json = assistantContentToPartMaps(parts);
      final types = json.map((j) => j['type']).toList();
      expect(types, [
        'reasoning',
        'text',
        'reasoning',
        'tool_result',
        'tool_result',
        'tool_result',
        'reasoning',
        'text',
      ]);

      // Verify closed reasoning has durationMs computed (started+ended in source)
      expect(
        json[0]['durationMs'],
        isA<int>(),
        reason:
            'closed AssistantReasoning → closed ReasoningPart with duration',
      );

      // Note: TextPart has its own isStreaming flag (defaults false). Only
      // AssistantReasoning currently tracks streaming state via AssistantReasoning.ended.
    });
  });

  group('filterPartsByMessage', () {
    test('returns only parts belonging to the target messageId', () {
      final parts = [
        AssistantText(id: 't1', sessionId: 's1', messageId: 'm1', text: 'hello'),
        AssistantReasoning(
          id: 'r1',
          sessionId: 's1',
          messageId: 'm1',
          text: 'thinking',
          started: DateTime.now(),
        ),
        AssistantText(id: 't2', sessionId: 's1', messageId: 'm2', text: 'other'),
      ];

      final filtered = filterPartsByMessage(parts, 'm1');

      expect(filtered, hasLength(2));
      expect(filtered.whereType<AssistantText>(), hasLength(1));
      expect(filtered.whereType<AssistantReasoning>(), hasLength(1));
    });

    test('returns empty list when no parts match the messageId', () {
      final parts = [
        AssistantText(id: 't1', sessionId: 's1', messageId: 'm1', text: 'hello'),
      ];

      final filtered = filterPartsByMessage(parts, 'm2');

      expect(filtered, isEmpty);
    });

    test('includes tools and other part types for the target message', () {
      final parts = [
        AssistantTool(
          id: 'tc1',
          sessionId: 's1',
          messageId: 'm1',
          callId: 'c1',
          tool: 'shell',
          state: ToolState.completed,
          input: {},
          output: 'out',
        ),
        AssistantTask(
          id: 'task1',
          sessionId: 's1',
          messageId: 'm1',
          description: 'do',
          agent: 'a',
          state: ToolState.running,
        ),
        AssistantText(id: 't1', sessionId: 's1', messageId: 'm2', text: 'other'),
      ];

      final filtered = filterPartsByMessage(parts, 'm1');

      expect(filtered, hasLength(2));
      expect(filtered.whereType<AssistantTool>(), hasLength(1));
      expect(filtered.whereType<AssistantTask>(), hasLength(1));
    });
  });

  group('sessionStateToChat', () {
    test('converts per-message tokens from StepEnded replay', () {
      final now = DateTime.now();
      final state = session_state.SessionState(
        id: SessionID.fromString('ses_1'),
        createdAt: now,
        updatedAt: now,
        messages: [
          session_state.SessionMessage(
            id: 'u1',
            role: session_state.MessageRole.user,
            content: 'hi',
            seq: 1,
            createdAt: now,
          ),
          session_state.SessionMessage(
            id: 'a1',
            role: session_state.MessageRole.assistant,
            content: 'answer',
            seq: 2,
            createdAt: now,
            tokensInput: 100,
            tokensOutput: 50,
            tokensReasoning: 10,
          ),
        ],
      );

      final chat = sessionStateToChat(state);
      final assistant = chat.messages.firstWhere(
        (m) => m.role == MessageRole.assistant,
      );
      expect(assistant.tokensInput, 100);
      expect(assistant.tokensOutput, 50);
      expect(assistant.tokensReasoning, 10);
    });
  });
}
