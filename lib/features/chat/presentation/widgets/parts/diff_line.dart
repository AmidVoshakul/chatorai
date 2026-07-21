import 'package:flutter/material.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';

enum DiffLineType { context, addition, removal }

class DiffLineData {
  final int? oldLineNumber;
  final int? newLineNumber;
  final String text;
  final DiffLineType type;
  final List<LspDiagnostic>? diagnostics;

  const DiffLineData({
    this.oldLineNumber,
    this.newLineNumber,
    required this.text,
    required this.type,
    this.diagnostics,
  });
}

List<DiffLineData> computeDiff(String oldText, String newText) {
  final oldLines = oldText.split('\n');
  final newLines = newText.split('\n');

  if (oldLines.isEmpty && newLines.isEmpty) {
    return const [];
  }

  int prefixLen = 0;
  while (prefixLen < oldLines.length && prefixLen < newLines.length) {
    if (oldLines[prefixLen] == newLines[prefixLen]) {
      prefixLen++;
    } else {
      break;
    }
  }

  int suffixLen = 0;
  while (suffixLen < (oldLines.length - prefixLen) &&
      suffixLen < (newLines.length - prefixLen)) {
    final oldIdx = oldLines.length - 1 - suffixLen;
    final newIdx = newLines.length - 1 - suffixLen;
    if (oldLines[oldIdx] == newLines[newIdx]) {
      suffixLen++;
    } else {
      break;
    }
  }

  final result = <DiffLineData>[];

  for (var i = 0; i < prefixLen; i++) {
    result.add(
      DiffLineData(
        oldLineNumber: i + 1,
        newLineNumber: i + 1,
        text: oldLines[i],
        type: DiffLineType.context,
      ),
    );
  }

  for (var i = prefixLen; i < oldLines.length - suffixLen; i++) {
    result.add(
      DiffLineData(
        oldLineNumber: i + 1,
        newLineNumber: null,
        text: oldLines[i],
        type: DiffLineType.removal,
      ),
    );
  }

  for (var i = prefixLen; i < newLines.length - suffixLen; i++) {
    result.add(
      DiffLineData(
        oldLineNumber: null,
        newLineNumber: i + 1,
        text: newLines[i],
        type: DiffLineType.addition,
      ),
    );
  }

  for (var i = 0; i < suffixLen; i++) {
    final oldIdx = oldLines.length - suffixLen + i;
    final newIdx = newLines.length - suffixLen + i;
    result.add(
      DiffLineData(
        oldLineNumber: oldIdx + 1,
        newLineNumber: newIdx + 1,
        text: newLines[newIdx],
        type: DiffLineType.context,
      ),
    );
  }

  return result;
}

class DiffLine extends StatelessWidget {
  final DiffLineData data;
  final void Function(LspDiagnostic)? onDiagnosticTap;

  const DiffLine({required this.data, this.onDiagnosticTap, super.key});

  Color _severityColor(int severity, ThemeData theme) {
    switch (severity) {
      case 1:
        return theme.colorScheme.error;
      case 2:
        return theme.colorScheme.tertiary;
      case 3:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final prefix = switch (data.type) {
      DiffLineType.addition => '+',
      DiffLineType.removal => '-',
      DiffLineType.context => ' ',
    };

    final lineColor = switch (data.type) {
      DiffLineType.addition => const Color(0xFF22C55E),
      DiffLineType.removal => const Color(0xFFEF4444),
      DiffLineType.context => theme.colorScheme.onSurface.withValues(
        alpha: 0.4,
      ),
    };

    final lineNumber = data.newLineNumber ?? data.oldLineNumber;
    final diagnostics = data.diagnostics;
    final hasDiagnostics = diagnostics != null && diagnostics.isNotEmpty;

    final diagnosticBadges = hasDiagnostics
        ? diagnostics.map((d) {
            final color = _severityColor(d.severity, theme);
            final icon = d.severity == 1
                ? Icons.error
                : d.severity == 2
                ? Icons.warning
                : Icons.info;
            return GestureDetector(
              onTap: () => onDiagnosticTap?.call(d),
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Icon(icon, size: 10, color: color),
              ),
            );
          }).toList()
        : null;

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              data.type == DiffLineType.context &&
                      data.oldLineNumber != data.newLineNumber
                  ? '${data.oldLineNumber}-${data.newLineNumber}'
                  : '$lineNumber',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: ChatoraiFontSizes.monospaceFont,
                fontSize: ChatoraiFontSizes.sm,
                color:
                    hasDiagnostics == true &&
                        diagnostics!.any((d) => d.severity == 1)
                    ? theme.colorScheme.error
                    : lineColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            prefix,
            style: TextStyle(
              fontFamily: ChatoraiFontSizes.monospaceFont,
              fontSize: ChatoraiFontSizes.sm,
              color: lineColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              data.text,
              style: TextStyle(
                fontFamily: ChatoraiFontSizes.monospaceFont,
                fontSize: ChatoraiFontSizes.sm,
                color:
                    hasDiagnostics == true &&
                        diagnostics!.any((d) => d.severity == 1)
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (diagnosticBadges != null) ...[
            const SizedBox(width: 2),
            ...diagnosticBadges,
          ],
        ],
      ),
    );
  }
}
