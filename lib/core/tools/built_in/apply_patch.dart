import 'dart:io';

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
      final originalLines = await file.readAsLines();
      final patchLines = patchStr.split(RegExp(r'\r?\n'));
      final headerRegex = RegExp(r'^@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@');
      int? oldStart;
      int oldCount = 1;
      int? newStart;
      int newCount = 1;
      int headerIndex = -1;
      for (var i = 0; i < patchLines.length; i++) {
        final match = headerRegex.firstMatch(patchLines[i]);
        if (match != null) {
          oldStart = int.parse(match.group(1)!) - 1;
          oldCount = match.group(2)!.isEmpty ? 1 : int.parse(match.group(2)!);
          newStart = int.parse(match.group(3)!) - 1;
          newCount = match.group(4)!.isEmpty ? 1 : int.parse(match.group(4)!);
          headerIndex = i;
          break;
        }
      }
      if (oldStart == null || newStart == null || headerIndex == -1) {
        return ToolOutput(
          'Error: no valid @@ header found in patch',
          metadata: {'error': true},
        );
      }
      final hunkLines = patchLines.sublist(headerIndex + 1);
      int currentFileIdx = oldStart;
      for (final line in hunkLines) {
        if (line.startsWith('---') ||
            line.startsWith('+++') ||
            line.startsWith('@@')) {
          break;
        }
        if (line.startsWith(' ') || line.startsWith('-')) {
          final expectedLine = line.isNotEmpty ? line.substring(1) : '';
          if (currentFileIdx < 0 || currentFileIdx >= originalLines.length) {
            return ToolOutput(
              'Error: patch index out of bounds. File has ${originalLines.length} lines, trying to access index $currentFileIdx.',
              metadata: {'error': true, 'bounds_error': true},
            );
          }
          if (originalLines[currentFileIdx] != expectedLine) {
            return ToolOutput(
              'Error: context mismatch at line ${currentFileIdx + 1}.\nExpected: "$expectedLine"\nActual: "${originalLines[currentFileIdx]}"',
              metadata: {'error': true, 'context_mismatch': true},
            );
          }
          currentFileIdx++;
        }
      }
      final result = <String>[];
      for (var i = 0; i < oldStart; i++) {
        result.add(originalLines[i]);
      }
      int inserted = 0;
      for (final line in hunkLines) {
        if (line.startsWith('---') ||
            line.startsWith('+++') ||
            line.startsWith('@@')) {
          break;
        }
        if (line.startsWith('-') || line.startsWith('\\')) {
          continue;
        }
        if (line.startsWith('+')) {
          result.add(line.substring(1));
          inserted++;
        } else if (line.startsWith(' ')) {
          result.add(line.substring(1));
          inserted++;
        } else if (line.isEmpty) {
          result.add('');
          inserted++;
        }
      }
      for (var i = oldStart + oldCount; i < originalLines.length; i++) {
        if (i >= 0 && i < originalLines.length) {
          result.add(originalLines[i]);
        }
      }
      await file.writeAsString(result.join('\n'));
      final expectedTotalLines = originalLines.length - oldCount + newCount;
      if (result.length != expectedTotalLines) {
        return ToolOutput(
          'Patch applied with line count warning: expected total $expectedTotalLines, got ${result.length}',
          metadata: {
            'warning': true,
            'old_count': oldCount,
            'new_count': newCount,
            'actual_new_count': inserted,
            'total_lines': result.length,
          },
        );
      }
      return ToolOutput(
        'Patch successfully applied to $safePath ($oldCount lines replaced with $inserted lines)',
        metadata: {
          'file_path': safePath,
          'old_count': oldCount,
          'new_count': inserted,
          'total_lines': result.length,
        },
      );
    },
  );
}
