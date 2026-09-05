import 'dart:convert';
import 'dart:io';

import 'package:dartdiff/dartdiff.dart';
import 'package:chatorai/core/tools/file_edit_guard.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/tool_path_resolve.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/tools/lsp_diagnostics_format.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/session/file_snapshot_service.dart';
import 'package:chatorai/shared/utils/logger.dart';

String _generatePatch(String oldText, String newText) {
  if (oldText == newText) return '';
  final patch = createTwoFilesPatch(
    '',
    '',
    oldText,
    newText,
    headerOptions: omitHeaders,
  );
  return patch?.trimRight() ?? '';
}

/// Try fallback matching strategies when the exact [oldString] is not found
/// in [content]. Returns the actual matched text, or null if no strategy works.
String? _fuzzyFindMatch(String content, String oldString) {
  if (oldString.isEmpty) return null;

  // 1. Line-trimmed: trim each line of oldString then find in trimmed content
  final trimmedOld = oldString.split('\n').map((l) => l.trim()).join('\n');
  if (trimmedOld != oldString) {
    final trimmedContent = content.split('\n').map((l) => l.trim()).join('\n');
    final trimmedIdx = trimmedContent.indexOf(trimmedOld);
    if (trimmedIdx >= 0) {
      // Map back: find the same range in the trimmed content, then map forward
      final before = trimmedContent.substring(0, trimmedIdx);
      final beforeLines = '\n'.allMatches(before).length;
      final contentLines = content.split('\n');
      final matchedLines = trimmedOld.split('\n').length;
      return contentLines.skip(beforeLines).take(matchedLines).join('\n');
    }
  }

  // 2. Whitespace-normalized: collapse all whitespace sequences to single space
  final wsPattern = RegExp(r'\s+');
  final normalizedOld = oldString.replaceAll(wsPattern, ' ');
  final normalizedContent = content.replaceAll(wsPattern, ' ');
  final wsIdx = normalizedContent.indexOf(normalizedOld);
  if (wsIdx >= 0 && normalizedOld != oldString.replaceAll('\n', ' ')) {
    final before = normalizedContent.substring(0, wsIdx);
    final charCount = before.length;
    // approximate: use character count in normalized space
    int actualStart = 0;
    int normalizedPos = 0;
    for (int i = 0; i < content.length && normalizedPos < charCount; i++) {
      if (wsPattern.hasMatch(content[i])) {
        normalizedPos++;
        while (i + 1 < content.length && wsPattern.hasMatch(content[i + 1])) {
          i++;
        }
      } else {
        normalizedPos++;
      }
      actualStart = i + 1;
    }
    final matchLen = normalizedOld.length;
    int actualEnd = actualStart;
    normalizedPos = 0;
    for (
      int i = actualStart;
      i < content.length && normalizedPos < matchLen;
      i++
    ) {
      if (wsPattern.hasMatch(content[i])) {
        normalizedPos++;
        while (i + 1 < content.length && wsPattern.hasMatch(content[i + 1])) {
          i++;
        }
      } else {
        normalizedPos++;
      }
      actualEnd = i + 1;
    }
    return content.substring(actualStart, actualEnd);
  }

  if (oldString.length <= 200) {
    try {
      final re = RegExp(RegExp.escape(oldString), multiLine: true);
      final match = re.firstMatch(content);
      if (match != null) {
        return match.group(0);
      }
    } catch (_) {}
  }

  return null;
}

ToolDef createEditTool({
  LspService? lspService,
  FileSnapshotService? fileSnapshotService,
  FormatService? formatService,
}) {
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

      final resolved = await resolveToolPath(
        ctx: ctx,
        userPath: filePath,
        toolName: 'edit',
      );
      if (resolved.isError) return resolved.error!;
      final safePath = resolved.path!;
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

      var content = '';
      try {
        content = await file.readAsString(encoding: utf8);
      } on FileSystemException catch (e) {
        return ToolOutput(
          'Error: cannot read $safePath (${e.message}). '
          'On Android 11+, direct file path access to shared storage is restricted. '
          'Use the app file picker or copy the file into the app folder, then edit it from there.',
          metadata: {'error': true, 'os_permission': true, 'path': safePath},
        );
      }
      String matchText = oldString;
      bool foundExact = content.contains(oldString);
      if (!foundExact) {
        final fuzzy = _fuzzyFindMatch(content, oldString);
        if (fuzzy != null) {
          matchText = fuzzy;
        } else {
          return ToolOutput(
            'Error: old_string not found in file',
            metadata: {'error': true},
          );
        }
      }

      final replaceAll = input['replace_all'] as bool? ?? true;
      final newContent = replaceAll
          ? content.replaceAll(matchText, newString)
          : content.replaceFirst(matchText, newString);
      final patch = _generatePatch(content, newContent);

      if (fileSnapshotService != null && ctx.sessionId != null) {
        await fileSnapshotService.capture(
          sessionId: ctx.sessionId!,
          filePath: safePath,
          content: content,
          stepId: ctx.toolCallId,
          toolName: 'edit',
        );
      }

      var cleanNewContent = newContent;
      if (cleanNewContent.isNotEmpty &&
          cleanNewContent.codeUnitAt(0) == 0xFEFF) {
        cleanNewContent = cleanNewContent.substring(1);
      }
      try {
        await file.writeAsString(cleanNewContent, encoding: utf8);
      } on FileSystemException catch (e) {
        return ToolOutput(
          'Error: cannot edit $safePath (${e.message}). '
          'On Android 11+, direct file path access to shared storage is restricted. '
          'Use the app file picker or copy the file into the app folder, then edit it from there.',
          metadata: {'error': true, 'os_permission': true, 'path': safePath},
        );
      }
      await FileEditGuard.recordRead(safePath);

      if (formatService != null) {
        try {
          await formatService.applyFix(safePath);
        } catch (e) {
          LogTags.format.logWarning('[edit] formatService.applyFix failed: $e');
        }
      }

      String lspOutput = '';
      if (lspService != null) {
        final diags = await lspService.diagnosticsForFile(safePath);
        lspOutput = '\n\n${formatLspDiagnostics(diags)}';
      }

      return ToolOutput(
        '${jsonEncode({'message': 'File edited successfully', 'patch': patch})}$lspOutput',
        metadata: {'path': safePath},
      );
    },
  );
}
