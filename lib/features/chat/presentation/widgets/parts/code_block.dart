import 'dart:async';

import 'package:chatorai/l10n/app_localizations.dart';
// import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/message_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class CodeBlock extends StatefulWidget {
  final String code;
  final String language;

  const CodeBlock({super.key, required this.code, required this.language});

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

// ===========================================================================
// STATE CLASS
// ===========================================================================

class _CodeBlockState extends State<CodeBlock> {
  bool _isCollapsed = false;
  bool _showCopied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _onCopy() {
    MessageUtils.copyMessage(content: widget.code, context: context);
    setState(() => _showCopied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCopied = false);
    });
  }

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final headerColor = isDark
        ? ChatoraiColors.white70
        : ChatoraiColors.pureBlack;
    final codeBgColor = isDark
        ? ChatoraiColors.codeBackgroundDark
        : ChatoraiColors.codeBackgroundLight;
    final headerBgColor = isDark
        ? ChatoraiColors.darkGray
        : ChatoraiColors.lightGray;
    final codeHighlightColor = isDark
        ? ChatoraiColors.codeHighlightDark
        : ChatoraiColors.codeBackgroundLight;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: ChatoraiSpacing.sm),
      decoration: BoxDecoration(
        color: codeBgColor,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.8),
          width: ChatoraiBorderWidth.thinBold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChatoraiSpacing.sm,
                vertical: ChatoraiSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ChatoraiBorderRadius.sm),
                  bottom: _isCollapsed
                      ? Radius.circular(ChatoraiBorderRadius.sm)
                      : Radius.zero,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCollapsed ? Icons.chevron_right : Icons.expand_more,
                        color: headerColor,
                        size: ChatoraiIconSizes.lg,
                      ),
                      const SizedBox(width: ChatoraiSpacing.xs),
                      Text(
                        widget.language.toUpperCase(),
                        style: TextStyle(
                          color: headerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: ChatoraiFontSizes.md,
                        ),
                      ),
                    ],
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: _showCopied
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ChatoraiSpacing.xs,
                            ),
                            child: Text(
                              localizations.copiedFeedback,
                              style: TextStyle(
                                color: const Color(0xFF418A44),
                                fontSize: ChatoraiFontSizes.sm,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.copy_all,
                              color: headerColor,
                              size: ChatoraiIconSizes.lg,
                            ),
                            onPressed: _onCopy,
                            tooltip: localizations.copyCodeTooltip,
                            splashRadius: ChatoraiIconSizes.md,
                            hoverColor: isDark
                                ? ChatoraiColors.black10
                                : ChatoraiColors.black12,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: ChatoraiSpacing.lg,
                              minHeight: ChatoraiSpacing.lg,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (!_isCollapsed)
            Container(
              color: codeHighlightColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(ChatoraiSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _SelectableHighlightView(
                            widget.code,
                            language: widget.language.toLowerCase(),
                            theme: isDark ? vs2015Theme : githubTheme,
                            textStyle: TextStyle(
                              fontSize: ChatoraiFontSizes.base,
                              height: ChatoraiSizes.codeBlockLineHeight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SELECTABLE HIGHLIGHT VIEW
// ===========================================================================

/// A drop-in replacement for `flutter_highlight`'s `HighlightView` that
/// renders via [Text.rich] instead of `RichText`. We switched to `Text.rich`
/// (and removed `flutter_highlight` itself in favor of the lower-level
/// `highlight` package) because the outer [SelectionArea] in
/// `chat_messages.dart` only makes widgets that already expose selectable text
/// participate in the shared selection — `Text.rich` does, `RichText` does
/// not. Output is visually identical to the previous `HighlightView`.
class _SelectableHighlightView extends StatelessWidget {
  final String source;
  final String? language;
  final Map<String, TextStyle> theme;
  final TextStyle? textStyle;

  _SelectableHighlightView(
    String input, {
    this.language,
    this.theme = const {},
    this.textStyle,
    int tabSize = 8,
  }) : source = input.replaceAll('\t', ' ' * tabSize);

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);
  static const _defaultFontFamily = 'monospace';

  List<TextSpan> _convert(List<Node> nodes) {
    final List<TextSpan> spans = [];
    var currentSpans = spans;
    final List<List<TextSpan>> stack = [];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: theme[node.className!]),
        );
      } else if (node.children != null) {
        final List<TextSpan> tmp = [];
        currentSpans.add(
          TextSpan(children: tmp, style: theme[node.className!]),
        );
        stack.add(currentSpans);
        currentSpans = tmp;

        for (final n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    var baseStyle = TextStyle(
      fontFamily: _defaultFontFamily,
      color: theme[_rootKey]?.color ?? _defaultFontColor,
    );
    if (textStyle != null) {
      baseStyle = baseStyle.merge(textStyle);
    }

    final nodes = highlight.parse(source, language: language).nodes;
    if (nodes == null || nodes.isEmpty) {
      // Fall back to plain text so the surrounding SelectionArea can still
      // select it instead of crashing on a null parse result.
      return Container(
        color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
        child: Text(source, style: baseStyle),
      );
    }

    return Container(
      color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      child: Text.rich(TextSpan(style: baseStyle, children: _convert(nodes))),
    );
  }
}
