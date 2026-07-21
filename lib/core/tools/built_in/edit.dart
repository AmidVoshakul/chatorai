import 'dart:convert';
import 'dart:io';

import 'package:dartdiff/dartdiff.dart';
import 'package:chatorai/core/tools/file_edit_guard.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';
import 'package:path/path.dart' as p;
import 'package:chatorai/core/tools/filesystem_boundary.dart';

String _generatePatch(String oldText, String newText) {
  if (oldText == newText) return '';
  final patch = createTwoFilesPatch('', '', oldText, newText,
      headerOptions: omitHeaders);
  return patch?.trimRight() ?? '';
}

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
      final boundary = FilesystemBoundary(workspace: Directory.current);
      final resolution = boundary.resolve(safePath);
      if (resolution.isExternal) {
        await ctx.ask(
          permission: 'external_directory',
          patterns: [resolution.path],
          always: [resolution.path],
          metadata: {
            'filepath': resolution.path,
            'parentDir': p.dirname(resolution.path),
            'tool': 'edit',
          },
        );
      }
      await ctx.ask(permission: 'edit', patterns: ['edit:file_path=$safePath']);

      final staleMtime = await FileEditGuard.checkStale(safePath);
      if (staleMtime != null) {
        return ToolOutput(
          'Error: file was modified since last read '
          '(mtime changed from cached value). '
          'Please re-read the file before editing.',
          metadata: {'error': true, 'stale': true},
        );
      }
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
      final patch = _generatePatch(content, newContent);
      await file.writeAsString(newContent, encoding: utf8);

      return ToolOutput(
        jsonEncode({
          'message': 'File edited successfully',
          'patch': patch,
        }),
        metadata: {'path': safePath},
      );
    },
  );
}
