import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unified card style (like Auto-Approve tools)', () {
    test(
      'premiumCard dark uses gradient, border and shadow like Auto-Approve',
      () {
        final deco = premiumCard(true);
        expect(deco.gradient, isA<LinearGradient>());
        final g = deco.gradient as LinearGradient;
        expect(g.colors, const [Color(0xFF1E1E1E), Color(0xFF262626)]);
        expect(g.begin, Alignment.topLeft);
        expect(g.end, Alignment.bottomRight);
        expect(
          deco.borderRadius,
          BorderRadius.circular(ChatoraiBorderRadius.md),
        );
        expect(deco.border, isA<Border>());
        // border color must be darkInputBorder
        final border = deco.border as Border;
        expect(border.top.color, ChatoraiColors.darkInputBorder);
        expect(deco.boxShadow, ChatoraiShadows.darkShadow);
      },
    );

    test(
      'premiumCard light uses gradient, border and shadow like Auto-Approve',
      () {
        final deco = premiumCard(false);
        expect(deco.gradient, isA<LinearGradient>());
        final g = deco.gradient as LinearGradient;
        expect(g.colors, const [Color(0xFFFAFAFA), Color(0xFFF5F5F5)]);
        expect(
          deco.borderRadius,
          BorderRadius.circular(ChatoraiBorderRadius.md),
        );
        final border = deco.border as Border;
        expect(border.top.color, ChatoraiColors.inputBorder);
        expect(deco.boxShadow, ChatoraiShadows.cardShadow);
      },
    );

    testWidgets('HoverCard-like container renders with unified decoration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Container(
              decoration: premiumCard(true),
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container));
      final deco = container.decoration as BoxDecoration;
      expect(deco.gradient, isNotNull);
    });
  });
}
