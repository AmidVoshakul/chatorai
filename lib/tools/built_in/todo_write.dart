import 'package:chatorai/tools/tool.dart';

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
      await ctx.ask(permission: 'todowrite', patterns: ['*']);
      final todos = input['todos'] as List<dynamic>? ?? [];
      final sessionId = ctx.sessionId ?? 'default';

      // Store in memory (MVP — replace with SharedPreferences/Hive later)
      _todoStore[sessionId] = todos.cast<Map<String, dynamic>>().toList();

      final output = {'todos': todos};

      return ToolOutput(
        'Todo list updated:\n${todos.map((t) => "[${(t['status'] ?? 'pending')}] ${(t['priority'] ?? 'medium')} ${(t['content'])}").join("\n")}',
        metadata: {
          'count': todos.length,
          'sessionId': sessionId,
          'todos': output,
        },
      );
    },
  );
}
