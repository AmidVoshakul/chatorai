import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/diff_body.dart';
import 'package:chatorai/shared/utils/logger.dart';

class EditBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final bool isLoadingDiagnostics;
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final void Function(LspDiagnostic) onDiagnosticTap;
  final String? sessionId;
  final VoidCallback? onRestore;
  final VoidCallback? onShowOriginal;

  const EditBody({
    super.key,
    required this.theme,
    required this.part,
    required this.displayFull,
    required this.isError,
    required this.isLoadingDiagnostics,
    required this.diagnosticsByLine,
    required this.onDiagnosticTap,
    this.sessionId,
    this.onRestore,
    this.onShowOriginal,
  });

  @override
  Widget build(BuildContext context) {
    var patch = '';
    if (part.result != null && part.result!.isNotEmpty) {
      try {
        final parsed = jsonDecode(part.result!) as Map<String, dynamic>;
        final p = parsed['patch'] as String?;
        if (p != null && p.isNotEmpty) {
          patch = p;
        }
      } catch (e) {
        if (kDebugMode) {
          LogTags.chatService.logWarning(
            '[EditBody] failed to parse tool result: $e',
          );
        }
      }
    }

    final input = part.input ?? {};
    final filePath =
        input['filePath'] as String? ?? input['file_path'] as String? ?? '';

    int? fileStartLine;
    if (patch.isEmpty) {
      fileStartLine = _findPosition(filePath, input['old_string'] as String?);
    }

    return DiffBody(
      theme: theme,
      patch: patch,
      oldSource: patch.isEmpty ? (input['old_string'] as String? ?? '') : null,
      newSource: patch.isEmpty ? (input['new_string'] as String? ?? '') : null,
      filePath: filePath,
      toolName: part.toolName,
      displayFull: displayFull,
      isError: isError,
      isLoadingDiagnostics: isLoadingDiagnostics,
      diagnosticsByLine: diagnosticsByLine,
      onDiagnosticTap: onDiagnosticTap,
      fileStartLine: fileStartLine,
      sessionId: sessionId,
      onRestore: onRestore,
      onShowOriginal: onShowOriginal,
    );
  }

  int? _findPosition(String filePath, String? oldString) {
    if (filePath.isEmpty || oldString == null || oldString.isEmpty) return null;
    final file = io.File(filePath);
    if (!file.existsSync()) return null;
    try {
      final content = file.readAsStringSync();
      final index = content.indexOf(oldString);
      if (index < 0) return null;
      final before = content.substring(0, index);
      return '\n'.allMatches(before).length + 1;
    } catch (_) {
      return null;
    }
  }
}
