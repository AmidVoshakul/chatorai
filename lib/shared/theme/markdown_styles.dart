import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:chatorai/shared/theme/app_theme.dart';

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
        color: grayColor.withValues(alpha: isLight ? 50 / 255 : 150 / 255),
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
        backgroundColor: grayColor.withValues(alpha: 150 / 255),
        color: codeColor,
        fontFamily: ChatoraiFontSizes.monospaceFont,
        fontSize: ChatoraiFontSizes.code,
        shadows: isLight
            ? [
                Shadow(
                  color: grayColor.withValues(alpha: 150 / 255),
                  offset: const Offset(-2, 0),
                  blurRadius: 0,
                ),
                Shadow(
                  color: grayColor.withValues(alpha: 150 / 255),
                  offset: const Offset(2, 0),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      a: baseStyle.a?.copyWith(
        color: ChatoraiColors.orange,
        decoration: TextDecoration.none,
      ),
      h1: baseStyle.h1?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
        fontWeight: FontWeight.bold,
        height: 1.5,
        fontSize: ChatoraiFontSizes.xxxl,
      ),
      h2: baseStyle.h2?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
        fontWeight: FontWeight.bold,
        height: 1.4,
        fontSize: ChatoraiFontSizes.xxl,
      ),
      h3: baseStyle.h3?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
        fontWeight: FontWeight.bold,
        height: 1.35,
        fontSize: ChatoraiFontSizes.xl,
      ),
      h4: baseStyle.h4?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
        fontWeight: FontWeight.bold,
        height: 1.3,
        fontSize: ChatoraiFontSizes.lg,
      ),
      h5: baseStyle.h5?.copyWith(
        color: isLight ? ChatoraiColors.dark : ChatoraiColors.light,
        fontWeight: FontWeight.bold,
        height: 1.25,
        fontSize: ChatoraiFontSizes.base,
      ),
      h6: baseStyle.h6?.copyWith(
        color: isLight
            ? ChatoraiColors.secondaryTextColor
            : ChatoraiColors.darkSecondaryTextColor,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        height: 1.25,
        fontSize: ChatoraiFontSizes.base,
      ),
    );

    _cache[cacheKey] = styleSheet;
    return styleSheet;
  }
}
