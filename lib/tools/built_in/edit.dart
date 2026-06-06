import 'dart:io';
import '../tool.dart';
import 'path_sandbox.dart';

ToolDef createEditTool() {
  return ToolDef(
    id: 'edit',
    description: 'Edit a file by replacing text',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description': 'Path to the file to edit',
        },
        'old_string': {'type': 'string', 'description': 'Text to replace'},
        'new_string': {'type': 'string', 'description': 'Replacement text'},
      },
      'required': ['file_path', 'old_string', 'new_string'],
    },
    execute: (input, ctx) async {
      final filePath =
          input['file_path'] as String? ?? input['path'] as String?;
      final oldString =
          input['old_string'] as String? ?? input['oldString'] as String?;
      final newString =
          input['new_string'] as String? ?? input['newString'] as String?;

      if (filePath == null) throw ArgumentError('file_path is required');
      if (oldString == null) throw ArgumentError('old_string is required');
      if (newString == null) throw ArgumentError('new_string is required');

      final safePath = resolveSafePath(filePath);
      await ctx.ask(permission: 'edit', patterns: [safePath]);
      final file = File(safePath);
      if (!await file.exists()) {
        return ToolOutput(
          'Error: file not found: $safePath',
          metadata: {'error': true},
        );
      }

      var content = await file.readAsString();
      if (!content.contains(oldString)) {
        return ToolOutput(
          'Error: old_string not found in file',
          metadata: {'error': true},
        );
      }

      final newContent = content.replaceFirst(oldString, newString);
      await file.writeAsString(newContent);

      return ToolOutput(
        'File edited successfully',
        metadata: {'path': safePath},
      );
    },
  );
}
