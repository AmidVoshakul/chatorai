import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';

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
        'replace_all': {
          'type': 'boolean',
          'description': 'Replace all occurrences (default: true)',
        },
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

      if (filePath == null) {
        return ToolOutput(
          'Error: file_path is required',
          metadata: {'error': true},
        );
      }
      if (oldString == null) {
        return ToolOutput(
          'Error: old_string is required',
          metadata: {'error': true},
        );
      }
      if (newString == null) {
        return ToolOutput(
          'Error: new_string is required',
          metadata: {'error': true},
        );
      }

      final safePath = resolveSafePath(filePath);
      // Use pattern 'edit:file_path=$safePath' as required
      await ctx.ask(permission: 'edit', patterns: ['edit:file_path=$safePath']);
      final file = File(safePath);
      if (!await file.exists()) {
        return ToolOutput(
          'Error: file not found: $safePath',
          metadata: {'error': true},
        );
      }

      var content = await file.readAsString(encoding: utf8);
      if (!content.contains(oldString)) {
        return ToolOutput(
          'Error: old_string not found in file',
          metadata: {'error': true},
        );
      }

      final replaceAll = input['replace_all'] as bool? ?? true;
      final newContent = replaceAll
          ? content.replaceAll(oldString, newString)
          : content.replaceFirst(oldString, newString);
      await file.writeAsString(newContent, encoding: utf8);

      return ToolOutput(
        'File edited successfully',
        metadata: {'path': safePath},
      );
    },
  );
}
