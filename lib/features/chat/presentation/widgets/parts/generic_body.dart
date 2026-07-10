import 'package:flutter/material.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';

class GenericBody extends StatelessWidget {
  final ThemeData theme;
  final String displayedBody;
  final bool isError;
  final Widget Function(String displayedBody, bool isError) buildResultFooter;

  const GenericBody({
    required this.theme,
    required this.displayedBody,
    required this.isError,
    required this.buildResultFooter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (displayedBody.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: SelectableText(
            displayedBody,
            style: ChatoraiFontSizes.mono(
              ChatoraiFontSizes.sm,
              color: theme.colorScheme.muted,
            ),
          ),
        ),
        buildResultFooter(displayedBody, isError),
      ],
    );
  }
}

String truncateOutput(String text) {
  const int maxLines = 2000;
  const int maxChars = 51200;

  if (text.isEmpty) return text;

  final lines = text.split('\n');
  bool truncated = false;
  String result = text;

  if (lines.length > maxLines) {
    result = lines.take(maxLines).join('\n');
    truncated = true;
  }
  if (result.length > maxChars) {
    result = result.substring(0, maxChars);
    truncated = true;
  }

  if (truncated) {
    result += '\n[...truncated...]';
  }

  return result;
}
