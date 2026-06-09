import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/message_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';

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

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

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
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: ChatoraiBorderWidth.thinBold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        icon: Icon(
                          _isCollapsed
                              ? Icons.chevron_right
                              : Icons.expand_more,
                          color: headerColor,
                          size: ChatoraiIconSizes.lg,
                        ),
                        onPressed: () =>
                            setState(() => _isCollapsed = !_isCollapsed),
                        tooltip: _isCollapsed
                            ? localizations.expandTooltip
                            : localizations.collapseTooltip,
                        splashRadius: ChatoraiSizes.iconButtonSplashRadius,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: ChatoraiSpacing.lg,
                          minHeight: ChatoraiSpacing.lg,
                        ),
                      ),
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
                  child: IconButton(
                    icon: Icon(
                      Icons.copy_all,
                      color: headerColor,
                      size: ChatoraiIconSizes.lg,
                    ),
                    onPressed: () => MessageUtils.copyMessage(
                      content: widget.code,
                      context: context,
                    ),
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
                        child: SelectionArea(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: HighlightView(
                              widget.code,
                              language: widget.language.toLowerCase(),
                              theme: isDark ? monokaiSublimeTheme : githubTheme,
                              padding: EdgeInsets.zero,
                              textStyle: TextStyle(
                                fontSize: ChatoraiFontSizes.base,
                                height: ChatoraiSizes.codeBlockLineHeight,
                              ),
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
