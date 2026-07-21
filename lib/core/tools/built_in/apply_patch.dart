import 'dart:convert';
import 'dart:io';

import 'package:dartdiff/dartdiff.dart';
import 'package:chatorai/core/tools/file_edit_guard.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/shared/utils/path_sandbox.dart';

ToolDef createApplyPatchTool() {
  return ToolDef(
    id: 'apply_patch',
    description:
        'Apply a unified diff patch to a file. Safer than edit because it uses line numbers and context.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'file_path': {
          'type': 'string',
          'description': 'Path to the file to patch',
        },
        'patch': {'type': 'string', 'description': 'Unified diff patch'},
      },
      'required': ['file_path', 'patch'],
    },
    execute: (input, ctx) async {
      final rawPath = input['file_path'] as String? ?? input['path'] as String?;
      if (rawPath == null) {
        return ToolOutput(
          'Error: file_path is required',
          metadata: {'error': true},
        );
      }
      final safePath = resolveSafePath(rawPath);
      await ctx.ask(permission: 'edit', patterns: [safePath]);
      final patchStr = input['patch'] as String?;
      if (patchStr == null || patchStr.isEmpty) {
        return ToolOutput(
          'Error: patch is required',
          metadata: {'error': true},
        );
      }
      final file = File(safePath);
      if (!await file.exists()) {
        return ToolOutput(
          'Error: file not found: $safePath',
          metadata: {'error': true},
        );
      }
      final originalContent = await file.readAsString();
      try {
        final patches = parsePatch(patchStr);
        if (patches.isEmpty || patches.every((p) => p.hunks.isEmpty)) {
          return ToolOutput(
            'Error: no valid @@ header found in patch',
            metadata: {'error': true},
          );
        }
      } catch (_) {
        // fall through — let applyPatch do its own parsing
      }
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
        return ToolOutput(
          'Error: invalid patch — $e',
          metadata: {'error': true},
        );
      }
      if (result == originalContent) {
        return ToolOutput(
          'Patch applied with no changes (patch did not modify the file)',
          metadata: {'no_change': true},
        );
      }
      await file.writeAsString(result);
      await FileEditGuard.recordRead(safePath);
      return ToolOutput(
        jsonEncode({
          'message': 'Patch successfully applied to $safePath',
          'patch': patchStr,
        }),
        metadata: {
          'file_path': safePath,
        },
      );
    },
  );
}
