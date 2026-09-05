import 'dart:convert';
import 'dart:io';

import 'package:dartdiff/dartdiff.dart';
import 'package:chatorai/core/tools/file_edit_guard.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/tools/lsp_diagnostics_format.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/session/file_snapshot_service.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/core/tools/built_in/tool_path_resolve.dart';

enum PatchOpType { add, update, delete }

class PatchOperation {
  final PatchOpType type;
  final String path;
  String? moveTo;
  final String? patchContent;

  PatchOperation({
    required this.type,
    required this.path,
    this.moveTo,
    this.patchContent,
  });
}

List<PatchOperation> _parseEnvelope(String patchStr) {
  final lines = patchStr.split('\n');
  if (lines.isEmpty || lines.first.trim() != '*** Begin Patch') {
    return [];
  }

  final ops = <PatchOperation>[];
  final endIdx = lines.indexWhere((l) => l.trim() == '*** End Patch');
  if (endIdx < 0) return [];

  final contentLines = lines.sublist(1, endIdx);
  int i = 0;
  while (i < contentLines.length) {
    final line = contentLines[i].trim();
    i++;

    PatchOpType? type;
    String? path;
    if (line.startsWith('*** Add File: ')) {
      type = PatchOpType.add;
      path = line.substring('*** Add File: '.length).trim();
    } else if (line.startsWith('*** Delete File: ')) {
      type = PatchOpType.delete;
      path = line.substring('*** Delete File: '.length).trim();
      ops.add(PatchOperation(type: type, path: path));
      continue;
    } else if (line.startsWith('*** Update File: ')) {
      type = PatchOpType.update;
      path = line.substring('*** Update File: '.length).trim();
    } else if (line.startsWith('*** Move to: ')) {
      if (ops.isNotEmpty && ops.last.type == PatchOpType.update) {
        ops.last.moveTo = line.substring('*** Move to: '.length).trim();
      }
      continue;
    } else if (line.startsWith('*** ')) {
      return [];
    } else {
      continue;
    }

    if (path.isEmpty) continue;

    if (type == PatchOpType.add) {
      final addLines = <String>[];
      while (i < contentLines.length) {
        final cl = contentLines[i];
        if (cl.startsWith('*** ')) break;
        if (cl.startsWith('+')) {
          addLines.add(cl.substring(1));
        } else if (cl.isEmpty) {
          addLines.add('');
        }
        i++;
      }
      ops.add(
        PatchOperation(
          type: type,
          path: path,
          patchContent: addLines.join('\n'),
        ),
      );
    } else if (type == PatchOpType.update) {
      final patchLines = <String>[];
      String? moveToLine;
      while (i < contentLines.length) {
        final cl = contentLines[i];
        if (cl.startsWith('*** Move to: ')) {
          moveToLine = cl.substring('*** Move to: '.length).trim();
          i++;
          continue;
        }
        if (cl.startsWith('*** ')) break;
        patchLines.add(contentLines[i]);
        i++;
      }
      final finalMoveTo = moveToLine;
      ops.add(
        PatchOperation(
          type: type,
          path: path,
          patchContent: patchLines.join('\n'),
          moveTo: finalMoveTo,
        ),
      );
    }
  }

  return ops;
}

String _formatResults(List<Map<String, dynamic>> fileResults) {
  final parts = <String>[];
  for (final fr in fileResults) {
    final path = fr['path'] as String? ?? '';
    final status = fr['status'] as String? ?? '';
    final error = fr['error'] as String?;
    if (error != null) {
      parts.add('- $path: $error');
    } else if (status == 'added') {
      parts.add('- $path: file created');
    } else if (status == 'deleted') {
      parts.add('- $path: file deleted');
    } else if (status == 'updated') {
      parts.add('- $path: patch applied');
    } else if (status == 'moved') {
      final to = fr['moved_to'] as String? ?? '';
      parts.add('- $path: moved to $to');
    }
  }
  return parts.join('\n');
}

class _AppliedChange {
  final String path;
  final String? originalContent;
  final bool wasFile;
  final String? moveFrom;
  _AppliedChange(
    this.path,
    this.originalContent,
    this.wasFile, {
    this.moveFrom,
  });
}

