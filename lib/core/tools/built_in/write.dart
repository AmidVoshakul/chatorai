import 'dart:convert';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';

import 'package:chatorai/core/tools/filesystem_boundary.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/tools/file_edit_guard.dart';
import 'package:chatorai/core/tools/lsp_diagnostics_format.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/session/file_snapshot_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

ToolDef createWriteTool({
  LspService? lspService,
  FileSnapshotService? fileSnapshotService,
  FormatService? formatService,
}) {
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
        patterns: ['write:file_path=$safePath'],
      );

      final file = File(safePath);
      String? existingContent;
      try {
        existingContent = file.existsSync()
            ? await file.readAsString(encoding: utf8)
            : null;
      } on FileSystemException catch (e) {
        return ToolOutput(
          'Error: cannot read existing content for $safePath (${e.message}). '
          'On Android 11+, direct file path access to shared storage is restricted. '
          'Use the app file picker or copy the file into the app folder, then write to it from there.',
          metadata: {'error': true, 'os_permission': true, 'path': safePath},
        );
      }
      if (existingContent != null &&
          fileSnapshotService != null &&
          ctx.sessionId != null) {
        await fileSnapshotService.capture(
          sessionId: ctx.sessionId!,
          filePath: safePath,
          content: existingContent,
          stepId: ctx.toolCallId,
          toolName: 'write',
        );
      }

      await file.parent.create(recursive: true);
      var cleanContent = content;
      if (cleanContent.isNotEmpty && cleanContent.codeUnitAt(0) == 0xFEFF) {
        cleanContent = cleanContent.substring(1);
      }
      try {
        await file.writeAsBytes(utf8.encode(cleanContent));
      } on FileSystemException catch (e) {
        return ToolOutput(
          'Error: cannot write $safePath (${e.message}). '
          'On Android 11+, direct file path access to shared storage is restricted. '
          'Use the app file picker or copy the file into the app folder, then write to it from there.',
          metadata: {'error': true, 'os_permission': true, 'path': safePath},
        );
      }
      await FileEditGuard.recordRead(safePath);

      if (formatService != null) {
        try {
          await formatService.applyFix(safePath);
        } catch (e) {
          LogTags.format.logWarning(
            '[write] formatService.applyFix failed: $e',
          );
        }
      }

      String lspOutput = '';
      if (lspService != null) {
        final diags = await lspService.diagnosticsForFile(safePath);
        lspOutput = '\n\n${formatLspDiagnostics(diags)}';
      }

      return ToolOutput(
        'File written successfully$lspOutput',
        metadata: {'path': safePath, 'bytes': content.length},
      );
    },
  );
}
