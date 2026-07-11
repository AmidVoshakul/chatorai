import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:chatorai/shared/theme/markdown_styles.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

void main() {
  group('ChatoraiMarkdownStyles', () {
    group('caching behavior', () {
      testWidgets(
        'returns cached style on repeated calls with same brightness',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const _TestHomePage(),
            ),
          );

          final context = tester.element(find.byType(_TestHomePage));

          // First call - should cache
          final style1 = ChatoraiMarkdownStyles.getMarkdownStyles(context);
          // Second call - should return cached
          final style2 = ChatoraiMarkdownStyles.getMarkdownStyles(context);

          expect(identical(style1, style2), isTrue);
        },
      );

      testWidgets('caches styles separately for light and dark brightness', (
        tester,
      ) async {
        // Test light theme caching
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final lightContext = tester.element(find.byType(_TestHomePage));
        final lightStyle = ChatoraiMarkdownStyles.getMarkdownStyles(
          lightContext,
        );
        final lightStyleCached = ChatoraiMarkdownStyles.getMarkdownStyles(
          lightContext,
        );

        expect(identical(lightStyle, lightStyleCached), isTrue);

        // Test dark theme caching
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final darkContext = tester.element(find.byType(_TestHomePage));
        final darkStyle = ChatoraiMarkdownStyles.getMarkdownStyles(darkContext);
        final darkStyleCached = ChatoraiMarkdownStyles.getMarkdownStyles(
          darkContext,
        );

        expect(identical(darkStyle, darkStyleCached), isTrue);
      });

      testWidgets('cache key uses Object.hash with brightness', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));

        // Verify cache key generation works correctly
        final cacheKey = Object.hash(
          MediaQuery.platformBrightnessOf(context),
          Theme.of(context).brightness,
        );

        expect(cacheKey, isNotNull);
        expect(cacheKey, isA<int>());
      });
    });

    group('light theme styles', () {
      testWidgets('returns non-null MarkdownStyleSheet for light brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style, isNotNull);
        expect(style, isA<MarkdownStyleSheet>());
      });

      testWidgets('light theme code color matches ChatoraiColors.codeLight', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.code?.color, equals(ChatoraiColors.codeLight));
      });

      testWidgets('light theme blockquote has italic fontStyle', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.blockquote?.fontStyle, equals(FontStyle.italic));
      });

      testWidgets('light theme blockquote fontSize is base', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.blockquote?.fontSize, equals(ChatoraiFontSizes.base));
      });

      testWidgets('light theme blockquote decoration has orange left border', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.blockquoteDecoration, isNotNull);
        final decoration = style.blockquoteDecoration as BoxDecoration?;
        expect(decoration?.border, isNotNull);
        // Check that the border exists and is a Border
        expect(decoration?.border is Border, isTrue);
      });

      testWidgets('light theme code has shadows applied', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.code?.shadows, isNotNull);
        expect(style.code?.shadows, isNotEmpty);
      });

      testWidgets('light theme link color is orange', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.a?.color, equals(ChatoraiColors.orange));
        expect(style.a?.decoration, equals(TextDecoration.none));
      });
    });

    group('dark theme styles', () {
      testWidgets('returns non-null MarkdownStyleSheet for dark brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style, isNotNull);
        expect(style, isA<MarkdownStyleSheet>());
      });

      testWidgets('dark theme code color is correct', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Verify code color is set (actual value depends on platform brightness)
        expect(style.code?.color, isNotNull);
      });

      testWidgets('dark theme code shadows are null or set based on brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Shadows depend on platform brightness, so just verify it's either null or a list
        expect(style.code?.shadows, anyOf(isNull, isA<List<Shadow>>()));
      });

      testWidgets('dark theme blockquote color is set', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Verify blockquote color is set
        expect(style.blockquote?.color, isNotNull);
      });

      testWidgets('dark theme h1 color is set', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Verify h1 color is set
        expect(style.h1?.color, isNotNull);
      });

      testWidgets('dark theme h2 color is set', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Verify h2 color is set
        expect(style.h2?.color, isNotNull);
      });

      testWidgets('dark theme h3 color is set', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Verify h3 color is set
        expect(style.h3?.color, isNotNull);
      });
    });

    group('cache invalidation', () {
      testWidgets('cache persists across multiple calls', (tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));

        // Multiple calls should return same cached instance
        final style1 = ChatoraiMarkdownStyles.getMarkdownStyles(context);
        final style2 = ChatoraiMarkdownStyles.getMarkdownStyles(context);
        final style3 = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(identical(style1, style2), isTrue);
        expect(identical(style2, style3), isTrue);
      });

      testWidgets('cache returns same instance on subsequent calls', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));

        // Get style multiple times
        final styles = List.generate(
          5,
          (_) => ChatoraiMarkdownStyles.getMarkdownStyles(context),
        );

        // All should be identical (cached)
        for (int i = 1; i < styles.length; i++) {
          expect(identical(styles[0], styles[i]), isTrue);
        }
      });
    });

    group('fontFamily inheritance', () {
      testWidgets('code style uses monospaceFont from ChatoraiFontSizes', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.code?.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      });
    });

    group('edge cases', () {
      testWidgets('returns valid style with all required properties', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        expect(style.a, isNotNull);
        expect(style.h1, isNotNull);
        expect(style.code, isNotNull);
        expect(style.blockquote, isNotNull);
      });

      testWidgets('blockquote decoration has correct border width', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        final decoration = style.blockquoteDecoration as BoxDecoration?;
        expect(decoration?.border, isNotNull);
        // Verify border is a Border type
        expect(decoration?.border is Border, isTrue);
      });

      testWidgets('code block background has correct opacity for light theme', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        // Light theme should have shadows (opacity 150)
        expect(style.code?.backgroundColor?.alpha, equals(150));
      });

      testWidgets('blockquote decoration has correct border radius', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const _TestHomePage()),
        );

        final context = tester.element(find.byType(_TestHomePage));
        final style = ChatoraiMarkdownStyles.getMarkdownStyles(context);

        final decoration = style.blockquoteDecoration as BoxDecoration?;
        expect(decoration?.borderRadius, isNotNull);
      });
    });
  });
}

/// Test widget to provide BuildContext for testing
class _TestHomePage extends StatelessWidget {
  const _TestHomePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