ToolDef createApplyPatchTool({
  LspService? lspService,
  FileSnapshotService? fileSnapshotService,
  FormatService? formatService,
}) {
  return ToolDef(
    id: 'apply_patch',
    description:
        'Apply a unified diff patch to a file. Safer than edit because it uses line numbers and context. Supports multi-file patches via *** Begin Patch / *** End Patch envelope.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description':
              'Path to the file to patch (required for single-file patches)',
        },
        'patch': {
          'type': 'string',
          'description':
              'Unified diff patch. For multi-file patches, wrap in *** Begin Patch / *** End Patch envelope with *** Add File:, *** Update File:, *** Delete File: markers.',
        },
      },
      'required': ['patch'],
    },
    execute: (input, ctx) async {
      final patchStr = input['patch'] as String?;
      if (patchStr == null || patchStr.isEmpty) {
        return ToolOutput(
          'Error: patch is required',
          metadata: {'error': true},
        );
      }

      if (patchStr.trimLeft().startsWith('*** Begin Patch')) {
        return _executeEnvelope(
          patchStr,
          ctx,
          lspService,
          fileSnapshotService,
          formatService,
        );
      }

      return _executeSingleFile(
        input,
        patchStr,
        ctx,
        lspService,
        fileSnapshotService,
        formatService,
      );
    },
  );
}

Future<ToolOutput> _executeEnvelope(
  String patchStr,
  ToolContext ctx,
  LspService? lspService,
  FileSnapshotService? fileSnapshotService,
  FormatService? formatService,
) async {
  final lines = patchStr.split('\n');
  final endIdx = lines.indexWhere((l) => l.trim() == '*** End Patch');
  if (endIdx < 0) {
    return ToolOutput(
      'Error: missing *** End Patch marker in patch envelope',
      metadata: {'error': true},
    );
  }

  final ops = _parseEnvelope(patchStr);
  if (ops.isEmpty) {
    String detail;
    final unknownLine = lines
        .where((l) => l.startsWith('*** '))
        .firstWhere(
          (l) =>
              !l.startsWith('*** Begin Patch') &&
              !l.startsWith('*** End Patch') &&
              !l.startsWith('*** Add File:') &&
              !l.startsWith('*** Delete File:') &&
              !l.startsWith('*** Update File:') &&
              !l.startsWith('*** Move to:'),
          orElse: () => '',
        );
    if (unknownLine.isNotEmpty) {
      detail = 'Unknown operation: "$unknownLine"';
    } else {
      detail = 'no valid operations found in patch envelope';
    }
    return ToolOutput('Error: $detail', metadata: {'error': true});
  }

  final applied = <_AppliedChange>[];
  final fileResults = <Map<String, dynamic>>[];

  try {
    for (final op in ops) {
      final resolved = await resolveToolPath(
        ctx: ctx,
        userPath: op.path,
        toolName: 'apply_patch',
      );
      if (resolved.isError) return resolved.error!;
      final safePath = resolved.path!;
      await ctx.ask(permission: 'edit', patterns: [safePath]);

      switch (op.type) {
        case PatchOpType.add:
          _applyAdd(op, safePath, applied, fileResults);
        case PatchOpType.delete:
          await _applyDelete(
            op,
            safePath,
            applied,
            fileResults,
            fileSnapshotService,
            ctx,
          );
        case PatchOpType.update:
          await _applyUpdate(
            op,
            safePath,
            applied,
            fileResults,
            fileSnapshotService,
            ctx,
          );
      }
    }
  } catch (e) {
    await _rollback(applied);
    return ToolOutput(
      'Error: patch partially failed — rolled back all changes. '
      '${_formatResults(fileResults)}\n\nCaused by: $e',
      metadata: {'error': true, 'rolled_back': true},
    );
  }

  if (formatService != null) {
    for (final fr in fileResults) {
      final frPath = fr['path'] as String?;
      if (frPath == null) continue;
      if (fr['status'] == 'deleted') continue;
      try {
        await formatService.applyFix(frPath);
      } catch (e) {
        LogTags.format.logWarning(
          '[apply_patch] formatService.applyFix failed for $frPath: $e',
        );
      }
    }
  }

  String lspLines = '';
  if (lspService != null) {
    final allDiags = <String>[];
    for (final fr in fileResults) {
      final frPath = fr['path'] as String?;
      if (frPath == null) continue;
      final frStatus = fr['status'] as String?;
      if (frStatus == 'deleted') continue;
      try {
        final diags = await lspService.diagnosticsForFile(frPath);
        allDiags.add(formatLspDiagnostics(diags));
      } catch (_) {}
    }
    if (allDiags.isNotEmpty) {
      lspLines = '\n\n${allDiags.join('\n')}';
    }
  }

  final fileCount = fileResults.length;
  final resultMsg = fileCount == 1
      ? 'Patch successfully applied to 1 file\n${_formatResults(fileResults)}'
      : 'Patch successfully applied to $fileCount files\n${_formatResults(fileResults)}';

  return ToolOutput(
    jsonEncode({'message': resultMsg, 'patch': patchStr}) + lspLines,
    metadata: {'file_count': fileResults.length},
  );
}

