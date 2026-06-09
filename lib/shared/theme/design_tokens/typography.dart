import 'package:flutter/material.dart';

import 'colors.dart';

/// Font size constants.
abstract class ChatoraiFontSizes {
  static const double xs = 10.0;
  static const double sm = 11.0;
  static const double md = 12.0;
  static const double base = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;
  static const double display = 32.0;

  // Specific
  static const double code = 13.0;

  // Sidebar
  static const double sidebarTitle = 18.0;
  static const double sidebarItem = 14.0;
  static const double sidebarDate = 11.0;
  static const double caption = 12.0;
}

/// Text theme definitions for light and dark modes.
abstract class ChatoraiTypography {
  static TextTheme get lightTextTheme => TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    headlineMedium: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      color: ChatoraiColors.lightTextColor,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      color: ChatoraiColors.secondaryTextColor,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      color: ChatoraiColors.secondaryTextColor,
    ),
  );

  static TextTheme get darkTextTheme => TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.pureWhite.withValues(alpha: 0.87),
    ),
    headlineMedium: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      color: ChatoraiColors.darkTextColor,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      color: ChatoraiColors.darkSecondaryTextColor,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      color: ChatoraiColors.darkSecondaryTextColor,
    ),
  );
}
