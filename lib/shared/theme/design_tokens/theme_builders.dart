import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Main theme builder — produces [ThemeData] for light and dark modes.
class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: ChatoraiColors.orange,
    primaryColorLight: const Color(0xFFFFC04C),
    primaryColorDark: const Color(0xFFCC8400),
    canvasColor: ChatoraiColors.light,
    scaffoldBackgroundColor: ChatoraiColors.lightSurface,
    cardColor: ChatoraiColors.lightCard,
    textTheme: ChatoraiTypography.lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: ChatoraiColors.light,
      foregroundColor: ChatoraiColors.dark,
      elevation: 0,
      iconTheme: IconThemeData(color: ChatoraiColors.orange),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.light(
      primary: ChatoraiColors.orange,
      secondary: ChatoraiColors.accent,
      surface: ChatoraiColors.light,
      error: ChatoraiColors.error,
    ),
    iconTheme: const IconThemeData(color: ChatoraiColors.lightIconColor),
    dividerColor: ChatoraiColors.lightBorderColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ChatoraiColors.light,
      selectedItemColor: ChatoraiColors.orange,
      unselectedItemColor: ChatoraiColors.unselectedItemLight,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ChatoraiColors.light,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: ChatoraiColors.dark,
      titleTextStyle: const TextStyle(
        color: ChatoraiColors.dark,
        fontSize: 20.0, // ChatoraiFontSizes.xxl
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: ChatoraiColors.secondaryTextColor,
        fontSize: 14.0, // ChatoraiFontSizes.base
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // ChatoraiBorderRadius.md
      ),
    ),
    cardTheme: CardThemeData(
      color: ChatoraiColors.light,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
        borderSide: const BorderSide(color: ChatoraiColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
        borderSide: const BorderSide(color: ChatoraiColors.orange),
      ),
      fillColor: ChatoraiColors.inputFill,
      filled: true,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: ChatoraiColors.orange,
    primaryColorLight: const Color(0xFFFFC04C),
    primaryColorDark: const Color(0xFFCC8400),
    canvasColor: ChatoraiColors.darkSurface,
    scaffoldBackgroundColor: ChatoraiColors.darkSurface,
    cardColor: ChatoraiColors.darkCard,
    textTheme: ChatoraiTypography.darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: ChatoraiColors.darkSurface,
      foregroundColor: ChatoraiColors.light,
      elevation: 0,
      iconTheme: IconThemeData(color: ChatoraiColors.orange),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.dark(
      primary: ChatoraiColors.orange,
      secondary: ChatoraiColors.accent,
      surface: ChatoraiColors.darkCard,
      error: ChatoraiColors.errorLight,
    ),
    iconTheme: const IconThemeData(color: ChatoraiColors.darkTextColor),
    dividerColor: ChatoraiColors.darkBorderColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ChatoraiColors.darkSurface,
      selectedItemColor: ChatoraiColors.orange,
      unselectedItemColor: ChatoraiColors.unselectedItemDark,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ChatoraiColors.darkCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: ChatoraiColors.darkTextColor,
      titleTextStyle: const TextStyle(
        color: ChatoraiColors.light,
        fontSize: 20.0, // ChatoraiFontSizes.xxl
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: ChatoraiColors.darkSecondaryTextColor,
        fontSize: 14.0, // ChatoraiFontSizes.base
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // ChatoraiBorderRadius.md
      ),
    ),
    cardTheme: CardThemeData(
      color: ChatoraiColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
        borderSide: const BorderSide(
          color: ChatoraiColors.darkInputBorder,
          width: 1.0, // ChatoraiBorderWidth.thinBold
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
        borderSide: const BorderSide(
          color: ChatoraiColors.orange,
          width: 2.0, // ChatoraiBorderWidth.medium
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // ChatoraiBorderRadius.sm
        borderSide: const BorderSide(
          color: ChatoraiColors.darkInputBorder,
          width: 1.0, // ChatoraiBorderWidth.thinBold
        ),
      ),
      fillColor: ChatoraiColors.darkInputFill,
      filled: true,
      labelStyle: const TextStyle(color: ChatoraiColors.darkSecondaryTextColor),
      hintStyle: const TextStyle(color: ChatoraiColors.secondaryTextColor),
    ),
  );

  static ThemeData getTheme(Brightness brightness) =>
      brightness == Brightness.light ? lightTheme : darkTheme;
}
