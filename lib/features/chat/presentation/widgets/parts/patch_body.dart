import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';
import 'diff_line.dart';

class PatchBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const PatchBody({
    required this.theme,
    required this.part,
    required this.displayFull,
    required this.isError,
    required this.buildResultFooter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final input = part.input ?? {};
    final filePath = input['file_path'] as String? ?? '';
    final patchStr = input['patch'] as String? ?? '';
    final result = part.result ?? '';

    final patchLines = patchStr.split('\n');
    final previewLines = displayFull
        ? patchLines
        : patchLines.take(40).toList();

    final diffLines = <DiffLineData>[];
    for (final line in previewLines) {
      if (line.startsWith('+') && !line.startsWith('+++')) {
        diffLines.add(DiffLineData(text: line, type: DiffLineType.addition));
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        diffLines.add(DiffLineData(text: line, type: DiffLineType.removal));
      } else {
        diffLines.add(DiffLineData(text: line, type: DiffLineType.context));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patch $filePath',
            style: ChatoraiFontSizes.mono(
              ChatoraiFontSizes.sm,
              color: theme.colorScheme.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          if (diffLines.isNotEmpty) ...diffLines.map((d) => DiffLine(data: d)),
          buildResultFooter(result, isError),
        ],
      ),
    );
  }
}
