import 'package:chatorai/core/chat/chat/tool_result_part.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/gui/shared/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ReadBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final String Function(String) previewOutput;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const ReadBody({
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
    final input = part.input ?? {};
    final offset = input['offset'];
    final limit = input['limit'];
    final originalResult = part.result ?? '';
    final displayedResult = displayFull
        ? originalResult
        : previewOutput(originalResult);

    if (originalResult.isEmpty) return const SizedBox.shrink();

    String subtitle = '';
    if (offset != null || limit != null) {
      final parts = <String>[];
      if (offset != null) parts.add('offset=$offset');
      if (limit != null) parts.add('limit=$limit');
      subtitle = '[${parts.join(', ')}]';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.sm,
                color: theme.colorScheme.muted,
              ),
            ),
          if (originalResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                displayedResult,
                style: ChatoraiFontSizes.mono(
                  ChatoraiFontSizes.sm,
                  color: theme.colorScheme.muted,
                ),
              ),
            ),
          if (originalResult.isNotEmpty)
            buildResultFooter(displayedResult, isError),
        ],
      ),
    );
  }
}
