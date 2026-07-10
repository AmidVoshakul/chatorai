import 'package:flutter/material.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';
import 'diff_line.dart';

class EditBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final bool isLoadingDiagnostics;
  final Map<int, List<LspDiagnostic>> diagnosticsByLine;
  final VoidCallback? onFetchDiagnostics;
  final void Function(LspDiagnostic) onDiagnosticTap;
  final String Function(String) previewOutput;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const EditBody({
    required this.theme,
    required this.part,
    required this.displayFull,
    required this.isError,
    required this.isLoadingDiagnostics,
    required this.diagnosticsByLine,
    this.onFetchDiagnostics,
    required this.onDiagnosticTap,
    required this.previewOutput,
    required this.buildResultFooter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final input = part.input ?? {};
    final filePath =
        input['filePath'] as String? ?? input['file_path'] as String? ?? '';
    final oldStr = input['old_string'] as String? ?? '';
    final newStr = input['new_string'] as String? ?? '';
    final result = part.result ?? '';

    final additions = newStr.split('\n').length;
    final deletions = oldStr.split('\n').length;

    final diffLines = computeDiff(oldStr, newStr).map((d) {
      final lineNumber = d.newLineNumber ?? d.oldLineNumber;
      final diags = lineNumber != null ? diagnosticsByLine[lineNumber] : null;
      return DiffLineData(
        oldLineNumber: d.oldLineNumber,
        newLineNumber: d.newLineNumber,
        text: d.text,
        type: d.type,
        diagnostics: diags,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 14, color: theme.colorScheme.muted),
              const SizedBox(width: 4),
              Text(
                'Edit $filePath',
                style: ChatoraiFontSizes.mono(
                  ChatoraiFontSizes.sm,
                  color: theme.colorScheme.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isLoadingDiagnostics) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (!displayFull)
            Text(
              '+$additions -$deletions',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (displayFull && (oldStr.isNotEmpty || newStr.isNotEmpty)) ...[
            ...diffLines.map(
              (d) => DiffLine(data: d, onDiagnosticTap: onDiagnosticTap),
            ),
          ],
          buildResultFooter(result, isError),
        ],
      ),
    );
  }
}
