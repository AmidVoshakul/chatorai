import 'package:chatorai/features/chat/data/models/chat/tool_result_part.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class ShellBody extends StatefulWidget {
  final ThemeData theme;
  final ToolResultPart part;
  final bool displayFull;
  final bool isError;
  final bool standalone;
  final String Function(String) previewOutput;
  final VoidCallback? onToggle;

  const ShellBody({
    required this.theme,
    required this.part,
    required this.displayFull,
    required this.isError,
    required this.previewOutput,
    this.standalone = true,
    this.onToggle,
    super.key,
  });

  @override
  State<ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<ShellBody> {
  Offset? _tapDown;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final input = w.part.input ?? {};
    final cmd = input['command'] as String? ?? '';
    final originalResult = w.part.result ?? '';
    final displayedResult = w.displayFull
        ? originalResult
        : w.previewOutput(originalResult);
    final isDark = w.theme.brightness == Brightness.dark;
    final terminal = w.theme.colorScheme.dim;
    final muted = w.theme.colorScheme.muted;
    const pad = 12.0;
    final wasTruncated =
        originalResult.isNotEmpty &&
        w.previewOutput(originalResult) != originalResult;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cmd.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r'$ ',
                  style: ChatoraiFontSizes.mono(
                    ChatoraiFontSizes.md,
                    weight: FontWeight.w300,
                    color: w.isError ? w.theme.colorScheme.error : terminal,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cmd,
                    style: ChatoraiFontSizes.mono(
                      ChatoraiFontSizes.md,
                      weight: FontWeight.w300,
                      color: terminal,
                    ),
                    softWrap: true,
                  ),
                ),
                if (w.isError)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.error_outline,
                      size: 14,
                      color: w.theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        if (originalResult.isNotEmpty) const SizedBox(height: 6),
        if (originalResult.isNotEmpty)
          SingleChildScrollView(
            child: Text(
              displayedResult,
              style: ChatoraiFontSizes.mono(
                ChatoraiFontSizes.md,
                color: w.isError
                    ? (isDark ? Colors.red[200] : Colors.red[700])
                    : terminal,
              ),
            ),
          ),
        if (wasTruncated)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              w.displayFull ? 'Click to collapse' : 'Click to expand',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
      ],
    );

    final tappableBody = w.onToggle != null
        ? Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _tapDown = e.position,
            onPointerUp: (e) {
              if (_tapDown != null && (e.position - _tapDown!).distance < 10) {
                w.onToggle!();
              }
              _tapDown = null;
            },
            child: body,
          )
        : body;

    if (w.standalone) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: isDark ? Colors.black26 : Colors.white38,
        padding: const EdgeInsets.all(pad),
        child: tappableBody,
      );
    }

    return tappableBody;
  }
}
