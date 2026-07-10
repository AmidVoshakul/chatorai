import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';

class GrepBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final String Function(String) previewOutput;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const GrepBody({
    required this.theme,
    required this.part,
    required this.displayFull,
    required this.isError,
    required this.previewOutput,
    required this.buildResultFooter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final originalResult = part.result ?? '';
    final displayedResult = displayFull
        ? originalResult
        : previewOutput(originalResult);
    final input = part.input ?? {};
    final pattern = input['pattern'] as String? ?? '';

    if (originalResult.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✱ $pattern',
            style: ChatoraiFontSizes.mono(
              ChatoraiFontSizes.sm,
              color: theme.colorScheme.muted,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: SelectableText(
              displayedResult,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.sm,
                color: theme.colorScheme.muted,
              ),
            ),
          ),
          buildResultFooter(displayedResult, isError),
        ],
      ),
    );
  }
}
