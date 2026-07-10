import 'package:chatorai/core/tools/tool.dart';

// Simple in-memory todo store (MVP — no persistence yet)
final _todoStore = <String, List<Map<String, dynamic>>>{};

ToolDef createTodoWriteTool() {
  return ToolDef(
    id: 'todowrite',
    description:
        'Create and maintain a structured task list for the current session. Use to track progress on complex tasks.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'todos': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': 'Task description'},
              'status': {
                'type': 'string',
                'enum': ['pending', 'in_progress', 'completed', 'cancelled'],
                'description': 'Current status',
              },
              'priority': {
                'type': 'string',
                'enum': ['high', 'medium', 'low'],
                'description': 'Priority level',
              },
            },
            'required': ['content', 'status'],
          },
        },
      },
      'required': ['todos'],
    },
    execute: (input, ctx) async {
      // Validate: todos is required
      if (!input.containsKey('todos') || input['todos'] == null) {
        return ToolOutput(
          'Error: todos parameter is required',
          metadata: {'error': true},
        );
      }

      final todos = input['todos'] as List<dynamic>? ?? [];
      final sessionId = ctx.sessionId ?? 'default';

      // Ask permission with pattern including count
      await ctx.ask(
        permission: 'todowrite',
        patterns: ['todo_write:count=${todos.length}'],
      );

      // Store in memory (MVP — replace with SharedPreferences/Hive later)
      _todoStore[sessionId] = todos.cast<Map<String, dynamic>>().toList();

      final output = {'todos': todos};

      // Build output string
      String outputString;
      if (todos.isEmpty) {
        outputString = '[]';
      } else {
        outputString = todos
            .map(
              (t) =>
                  "[${(t['status'] ?? 'pending')}] ${(t['priority'] ?? 'medium')} ${(t['content'])}",
            )
            .join("\n");
      }

      // Build metadata: error = false for empty list, no error key for non-empty (null)
      final metadata = <String, dynamic>{
        'count': todos.length,
        'sessionId': sessionId,
        'todos': output,
      };
      if (todos.isEmpty) {
        metadata['error'] = false;
      }

      return ToolOutput(outputString, metadata: metadata);
    },
  );
}
