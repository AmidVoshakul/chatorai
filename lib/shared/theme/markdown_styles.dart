import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:chatorai/shared/theme/design_tokens/borders.dart';
import 'package:chatorai/shared/theme/design_tokens/colors.dart';
import 'package:chatorai/shared/theme/design_tokens/typography.dart';

/// Markdown stylesheet builder with light/dark theme support and caching.
class ChatoraiMarkdownStyles {
  static final _cache = <int, MarkdownStyleSheet>{};

  static MarkdownStyleSheet getMarkdownStyles(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = Theme.of(context);
    final baseStyle = MarkdownStyleSheet.fromTheme(theme);

    final isLight = brightness == Brightness.light;

    // Use theme brightness hash as cache key
    final cacheKey = Object.hash(brightness, theme.brightness);

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final codeColor = isLight
        ? ChatoraiColors.codeLight
        : ChatoraiColors.codeDark;
    final grayColor = isLight
        ? ChatoraiColors.lightGray
        : ChatoraiColors.darkGray;

    final styleSheet = baseStyle.copyWith(
      blockquote: baseStyle.blockquote?.copyWith(
        color: isLight
            ? ChatoraiColors.secondaryTextColor
            : ChatoraiColors.darkSecondaryTextColor,
        fontStyle: FontStyle.italic,
        fontSize: ChatoraiFontSizes.base,
      ),
      blockquoteDecoration: BoxDecoration(
        color: grayColor.withAlpha(isLight ? 50 : 150),
        border: Border(
          left: BorderSide(
            color: ChatoraiColors.orange,
            width: ChatoraiBorderWidth.bold,
          ),
        ),
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(ChatoraiBorderRadius.sm),
        ),
      ),
      code: baseStyle.code?.copyWith(
        backgroundColor: grayColor.withAlpha(150),
        color: codeColor,
        fontFamily: 'Monaco, Consolas, "Courier New", monospace',
        fontSize: ChatoraiFontSizes.code,
        shadows: isLight
            ? [
                Shadow(
                  color: grayColor.withAlpha(150),
                  offset: const Offset(-2, 0),
                  blurRadius: 0,
                ),
                Shadow(
                  color: grayColor.withAlpha(150),
                  offset: const Offset(2, 0),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      a: baseStyle.a?.copyWith(
        color: ChatoraiColors.orange,
        decoration: TextDecoration.underline,
      ),
      h1: baseStyle.h1?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
      ),
      h2: baseStyle.h2?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
      ),
      h3: baseStyle.h3?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
      ),
    );

    _cache[cacheKey] = styleSheet;
    return styleSheet;
  }
}