Future<ToolOutput> _executeSingleFile(
  Map<String, dynamic> input,
  String patchStr,
  ToolContext ctx,
  LspService? lspService,
  FileSnapshotService? fileSnapshotService,
  FormatService? formatService,
) async {
  final rawPath = input['file_path'] as String? ?? input['path'] as String?;
  if (rawPath == null) {
    return ToolOutput(
      'Error: file_path is required',
      metadata: {'error': true},
    );
  }
  final resolved = await resolveToolPath(
    ctx: ctx,
    userPath: rawPath,
    toolName: 'apply_patch',
  );
  if (resolved.isError) return resolved.error!;
  final safePath = resolved.path!;
  await ctx.ask(permission: 'edit', patterns: [safePath]);

  final file = File(safePath);
  if (!await file.exists()) {
    return ToolOutput(
      'Error: file not found: $safePath',
      metadata: {'error': true},
    );
  }
  final originalContent = await file.readAsString();

  if (fileSnapshotService != null && ctx.sessionId != null) {
    await fileSnapshotService.capture(
      sessionId: ctx.sessionId!,
      filePath: safePath,
      content: originalContent,
      stepId: ctx.toolCallId,
      toolName: 'apply_patch',
    );
  }

  try {
    final patches = parsePatch(patchStr);
    if (patches.isEmpty || patches.every((p) => p.hunks.isEmpty)) {
      return ToolOutput(
        'Error: no valid @@ header found in patch',
        metadata: {'error': true},
      );
    }
  } catch (_) {}

  final String result;
  try {
    final r = applyPatch(originalContent, patchStr);
    if (r == null) {
      return ToolOutput(
        'Error: patch context mismatch — could not apply patch to the current file content',
        metadata: {'error': true},
      );
    }
    result = r;
  } catch (e) {
    return ToolOutput('Error: invalid patch — $e', metadata: {'error': true});
  }
  if (result == originalContent) {
    return ToolOutput(
      'Patch applied with no changes (patch did not modify the file)',
      metadata: {'no_change': true},
    );
  }
  await file.writeAsString(result, encoding: utf8);
  await FileEditGuard.recordRead(safePath);

  if (formatService != null) {
    try {
      await formatService.applyFix(safePath);
    } catch (e) {
      LogTags.format.logWarning(
        '[apply_patch] formatService.applyFix failed: $e',
      );
    }
  }

  String lspOutput = '';
  if (lspService != null) {
    final diags = await lspService.diagnosticsForFile(safePath);
    lspOutput = '\n\n${formatLspDiagnostics(diags)}';
  }

  return ToolOutput(
    jsonEncode({
          'message': 'Patch successfully applied to $safePath',
          'patch': patchStr,
        }) +
        lspOutput,
    metadata: {'file_path': safePath},
  );
}

void _applyAdd(
  PatchOperation op,
  String safePath,
  List<_AppliedChange> applied,
  List<Map<String, dynamic>> fileResults,
) {
  final file = File(safePath);
  if (file.existsSync()) {
    throw Exception('File already exists: ${op.path}');
  }
  file.createSync(recursive: true);
  final content = op.patchContent ?? '';
  if (content.isNotEmpty) {
    file.writeAsStringSync(content, encoding: utf8);
  }
  applied.add(_AppliedChange(safePath, null, false));
  fileResults.add({'path': op.path, 'status': 'added'});
}

