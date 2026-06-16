import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/data/models/chat/chat_message_export.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';

void main() {
  // ── Enums ──────────────────────────────────────────────────

  group('ToolState', () {
    test('has four values', () {
      expect(ToolState.values.length, 4);
    });

    test('values are in expected order', () {
      expect(ToolState.values[0], ToolState.pending);
      expect(ToolState.values[1], ToolState.running);
      expect(ToolState.values[2], ToolState.completed);
      expect(ToolState.values[3], ToolState.error);
    });

    test('name serialization works via values.byName', () {
      expect(ToolState.values.byName('pending'), ToolState.pending);
      expect(ToolState.values.byName('running'), ToolState.running);
      expect(ToolState.values.byName('completed'), ToolState.completed);
      expect(ToolState.values.byName('error'), ToolState.error);
    });
  });

  group('TaskStatus', () {
    test('has three values', () {
      expect(TaskStatus.values.length, 3);
    });

    test('values are running, completed, error', () {
      expect(TaskStatus.values, contains(TaskStatus.running));
      expect(TaskStatus.values, contains(TaskStatus.completed));
      expect(TaskStatus.values, contains(TaskStatus.error));
    });
  });

  group('TodoStatus', () {
    test('has four values', () {
      expect(TodoStatus.values.length, 4);
    });

    test('values include pending, inProgress, completed, cancelled', () {
      expect(TodoStatus.values, contains(TodoStatus.pending));
      expect(TodoStatus.values, contains(TodoStatus.inProgress));
      expect(TodoStatus.values, contains(TodoStatus.completed));
      expect(TodoStatus.values, contains(TodoStatus.cancelled));
    });
  });

  // ── TextPart ───────────────────────────────────────────────

  group('TextPart', () {
    test('creates with content and defaults', () {
      const part = TextPart(content: 'Hello world');
      expect(part.content, 'Hello world');
      expect(part.isStreaming, false);
    });

    test('creates with isStreaming true', () {
      const part = TextPart(content: 'Streaming...', isStreaming: true);
      expect(part.isStreaming, true);
    });

    test('copyWith updates content', () {
      const part = TextPart(content: 'original');
      final updated = part.copyWith(content: 'updated');
      expect(updated.content, 'updated');
      expect(updated.isStreaming, false); // unchanged
    });

    test('copyWith updates isStreaming', () {
      const part = TextPart(content: 'text', isStreaming: false);
      final updated = part.copyWith(isStreaming: true);
      expect(updated.isStreaming, true);
      expect(updated.content, 'text'); // unchanged
    });

    test('copyWith with null values preserves originals', () {
      const part = TextPart(content: 'text', isStreaming: true);
      final updated = part.copyWith();
      expect(updated.content, 'text');
      expect(updated.isStreaming, true);
    });

    test('toJson produces correct map', () {
      const part = TextPart(content: 'hello', isStreaming: true);
      final json = part.toJson();
      expect(json['type'], 'text');
      expect(json['content'], 'hello');
      expect(json['isStreaming'], true);
    });

    test('fromJson restores all fields', () {
      final json = {'type': 'text', 'content': 'restored', 'isStreaming': true};
      final part = TextPart.fromJson(json);
      expect(part.content, 'restored');
      expect(part.isStreaming, true);
    });

    test('fromJson defaults isStreaming to false', () {
      final json = {'type': 'text', 'content': 'no_streaming'};
      final part = TextPart.fromJson(json);
      expect(part.isStreaming, false);
    });

    test('roundtrip serialization preserves data', () {
      const original = TextPart(content: 'roundtrip', isStreaming: true);
      final restored = TextPart.fromJson(original.toJson());
      expect(restored.content, original.content);
      expect(restored.isStreaming, original.isStreaming);
    });
  });

  // ── ReasoningPart ──────────────────────────────────────────

  group('ReasoningPart', () {
    test('creates with content and optional title', () {
      const part = ReasoningPart(content: 'thinking...', title: 'Analysis');
      expect(part.content, 'thinking...');
      expect(part.title, 'Analysis');
      expect(part.isStreaming, false);
    });

    test('creates without title', () {
      const part = ReasoningPart(content: 'thinking...');
      expect(part.title, isNull);
    });

    test('copyWith updates content', () {
      const part = ReasoningPart(content: 'old', title: 'Title');
      final updated = part.copyWith(content: 'new');
      expect(updated.content, 'new');
      expect(updated.title, 'Title'); // unchanged
    });

    test('copyWith updates title', () {
      const part = ReasoningPart(content: 'c', title: 'old');
      final updated = part.copyWith(title: 'new');
      expect(updated.title, 'new');
    });

    test('toJson includes title when present', () {
      const part = ReasoningPart(content: 'c', title: 't');
      final json = part.toJson();
      expect(json['type'], 'reasoning');
      expect(json['content'], 'c');
      expect(json['title'], 't');
    });

    test('toJson omits null title from map', () {
      const part = ReasoningPart(content: 'c');
      final json = part.toJson();
      expect(json['title'], isNull);
    });

    test('fromJson with null title', () {
      final json = {'type': 'reasoning', 'content': 'c', 'title': null};
      final part = ReasoningPart.fromJson(json);
      expect(part.title, isNull);
    });

    test('roundtrip serialization', () {
      const original = ReasoningPart(content: 'reasoning', title: 'Step 1');
      final restored = ReasoningPart.fromJson(original.toJson());
      expect(restored.content, original.content);
      expect(restored.title, original.title);
    });
  });

  // ── ToolCallPart ───────────────────────────────────────────

  group('ToolCallPart', () {
    test('creates with required fields', () {
      final created = DateTime(2025, 1, 1, 12, 0);
      final part = ToolCallPart(
        toolCallId: 'call-123',
        toolName: 'bash',
        input: const {'command': 'echo hello'},
        createdAt: created,
      );
      expect(part.toolCallId, 'call-123');
      expect(part.toolName, 'bash');
      expect(part.input, {'command': 'echo hello'});
      expect(part.createdAt, created);
    });

    test('copyWith updates toolName', () {
      final created = DateTime(2025, 1, 1);
      final part = ToolCallPart(
        toolCallId: 'id',
        toolName: 'bash',
        input: const {},
        createdAt: created,
      );
      final updated = part.copyWith(toolName: 'read');
      expect(updated.toolName, 'read');
      expect(updated.toolCallId, 'id'); // unchanged
    });

    test('toJson serializes createdAt as ISO8601', () {
      final created = DateTime(2025, 6, 15, 10, 30);
      final part = ToolCallPart(
        toolCallId: 'id',
        toolName: 'grep',
        input: const {'pattern': 'test'},
        createdAt: created,
      );
      final json = part.toJson();
      expect(json['type'], 'tool_call');
      expect(json['toolCallId'], 'id');
      expect(json['toolName'], 'grep');
      expect(json['createdAt'], created.toIso8601String());
    });

    test('fromJson parses ISO8601 createdAt', () {
      final created = DateTime(2025, 6, 15, 10, 30);
      final json = {
        'type': 'tool_call',
        'toolCallId': 'id',
        'toolName': 'grep',
        'input': {'pattern': 'test'},
        'createdAt': created.toIso8601String(),
      };
      final part = ToolCallPart.fromJson(json);
      expect(part.createdAt, created);
    });

    test('fromJson defaults input to empty map', () {
      final json = {
        'type': 'tool_call',
        'toolCallId': 'id',
        'toolName': 'read',
        'createdAt': DateTime.now().toIso8601String(),
      };
      final part = ToolCallPart.fromJson(json);
      expect(part.input, {});
    });

    test('roundtrip serialization', () {
      final created = DateTime(2025, 3, 15, 8, 0);
      final original = ToolCallPart(
        toolCallId: 'tc-1',
        toolName: 'write',
        input: const {'path': 'file.txt', 'content': 'hello'},
        createdAt: created,
      );
      final restored = ToolCallPart.fromJson(original.toJson());
      expect(restored.toolCallId, original.toolCallId);
      expect(restored.toolName, original.toolName);
      expect(restored.input, original.input);
      expect(restored.createdAt, original.createdAt);
    });
  });

  // ── ToolResultPart ─────────────────────────────────────────

  group('ToolResultPart', () {
    test('creates with running state by default', () {
      const part = ToolResultPart(toolCallId: 'call-1', toolName: 'bash');
      expect(part.state, ToolState.running);
      expect(part.result, isNull);
      expect(part.error, isNull);
      expect(part.duration, isNull);
      expect(part.input, isNull);
      expect(part.isStreaming, false);
    });

    test('creates with all fields specified', () {
      const part = ToolResultPart(
        toolCallId: 'call-1',
        toolName: 'read',
        result: 'file content',
        error: null,
        state: ToolState.completed,
        duration: Duration(milliseconds: 150),
        input: {'path': 'file.txt'},
        isStreaming: true,
      );
      expect(part.result, 'file content');
      expect(part.state, ToolState.completed);
      expect(part.duration, Duration(milliseconds: 150));
      expect(part.input, {'path': 'file.txt'});
      expect(part.isStreaming, true);
    });

    test('copyWith updates state to completed', () {
      const part = ToolResultPart(
        toolCallId: 'call-1',
        toolName: 'bash',
        state: ToolState.running,
      );
      final updated = part.copyWith(
        state: ToolState.completed,
        result: 'output',
      );
      expect(updated.state, ToolState.completed);
      expect(updated.result, 'output');
      expect(updated.toolCallId, 'call-1'); // unchanged
    });

    test('copyWith updates error', () {
      const part = ToolResultPart(
        toolCallId: 'call-1',
        toolName: 'bash',
        state: ToolState.running,
      );
      final updated = part.copyWith(
        error: 'File not found',
        state: ToolState.error,
      );
      expect(updated.error, 'File not found');
      expect(updated.state, ToolState.error);
    });

    test('toJson serializes state as name and duration as ms', () {
      const part = ToolResultPart(
        toolCallId: 'call-1',
        toolName: 'bash',
        result: 'output',
        state: ToolState.completed,
        duration: Duration(milliseconds: 200),
        input: {'cmd': 'ls'},
        isStreaming: false,
      );
      final json = part.toJson();
      expect(json['type'], 'tool_result');
      expect(json['toolCallId'], 'call-1');
      expect(json['toolName'], 'bash');
      expect(json['result'], 'output');
      expect(json['state'], 'completed');
      expect(json['duration'], 200);
      expect(json['input'], {'cmd': 'ls'});
      expect(json['isStreaming'], false);
    });

    test('fromJson parses state from string', () {
      final json = {
        'type': 'tool_result',
        'toolCallId': 'call-1',
        'toolName': 'bash',
        'result': 'out',
        'state': 'completed',
        'duration': 300,
        'isStreaming': false,
      };
      final part = ToolResultPart.fromJson(json);
      expect(part.state, ToolState.completed);
      expect(part.duration, Duration(milliseconds: 300));
    });

    test('fromJson defaults to completed when state is null', () {
      final json = {
        'type': 'tool_result',
        'toolCallId': 'call-1',
        'toolName': 'bash',
        'result': 'out',
        'isStreaming': false,
      };
      final part = ToolResultPart.fromJson(json);
      expect(part.state, ToolState.completed);
    });

    test('fromJson with null duration', () {
      final json = {
        'type': 'tool_result',
        'toolCallId': 'call-1',
        'toolName': 'bash',
        'state': 'error',
        'duration': null,
        'isStreaming': false,
      };
      final part = ToolResultPart.fromJson(json);
      expect(part.duration, isNull);
    });

    test('roundtrip serialization', () {
      const original = ToolResultPart(
        toolCallId: 'tc-r1',
        toolName: 'read',
        result: 'content',
        state: ToolState.completed,
        duration: Duration(milliseconds: 42),
        input: {'path': 'f.txt'},
        isStreaming: false,
      );
      final restored = ToolResultPart.fromJson(original.toJson());
      expect(restored.toolCallId, original.toolCallId);
      expect(restored.toolName, original.toolName);
      expect(restored.result, original.result);
      expect(restored.state, original.state);
      expect(restored.duration, original.duration);
      expect(restored.input, original.input);
      expect(restored.isStreaming, original.isStreaming);
    });
  });

  // ── TaskPart ───────────────────────────────────────────────

  group('TaskPart', () {
    test('creates with running status by default', () {
      const part = TaskPart(description: 'Review code', agent: 'code-reviewer');
      expect(part.status, TaskStatus.running);
      expect(part.subtaskCount, 0);
      expect(part.completedCount, 0);
    });

    test('creates with all fields specified', () {
      const part = TaskPart(
        description: 'Analyze security',
        agent: 'security-auditor',
        status: TaskStatus.completed,
        subtaskCount: 5,
        completedCount: 5,
      );
      expect(part.status, TaskStatus.completed);
      expect(part.subtaskCount, 5);
      expect(part.completedCount, 5);
    });

    test('copyWith updates status', () {
      const part = TaskPart(description: 'task', agent: 'agent');
      final updated = part.copyWith(status: TaskStatus.completed);
      expect(updated.status, TaskStatus.completed);
      expect(updated.description, 'task'); // unchanged
    });

    test('copyWith updates completedCount', () {
      const part = TaskPart(
        description: 'task',
        agent: 'agent',
        subtaskCount: 10,
      );
      final updated = part.copyWith(completedCount: 7);
      expect(updated.completedCount, 7);
      expect(updated.subtaskCount, 10); // unchanged
    });

    test('toJson serializes status as name', () {
      const part = TaskPart(
        description: 'task',
        agent: 'explore',
        status: TaskStatus.error,
      );
      final json = part.toJson();
      expect(json['type'], 'task');
      expect(json['description'], 'task');
      expect(json['agent'], 'explore');
      expect(json['status'], 'error');
    });

    test('fromJson parses status from string', () {
      final json = {
        'type': 'task',
        'description': 'desc',
        'agent': 'agent',
        'status': 'completed',
        'subtaskCount': 3,
        'completedCount': 2,
      };
      final part = TaskPart.fromJson(json);
      expect(part.status, TaskStatus.completed);
      expect(part.subtaskCount, 3);
      expect(part.completedCount, 2);
    });

    test('fromJson defaults status to running', () {
      final json = {'type': 'task', 'description': 'desc', 'agent': 'agent'};
      final part = TaskPart.fromJson(json);
      expect(part.status, TaskStatus.running);
      expect(part.subtaskCount, 0);
      expect(part.completedCount, 0);
    });

    test('roundtrip serialization', () {
      const original = TaskPart(
        description: 'Deep analysis',
        agent: 'deepresearch',
        status: TaskStatus.completed,
        subtaskCount: 8,
        completedCount: 8,
      );
      final restored = TaskPart.fromJson(original.toJson());
      expect(restored.description, original.description);
      expect(restored.agent, original.agent);
      expect(restored.status, original.status);
      expect(restored.subtaskCount, original.subtaskCount);
      expect(restored.completedCount, original.completedCount);
    });
  });

  // ── QuestionPart ───────────────────────────────────────────

  group('QuestionPart', () {
    test('creates with question and empty options by default', () {
      const part = QuestionPart(question: 'Which approach?');
      expect(part.question, 'Which approach?');
      expect(part.options, isEmpty);
      expect(part.answer, isNull);
    });

    test('creates with options and answer', () {
      const part = QuestionPart(
        question: 'Choose one',
        options: ['Option A', 'Option B'],
        answer: 'Option A',
      );
      expect(part.options, ['Option A', 'Option B']);
      expect(part.answer, 'Option A');
    });

    test('copyWith updates answer', () {
      const part = QuestionPart(question: 'Choose?');
      final updated = part.copyWith(answer: 'B');
      expect(updated.answer, 'B');
      expect(updated.question, 'Choose?');
    });

    test('copyWith updates options', () {
      const part = QuestionPart(question: 'Q', options: ['old']);
      final updated = part.copyWith(options: ['new1', 'new2']);
      expect(updated.options, ['new1', 'new2']);
    });

    test('toJson roundtrip', () {
      const original = QuestionPart(
        question: 'Proceed?',
        options: ['Yes', 'No'],
        answer: 'Yes',
      );
      final json = original.toJson();
      expect(json['type'], 'question');
      final restored = QuestionPart.fromJson(json);
      expect(restored.question, original.question);
      expect(restored.options, original.options);
      expect(restored.answer, original.answer);
    });

    test('fromJson with null options', () {
      final json = {'type': 'question', 'question': 'Q', 'answer': null};
      final part = QuestionPart.fromJson(json);
      expect(part.options, isEmpty);
      expect(part.answer, isNull);
    });
  });

  // ── TodoItem ───────────────────────────────────────────────

  group('TodoItem', () {
    test('creates with pending status by default', () {
      const item = TodoItem(id: 't1', description: 'Write tests');
      expect(item.id, 't1');
      expect(item.description, 'Write tests');
      expect(item.status, TodoStatus.pending);
    });

    test('creates with explicit status', () {
      const item = TodoItem(
        id: 't2',
        description: 'Done task',
        status: TodoStatus.completed,
      );
      expect(item.status, TodoStatus.completed);
    });

    test('copyWith updates description', () {
      const item = TodoItem(id: 't1', description: 'old');
      final updated = item.copyWith(description: 'new');
      expect(updated.description, 'new');
      expect(updated.id, 't1'); // id is immutable
    });

    test('copyWith updates status', () {
      const item = TodoItem(id: 't1', description: 'task');
      final updated = item.copyWith(status: TodoStatus.inProgress);
      expect(updated.status, TodoStatus.inProgress);
    });

    test('id is immutable via copyWith', () {
      const item = TodoItem(id: 'original', description: 'task');
      // The copyWith method does not accept id parameter,
      // so the original id is always preserved.
      final updated = item.copyWith(description: 'changed');
      expect(updated.id, 'original');
    });

    test('toJson roundtrip', () {
      const original = TodoItem(
        id: 'todo-1',
        description: 'Implement feature',
        status: TodoStatus.inProgress,
      );
      final restored = TodoItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.status, original.status);
    });

    test('fromJson defaults status to pending', () {
      final json = {'id': 't1', 'description': 'task'};
      final item = TodoItem.fromJson(json);
      expect(item.status, TodoStatus.pending);
    });
  });

  // ── TodoPart ───────────────────────────────────────────────

  group('TodoPart', () {
    test('creates with todo list', () {
      const part = TodoPart(
        todos: [
          TodoItem(id: '1', description: 'First'),
          TodoItem(id: '2', description: 'Second'),
        ],
        isStreaming: true,
      );
      expect(part.todos.length, 2);
      expect(part.isStreaming, true);
    });

    test('creates with empty todos', () {
      const part = TodoPart(todos: []);
      expect(part.todos, isEmpty);
      expect(part.isStreaming, false);
    });

    test('copyWith updates todos', () {
      const part = TodoPart(
        todos: [TodoItem(id: '1', description: 'old')],
      );
      final updated = part.copyWith(
        todos: [
          TodoItem(id: '1', description: 'old'),
          TodoItem(id: '2', description: 'new'),
        ],
      );
      expect(updated.todos.length, 2);
    });

    test('toJson serializes todos list', () {
      const part = TodoPart(
        todos: [
          TodoItem(id: '1', description: 'task1', status: TodoStatus.completed),
          TodoItem(id: '2', description: 'task2'),
        ],
      );
      final json = part.toJson();
      expect(json['type'], 'todo');
      expect(json['todos'], isList);
      expect((json['todos'] as List).length, 2);
    });

    test('fromJson restores todos list', () {
      final json = {
        'type': 'todo',
        'todos': [
          {'id': '1', 'description': 'task1', 'status': 'completed'},
          {'id': '2', 'description': 'task2', 'status': 'pending'},
        ],
        'isStreaming': false,
      };
      final part = TodoPart.fromJson(json);
      expect(part.todos.length, 2);
      expect(part.todos[0].status, TodoStatus.completed);
      expect(part.todos[1].status, TodoStatus.pending);
    });

    test('fromJson with empty/missing todos', () {
      final json = {'type': 'todo', 'isStreaming': false};
      final part = TodoPart.fromJson(json);
      expect(part.todos, isEmpty);
    });

    test('roundtrip serialization', () {
      const original = TodoPart(
        todos: [
          TodoItem(id: 'a', description: 'Alpha', status: TodoStatus.completed),
          TodoItem(id: 'b', description: 'Beta', status: TodoStatus.inProgress),
          TodoItem(id: 'c', description: 'Gamma'),
        ],
        isStreaming: false,
      );
      final restored = TodoPart.fromJson(original.toJson());
      expect(restored.todos.length, original.todos.length);
      for (var i = 0; i < restored.todos.length; i++) {
        expect(restored.todos[i].id, original.todos[i].id);
        expect(restored.todos[i].description, original.todos[i].description);
        expect(restored.todos[i].status, original.todos[i].status);
      }
      expect(restored.isStreaming, original.isStreaming);
    });
  });

  // ── MessagePart sealed class hierarchy ─────────────────────

  group('MessagePart sealed class', () {
    test('all parts are MessagePart subtypes', () {
      // Note: ToolCallPart uses non-const DateTime, so we build the list differently
      final toolCall = ToolCallPart(
        toolCallId: 'id',
        toolName: 'bash',
        input: const {},
        createdAt: DateTime(2025),
      );
      final parts = <MessagePart>[
        const TextPart(content: 'text'),
        const ReasoningPart(content: 'reasoning'),
        toolCall,
        const ToolResultPart(toolCallId: 'id', toolName: 'bash'),
        const TaskPart(description: 'task', agent: 'agent'),
        const QuestionPart(question: 'q'),
        const TodoPart(todos: []),
      ];
      expect(parts.length, 7); // 7 part types (ToolCallPart included above)
    });

    test('toJson on each part produces type discriminator', () {
      final parts = <MessagePart>[
        const TextPart(content: 'text'),
        const ReasoningPart(content: 'reasoning'),
        ToolCallPart(
          toolCallId: 'id',
          toolName: 'bash',
          input: const {},
          createdAt: DateTime(2025),
        ),
        const ToolResultPart(toolCallId: 'id', toolName: 'bash'),
        const TaskPart(description: 'task', agent: 'agent'),
        const QuestionPart(question: 'q'),
        const TodoPart(todos: []),
      ];
      final types = parts.map((p) => p.toJson()['type']).toSet();
      expect(types, {
        'text',
        'reasoning',
        'tool_call',
        'tool_result',
        'task',
        'question',
        'todo',
      });
    });
  });

  // ── AssistantMessage.fromJson dispatches parts ────────────
  // (_partFromJson is private; tested indirectly via fromJson)

  group('AssistantMessage.fromJson part dispatch', () {
    test('dispatches text part type via fromJson', () {
      final json = {
        'type': 'assistant',
        'id': 'a1',
        'parts': [
          {'type': 'text', 'content': 'hello'},
        ],
        'isStreaming': false,
        'continuationSuggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = AssistantMessage.fromJson(json);
      expect(msg.parts, hasLength(1));
      expect(msg.parts.first, isA<TextPart>());
      expect((msg.parts.first as TextPart).content, 'hello');
    });

    test('dispatches reasoning part type via fromJson', () {
      final json = {
        'type': 'assistant',
        'id': 'a2',
        'parts': [
          {'type': 'reasoning', 'content': 'thinking'},
        ],
        'isStreaming': false,
        'continuationSuggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = AssistantMessage.fromJson(json);
      expect(msg.parts.first, isA<ReasoningPart>());
    });

    test('dispatches tool_result part type via fromJson', () {
      final json = {
        'type': 'assistant',
        'id': 'a3',
        'parts': [
          {
            'type': 'tool_result',
            'toolCallId': 'id',
            'toolName': 'bash',
            'isStreaming': false,
          },
        ],
        'isStreaming': false,
        'continuationSuggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = AssistantMessage.fromJson(json);
      expect(msg.parts.first, isA<ToolResultPart>());
    });

    test('dispatches multiple mixed part types via fromJson', () {
      final json = {
        'type': 'assistant',
        'id': 'a4',
        'parts': [
          {'type': 'text', 'content': 'Response'},
          {'type': 'reasoning', 'content': 'Thought process'},
          {
            'type': 'tool_call',
            'toolCallId': 'tc1',
            'toolName': 'read',
            'input': {'path': 'file.txt'},
            'createdAt': DateTime.now().toIso8601String(),
          },
        ],
        'isStreaming': false,
        'continuationSuggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = AssistantMessage.fromJson(json);
      expect(msg.parts, hasLength(3));
      expect(msg.parts[0], isA<TextPart>());
      expect(msg.parts[1], isA<ReasoningPart>());
      expect(msg.parts[2], isA<ToolCallPart>());
    });

    test('handles empty parts list in fromJson', () {
      final json = {
        'type': 'assistant',
        'id': 'a5',
        'parts': [],
        'isStreaming': false,
        'continuationSuggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = AssistantMessage.fromJson(json);
      expect(msg.parts, isEmpty);
    });
  });

  // ── UserMessage ────────────────────────────────────────────

  group('UserMessage', () {
    test('creates with content and empty files by default', () {
      final msg = UserMessage(
        id: 'msg-1',
        content: 'Hello',
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.id, 'msg-1');
      expect(msg.content, 'Hello');
      expect(msg.files, isEmpty);
    });

    test('creates with files', () {
      final msg = UserMessage(
        id: 'msg-2',
        content: 'See attached',
        files: ['image.png', 'doc.pdf'],
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.files, ['image.png', 'doc.pdf']);
    });

    test('toJson roundtrip', () {
      final original = UserMessage(
        id: 'u1',
        content: 'test message',
        files: ['file.txt'],
        timestamp: DateTime(2025, 6, 1),
      );
      final json = original.toJson();
      expect(json['type'], 'user');
      final restored = UserMessage.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.files, original.files);
      expect(restored.timestamp, original.timestamp);
    });
  });

  // ── AssistantMessage ───────────────────────────────────────

  group('AssistantMessage', () {
    test('creates with empty parts by default', () {
      final msg = AssistantMessage(
        id: 'msg-1',
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.parts, isEmpty);
      expect(msg.model, isNull);
      expect(msg.isStreaming, false);
      expect(msg.continuationSuggestions, isEmpty);
    });

    test('creates with parts and model', () {
      final msg = AssistantMessage(
        id: 'msg-2',
        parts: const [TextPart(content: 'Hello')],
        model: 'claude-sonnet-4',
        isStreaming: true,
        continuationSuggestions: ['Tell me more', 'Go deeper'],
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.parts.length, 1);
      expect(msg.model, 'claude-sonnet-4');
      expect(msg.isStreaming, true);
      expect(msg.continuationSuggestions, ['Tell me more', 'Go deeper']);
    });

    test('copyWith updates parts', () {
      final msg = AssistantMessage(
        id: 'msg-1',
        parts: const [TextPart(content: 'old')],
        timestamp: DateTime(2025, 1, 1),
      );
      final updated = msg.copyWith(
        parts: const [TextPart(content: 'new')],
        isStreaming: true,
      );
      expect(updated.parts.length, 1);
      expect((updated.parts.first as TextPart).content, 'new');
      expect(updated.isStreaming, true);
      expect(updated.id, 'msg-1'); // unchanged
    });

    test('copyWith updates model', () {
      final msg = AssistantMessage(
        id: 'msg-1',
        model: 'old-model',
        timestamp: DateTime(2025, 1, 1),
      );
      final updated = msg.copyWith(model: 'new-model');
      expect(updated.model, 'new-model');
    });

    test('copyWith updates continuationSuggestions', () {
      final msg = AssistantMessage(
        id: 'msg-1',
        timestamp: DateTime(2025, 1, 1),
      );
      final updated = msg.copyWith(continuationSuggestions: ['suggestion']);
      expect(updated.continuationSuggestions, ['suggestion']);
    });

    test('toJson roundtrip', () {
      final original = AssistantMessage(
        id: 'a1',
        parts: const [
          TextPart(content: 'response'),
          ReasoningPart(content: 'thought'),
        ],
        model: 'gpt-4o',
        isStreaming: false,
        continuationSuggestions: ['Continue'],
        timestamp: DateTime(2025, 6, 15, 10, 30),
      );
      final json = original.toJson();
      expect(json['type'], 'assistant');
      expect(json['parts'], isList);
      expect((json['parts'] as List).length, 2);
      final restored = AssistantMessage.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.parts.length, original.parts.length);
      expect(restored.model, original.model);
      expect(restored.isStreaming, original.isStreaming);
      expect(
        restored.continuationSuggestions,
        original.continuationSuggestions,
      );
      expect(restored.timestamp, original.timestamp);
    });

    test('fromJson with empty parts', () {
      final json = {
        'type': 'assistant',
        'id': 'a1',
        'parts': [],
        'model': null,
        'isStreaming': false,
        'continuationSuggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = AssistantMessage.fromJson(json);
      expect(msg.parts, isEmpty);
      expect(msg.model, isNull);
    });
  });

  // ── SystemMessage ─────────────────────────────────────────

  group('SystemMessage', () {
    test('creates with content', () {
      final msg = SystemMessage(
        id: 'sys-1',
        content: 'You are a helpful assistant',
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.content, 'You are a helpful assistant');
    });

    test('toJson roundtrip', () {
      final original = SystemMessage(
        id: 's1',
        content: 'System prompt',
        timestamp: DateTime(2025, 3, 1),
      );
      final restored = SystemMessage.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.timestamp, original.timestamp);
    });
  });

  // ── ErrorMessage ──────────────────────────────────────────

  group('ErrorMessage', () {
    test('creates with content and optional code/type', () {
      final msg = ErrorMessage(
        id: 'err-1',
        content: 'Something went wrong',
        code: 'RATE_LIMIT',
        type: 'api_error',
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.content, 'Something went wrong');
      expect(msg.code, 'RATE_LIMIT');
      expect(msg.type, 'api_error');
    });

    test('creates with null code and type', () {
      final msg = ErrorMessage(
        id: 'err-2',
        content: 'Unknown error',
        timestamp: DateTime(2025, 1, 1),
      );
      expect(msg.code, isNull);
      expect(msg.type, isNull);
    });

    test('toJson uses errorType key for type field', () {
      final msg = ErrorMessage(
        id: 'e1',
        content: 'err',
        code: 'C',
        type: 'T',
        timestamp: DateTime(2025, 1, 1),
      );
      final json = msg.toJson();
      expect(json['type'], 'error');
      expect(json['errorType'], 'T');
      expect(json['code'], 'C');
    });

    test('fromJson reads errorType key', () {
      final json = {
        'type': 'error',
        'id': 'e1',
        'content': 'err',
        'code': 'C',
        'errorType': 'T',
        'timestamp': DateTime.now().toIso8601String(),
      };
      final msg = ErrorMessage.fromJson(json);
      expect(msg.type, 'T');
      expect(msg.code, 'C');
    });

    test('roundtrip serialization', () {
      final original = ErrorMessage(
        id: 'err-rt',
        content: 'Rate limit exceeded',
        code: '429',
        type: 'rate_limit',
        timestamp: DateTime(2025, 6, 1),
      );
      final restored = ErrorMessage.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.code, original.code);
      expect(restored.type, original.type);
      expect(restored.timestamp, original.timestamp);
    });
  });

  // ── ChatMessage sealed class hierarchy ─────────────────────

  group('ChatMessage sealed class', () {
    test('all message types are ChatMessage subtypes', () {
      final messages = <ChatMessage>[
        UserMessage(id: 'u', content: 'hi', timestamp: DateTime(2025)),
        AssistantMessage(id: 'a', timestamp: DateTime(2025)),
        SystemMessage(id: 's', content: 'sys', timestamp: DateTime(2025)),
        ErrorMessage(id: 'e', content: 'err', timestamp: DateTime(2025)),
      ];
      expect(messages.length, 4);
    });

    test('toJson on each message produces correct type discriminator', () {
      final messages = <ChatMessage>[
        UserMessage(id: 'u', content: 'hi', timestamp: DateTime(2025)),
        AssistantMessage(id: 'a', timestamp: DateTime(2025)),
        SystemMessage(id: 's', content: 'sys', timestamp: DateTime(2025)),
        ErrorMessage(id: 'e', content: 'err', timestamp: DateTime(2025)),
      ];
      final types = messages.map((m) => m.toJson()['type']).toSet();
      expect(types, {'user', 'assistant', 'system', 'error'});
    });
  });

  // ── messageToChatMessage conversion ────────────────────────

  group('messageToChatMessage conversion', () {
    test('converts user message', () {
      final legacy = Message(
        role: MessageRole.user,
        content: 'Hello',
        timestamp: DateTime(2025, 1, 1),
      );
      final converted = messageToChatMessage(legacy);
      expect(converted, isA<UserMessage>());
      expect((converted as UserMessage).content, 'Hello');
    });

    test('converts assistant message with content', () {
      final legacy = Message(
        role: MessageRole.assistant,
        content: 'Response text',
        timestamp: DateTime(2025, 1, 1),
      );
      final converted = messageToChatMessage(legacy);
      expect(converted, isA<AssistantMessage>());
      final assistant = converted as AssistantMessage;
      expect(assistant.parts, hasLength(1));
      expect(assistant.parts.first, isA<TextPart>());
      expect((assistant.parts.first as TextPart).content, 'Response text');
    });

    test('converts assistant message with reasoning', () {
      final legacy = Message(
        role: MessageRole.assistant,
        content: 'Answer',
        reasoning: 'Let me think...',
        timestamp: DateTime(2025, 1, 1),
      );
      final converted = messageToChatMessage(legacy);
      final assistant = converted as AssistantMessage;
      expect(assistant.parts, hasLength(2));
      expect(assistant.parts[0], isA<ReasoningPart>());
      expect(assistant.parts[1], isA<TextPart>());
    });

    test('converts assistant message preserving model', () {
      final legacy = Message(
        role: MessageRole.assistant,
        content: 'Hi',
        model: 'claude-sonnet-4',
        timestamp: DateTime(2025, 1, 1),
      );
      final converted = messageToChatMessage(legacy);
      expect((converted as AssistantMessage).model, 'claude-sonnet-4');
    });

    test('converts system message', () {
      final legacy = Message(
        role: MessageRole.system,
        content: 'System prompt',
        timestamp: DateTime(2025, 1, 1),
      );
      final converted = messageToChatMessage(legacy);
      expect(converted, isA<SystemMessage>());
      expect((converted as SystemMessage).content, 'System prompt');
    });

    test('converts error message', () {
      final legacy = Message(
        role: MessageRole.assistant,
        content: 'Error occurred',
        isError: true,
        timestamp: DateTime(2025, 1, 1),
      );
      final converted = messageToChatMessage(legacy);
      expect(converted, isA<ErrorMessage>());
      expect((converted as ErrorMessage).content, 'Error occurred');
    });

    test('preserves id and timestamp through conversion', () {
      final ts = DateTime(2025, 6, 15, 14, 30);
      final legacy = Message(
        id: 'legacy-id-123',
        role: MessageRole.user,
        content: 'test',
        timestamp: ts,
      );
      final converted = messageToChatMessage(legacy);
      expect(converted.id, 'legacy-id-123');
      expect(converted.timestamp, ts);
    });
  });
}
