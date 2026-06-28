import 'dart:convert';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';

import 'package:chatorai/core/tools/filesystem_boundary.dart';

ToolDef createWriteTool() {
  return ToolDef(
    id: 'write',
    description: 'Write content to a file',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description': 'Path to the file to write',
        },
        'content': {'type': 'string', 'description': 'Content to write'},
      },
      'required': ['file_path', 'content'],
    },
    execute: (input, ctx) async {
      final filePath =
          input['file_path'] as String? ?? input['path'] as String?;
      final content = input['content'] as String?;

      if (filePath == null) {
        return ToolOutput(
          'Error: file_path is required',
          metadata: {'error': true},
        );
      }
      if (content == null) {
        return ToolOutput(
          'Error: content is required',
          metadata: {'error': true},
        );
      }

      String safePath;
      try {
        safePath = resolveSafePath(filePath);
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
              'tool': 'write',
            },
          );
        }
      } catch (e) {
        return ToolOutput('Error: ${e.toString()}', metadata: {'error': true});
      }

      await ctx.ask(
        permission: 'write',
        patterns: ['write:file_path=$filePath'],
      );

      final file = File(safePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(utf8.encode(content));

      return ToolOutput(
        'File written successfully',
        metadata: {'path': safePath, 'bytes': content.length},
      );
    },
  );
}
