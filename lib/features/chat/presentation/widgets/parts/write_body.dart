import 'package:flutter/material.dart';
import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_icon.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';

// ===========================================================================
// WriteBody — public widget
// ===========================================================================

class WriteBody extends StatelessWidget {
  final ThemeData theme;
  final ToolResultPart part;

  const WriteBody({required this.theme, required this.part, super.key});

  @override
  Widget build(BuildContext context) {
    if (part.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                part.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.error,
                  fontSize: ChatoraiFontSizes.sm,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final input = part.input ?? {};
    final content = input['content'] as String? ?? '';
    final path =
        input['path'] as String? ??
        input['filePath'] as String? ??
        input['file_path'] as String? ??
        '';
    final lines = content.split('\n');

    final iconData = toolIcon(part.toolName);
    final title = 'Write ${path.replaceAll('/', '/\u200B')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(color: diffBgColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, iconData, title),
          if (lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _WriteContent(lines: lines),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, IconData iconData, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(iconData, size: 14, color: theme.colorScheme.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.muted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// _WriteContent — line-numbered content body
// ===========================================================================

class _WriteContent extends StatelessWidget {
  final List<String> lines;

  const _WriteContent({required this.lines});

  @override
  Widget build(BuildContext context) {
    final maxDigits = lines.length.toString().length;
    final gutterWidth = maxDigits * 8.0 + 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++)
          _WriteLine(
            lineNumber: i + 1,
            text: lines[i],
            gutterWidth: gutterWidth,
          ),
      ],
    );
  }
}

// ===========================================================================
// _WriteLine — single content row with line number
// ===========================================================================

class _WriteLine extends StatelessWidget {
  final int lineNumber;
  final String text;
  final double gutterWidth;

  const _WriteLine({
    required this.lineNumber,
    required this.text,
    required this.gutterWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: gutterWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: Text(
              lineNumber.toString(),
              textAlign: TextAlign.right,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.sm,
                color: cs.muted,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            child: Text(
              text,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.md,
                color: cs.dim,
              ),
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }
}
