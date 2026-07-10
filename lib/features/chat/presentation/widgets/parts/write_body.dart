import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';

class WriteBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const WriteBody({
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
    final content = input['content'] as String? ?? '';
    final result = part.result ?? '';

    final lines = content.split('\n');
    final previewLines = displayFull ? lines : lines.take(20).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write $filePath',
            style: ChatoraiFontSizes.mono(
              ChatoraiFontSizes.sm,
              color: theme.colorScheme.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          if (previewLines.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
              ),
              child: SelectableText(
                previewLines.join('\n'),
                style: ChatoraiFontSizes.mono(
                  ChatoraiFontSizes.xs,
                  color: theme.colorScheme.muted,
                ),
                maxLines: displayFull ? null : 20,
              ),
            ),
          buildResultFooter(result, isError),
        ],
      ),
    );
  }
}
