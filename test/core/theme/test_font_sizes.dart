import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

void main() {
  group('ChatoraiFontSizes.mono()', () {
    test('creates TextStyle with required size parameter only', () {
      final style = ChatoraiFontSizes.mono(14.0);

      expect(style.fontSize, equals(14.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates TextStyle with all parameters provided', () {
      final style = ChatoraiFontSizes.mono(
        16.0,
        color: Colors.red,
        weight: FontWeight.bold,
        height: 1.5,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.5,
      );

      expect(style.fontSize, equals(16.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      expect(style.color, equals(Colors.red));
      expect(style.fontWeight, equals(FontWeight.bold));
      expect(style.height, equals(1.5));
      expect(style.fontStyle, equals(FontStyle.italic));
      expect(style.letterSpacing, equals(0.5));
    });

    test('creates TextStyle with only color and weight parameters', () {
      final style = ChatoraiFontSizes.mono(
        12.0,
        color: ChatoraiColors.orange,
        weight: FontWeight.w600,
      );

      expect(style.fontSize, equals(12.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      expect(style.color, equals(ChatoraiColors.orange));
      expect(style.fontWeight, equals(FontWeight.w600));
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates TextStyle with only height and fontStyle parameters', () {
      final style = ChatoraiFontSizes.mono(
        13.0,
        height: 1.2,
        fontStyle: FontStyle.italic,
      );

      expect(style.fontSize, equals(13.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      expect(style.height, equals(1.2));
      expect(style.fontStyle, equals(FontStyle.italic));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates TextStyle with only letterSpacing parameter', () {
      final style = ChatoraiFontSizes.mono(11.0, letterSpacing: -0.25);

      expect(style.fontSize, equals(11.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      expect(style.letterSpacing, equals(-0.25));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
    });

    test('inherits fontFamily from monospaceFont constant', () {
      final style = ChatoraiFontSizes.mono(14.0);

      expect(style.fontFamily, isNotNull);
      expect(style.fontFamily, contains('Monaco'));
      expect(style.fontFamily, contains('Consolas'));
      expect(style.fontFamily, contains('Courier New'));
      expect(style.fontFamily, contains('monospace'));
    });

    test('handles null parameters gracefully - all optional params null', () {
      final style = ChatoraiFontSizes.mono(
        14.0,
        color: null,
        weight: null,
        height: null,
        fontStyle: null,
        letterSpacing: null,
      );

      expect(style.fontSize, equals(14.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('handles zero size parameter', () {
      final style = ChatoraiFontSizes.mono(0.0);

      expect(style.fontSize, equals(0.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
    });

    test('handles negative size parameter', () {
      final style = ChatoraiFontSizes.mono(-10.0);

      expect(style.fontSize, equals(-10.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
    });

    test('handles very large size parameter', () {
      final style = ChatoraiFontSizes.mono(100.0);

      expect(style.fontSize, equals(100.0));
      expect(style.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
    });

    test('handles different FontWeight values', () {
      final normalStyle = ChatoraiFontSizes.mono(
        14.0,
        weight: FontWeight.normal,
      );
      final boldStyle = ChatoraiFontSizes.mono(14.0, weight: FontWeight.bold);
      final w900Style = ChatoraiFontSizes.mono(14.0, weight: FontWeight.w900);

      expect(normalStyle.fontWeight, equals(FontWeight.normal));
      expect(boldStyle.fontWeight, equals(FontWeight.bold));
      expect(w900Style.fontWeight, equals(FontWeight.w900));
    });

    test('handles different FontStyle values', () {
      final normalStyle = ChatoraiFontSizes.mono(
        14.0,
        fontStyle: FontStyle.normal,
      );
      final italicStyle = ChatoraiFontSizes.mono(
        14.0,
        fontStyle: FontStyle.italic,
      );

      expect(normalStyle.fontStyle, equals(FontStyle.normal));
      expect(italicStyle.fontStyle, equals(FontStyle.italic));
    });

    test('handles different height values including decimal', () {
      final style1 = ChatoraiFontSizes.mono(14.0, height: 1.0);
      final style2 = ChatoraiFontSizes.mono(14.0, height: 1.5);
      final style3 = ChatoraiFontSizes.mono(14.0, height: 2.0);

      expect(style1.height, equals(1.0));
      expect(style2.height, equals(1.5));
      expect(style3.height, equals(2.0));
    });

    test('handles different letterSpacing values including negative', () {
      final style1 = ChatoraiFontSizes.mono(14.0, letterSpacing: -2.0);
      final style2 = ChatoraiFontSizes.mono(14.0, letterSpacing: 0.0);
      final style3 = ChatoraiFontSizes.mono(14.0, letterSpacing: 5.0);

      expect(style1.letterSpacing, equals(-2.0));
      expect(style2.letterSpacing, equals(0.0));
      expect(style3.letterSpacing, equals(5.0));
    });

    test('returns same fontFamily for different size values', () {
      final style1 = ChatoraiFontSizes.mono(10.0);
      final style2 = ChatoraiFontSizes.mono(20.0);
      final style3 = ChatoraiFontSizes.mono(32.0);

      expect(style1.fontFamily, equals(style2.fontFamily));
      expect(style2.fontFamily, equals(style3.fontFamily));
      expect(style3.fontFamily, equals(ChatoraiFontSizes.monospaceFont));
    });

    test('creates style with color only', () {
      final style = ChatoraiFontSizes.mono(14.0, color: ChatoraiColors.error);

      expect(style.color, equals(ChatoraiColors.error));
      expect(style.fontWeight, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates style with weight only', () {
      final style = ChatoraiFontSizes.mono(14.0, weight: FontWeight.w300);

      expect(style.fontWeight, equals(FontWeight.w300));
      expect(style.color, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates style with height only', () {
      final style = ChatoraiFontSizes.mono(14.0, height: 1.8);

      expect(style.height, equals(1.8));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates style with fontStyle only', () {
      final style = ChatoraiFontSizes.mono(14.0, fontStyle: FontStyle.italic);

      expect(style.fontStyle, equals(FontStyle.italic));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.height, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates style with letterSpacing only', () {
      final style = ChatoraiFontSizes.mono(14.0, letterSpacing: 1.5);

      expect(style.letterSpacing, equals(1.5));
      expect(style.color, isNull);
      expect(style.fontWeight, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
    });

    test('creates style with color and height', () {
      final style = ChatoraiFontSizes.mono(
        14.0,
        color: ChatoraiColors.success,
        height: 1.4,
      );

      expect(style.color, equals(ChatoraiColors.success));
      expect(style.height, equals(1.4));
      expect(style.fontWeight, isNull);
      expect(style.fontStyle, isNull);
      expect(style.letterSpacing, isNull);
    });

    test('creates style with weight and letterSpacing', () {
      final style = ChatoraiFontSizes.mono(
        14.0,
        weight: FontWeight.w700,
        letterSpacing: 0.1,
      );

      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.letterSpacing, equals(0.1));
      expect(style.color, isNull);
      expect(style.height, isNull);
      expect(style.fontStyle, isNull);
    });

    test('creates style with all text-related parameters', () {
      final style = ChatoraiFontSizes.mono(
        14.0,
        color: Colors.blue,
        weight: FontWeight.w500,
        height: 1.3,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.2,
      );

      expect(style.color, equals(Colors.blue));
      expect(style.fontWeight, equals(FontWeight.w500));
      expect(style.height, equals(1.3));
      expect(style.fontStyle, equals(FontStyle.italic));
      expect(style.letterSpacing, equals(0.2));
    });

    test('monospaceFont constant is accessible', () {
      expect(ChatoraiFontSizes.monospaceFont, isNotNull);
      expect(ChatoraiFontSizes.monospaceFont, isA<String>());
      expect(ChatoraiFontSizes.monospaceFont.length, greaterThan(0));
    });

    test('fontSize property is correctly set in returned style', () {
      final style = ChatoraiFontSizes.mono(15.0);
      expect(style.fontSize, equals(15.0));
    });
  });
}
