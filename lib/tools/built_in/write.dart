import 'dart:io';
import '../tool.dart';
import 'path_sandbox.dart';

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

      if (filePath == null) throw ArgumentError('file_path is required');
      if (content == null) throw ArgumentError('content is required');

      final safePath = resolveSafePath(filePath);
      await ctx.ask(permission: 'write', patterns: [safePath]);

      final file = File(safePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);

      return ToolOutput(
        'File written successfully',
        metadata: {'path': safePath, 'bytes': content.length},
      );
    },
  );
}