Future<void> _applyDelete(
  PatchOperation op,
  String safePath,
  List<_AppliedChange> applied,
  List<Map<String, dynamic>> fileResults,
  FileSnapshotService? fileSnapshotService,
  ToolContext ctx,
) async {
  final file = File(safePath);
  if (!await file.exists()) {
    throw Exception('File not found: ${op.path}');
  }
  final originalContent = await file.readAsString();
  if (fileSnapshotService != null && ctx.sessionId != null) {
    await fileSnapshotService.capture(
      sessionId: ctx.sessionId!,
      filePath: safePath,
      content: originalContent,
      stepId: ctx.toolCallId,
      toolName: 'apply_patch',
    );
  }
  await file.delete();
  applied.add(_AppliedChange(safePath, originalContent, true));
  fileResults.add({'path': op.path, 'status': 'deleted'});
}

Future<void> _applyUpdate(
  PatchOperation op,
  String safePath,
  List<_AppliedChange> applied,
  List<Map<String, dynamic>> fileResults,
  FileSnapshotService? fileSnapshotService,
  ToolContext ctx,
) async {
  final patchContent = op.patchContent;
  if (patchContent == null || patchContent.isEmpty) {
    throw Exception('Empty patch for update: ${op.path}');
  }

  final file = File(safePath);
  if (!await file.exists()) {
    throw Exception('File not found: ${op.path}');
  }
  final originalContent = await file.readAsString();

  if (fileSnapshotService != null && ctx.sessionId != null) {
    await fileSnapshotService.capture(
      sessionId: ctx.sessionId!,
      filePath: safePath,
      content: originalContent,
      stepId: ctx.toolCallId,
      toolName: 'apply_patch',
    );
  }

  final String result;
  try {
    final r = applyPatch(originalContent, patchContent);
    if (r == null) {
      throw Exception(
        'patch context mismatch — could not apply patch to the current file content',
      );
    }
    result = r;
  } catch (e) {
    if (e is Exception) rethrow;
    throw Exception('invalid patch — $e');
  }

  if (op.moveTo != null) {
    final destResolved = await resolveToolPath(
      ctx: ctx,
      userPath: op.moveTo!,
      toolName: 'apply_patch',
    );
    if (destResolved.isError) throw Exception(destResolved.error!.output);
    final destPath = destResolved.path!;
    await ctx.ask(permission: 'edit', patterns: [destPath]);
    if (destPath == safePath) {
      await file.writeAsString(result, encoding: utf8);
      applied.add(_AppliedChange(safePath, originalContent, true));
      fileResults.add({'path': op.path, 'status': 'updated'});
    } else {
      final destFile = File(destPath);
      if (destFile.existsSync()) {
        throw Exception('Destination already exists: ${op.moveTo}');
      }
      await destFile.parent.create(recursive: true);
      await destFile.writeAsString(result, encoding: utf8);
      await file.delete();
      applied.add(
        _AppliedChange(destPath, originalContent, true, moveFrom: safePath),
      );
      fileResults.add({
        'path': op.path,
        'status': 'moved',
        'moved_to': op.moveTo,
      });
    }
  } else {
    await file.writeAsString(result, encoding: utf8);
    applied.add(_AppliedChange(safePath, originalContent, true));
    fileResults.add({'path': op.path, 'status': 'updated'});
  }

  await FileEditGuard.recordRead(safePath);
}

Future<void> _rollback(List<_AppliedChange> applied) async {
  final errors = <String, Exception>{};
  for (final change in applied.reversed) {
    try {
      if (change.moveFrom != null) {
        await File(change.moveFrom!).parent.create(recursive: true);
        await File(
          change.moveFrom!,
        ).writeAsString(change.originalContent ?? '');
        await File(change.path).delete();
      } else if (change.originalContent != null) {
        await File(change.path).writeAsString(change.originalContent!);
      } else if (!change.wasFile) {
        await File(change.path).delete();
      }
    } on Exception catch (e) {
      errors[change.path] = e;
    }
  }
  if (errors.isNotEmpty) {
    throw StateError(
      'Rollback incomplete: ${errors.length} file(s) failed: $errors',
    );
  }
}
