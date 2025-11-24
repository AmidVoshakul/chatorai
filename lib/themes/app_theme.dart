import 'package:flutter/material.dart';

/// Ubuntu-inspired color palette
class UbuntuColors {
  // Primary colors
  static const Color orange = Color(0xFFFF7F00); // Vibrant Ubuntu orange
  static const Color dark = Color(0xFF1A0E00); // Deep dark brown
  static const Color light = Color(0xFFFFFFFF); // Pure white
  
  // Grays
  static const Color gray = Color(0xFF555555); // Dark gray for better contrast
  static const Color lightGray = Color(0xFFEEEEEE); // Light gray
  static const Color darkGray = Color(0xFF2A2A2A); // Dark gray for dark theme
  static const Color mediumGray = Color(0xFFB0B0B0); // Medium gray
  
  // Accent colors
  static const Color accent = Color(0xFF6B008E); // Deep purple
  
  // Border colors
  static const Color lightBorderColor = Color(0xFFF5F5F5); // Light gray for light theme
  static const Color darkBorderColor = Color(0xFF0C0C0C); // Dark border color for dark theme
  
  // Surface colors
  static const Color lightSurface = Color(0xFFF8F9FA); // Light surface background
  static const Color darkSurface = Color(0xFF0A0A0A); // Dark surface background
  
  // Card colors
  static const Color lightCard = Color(0xFFFFFFFF); // Light card color
  static const Color darkCard = Color(0xFF1A1A1A); // Dark card color
  
  // Text colors
  static const Color lightTextColor = Color(0xFF333333); // Primary text for light theme
  static const Color darkTextColor = Color(0xFFE0E0E0); // Primary text for dark theme
  static const Color secondaryTextColor = Color(0xFF666666); // Secondary text for light theme
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0); // Secondary text for dark theme
  
  // Input colors
  static const Color inputFill = Color(0xFFF0F0F0); // Input background for light theme
  static const Color darkInputFill = Color(0xFF252525); // Input background for dark theme
  static const Color inputBorder = Color(0xFFDDDDDD); // Input border for light theme
  static const Color darkInputBorder = Color(0xFF252525); // Input border for dark theme
}

/// Типографика для разных элементов
class UbuntuTypography {
  // Light theme text styles
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.dark,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.dark,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.dark,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.dark,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.dark,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: UbuntuColors.lightTextColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: UbuntuColors.secondaryTextColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: UbuntuColors.secondaryTextColor,
    ),
  );

  // Dark theme text styles
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.light,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.light,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.light,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.light,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: UbuntuColors.light,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: UbuntuColors.darkTextColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: UbuntuColors.darkSecondaryTextColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: UbuntuColors.darkSecondaryTextColor,
    ),
  );
}

/// Конфигурация темы приложения
class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: UbuntuColors.orange,
    primaryColorLight: const Color(0xFFFFC04C),
    primaryColorDark: const Color(0xFFCC8400),
    canvasColor: UbuntuColors.light,
    scaffoldBackgroundColor: UbuntuColors.lightSurface,
    cardColor: UbuntuColors.lightCard,
    textTheme: UbuntuTypography.lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: UbuntuColors.light,
      foregroundColor: UbuntuColors.dark,
      elevation: 0,
      iconTheme: IconThemeData(color: UbuntuColors.orange),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.light(
      primary: UbuntuColors.orange,
      secondary: UbuntuColors.accent,
      surface: UbuntuColors.light,
      background: UbuntuColors.lightSurface,
      error: Colors.red,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF444444)),
    dividerColor: UbuntuColors.lightBorderColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: UbuntuColors.light,
      selectedItemColor: UbuntuColors.orange,
      unselectedItemColor: Color(0xFF888888),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: UbuntuColors.light,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: UbuntuColors.dark,
      titleTextStyle: TextStyle(
        color: UbuntuColors.dark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: UbuntuColors.secondaryTextColor,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    cardTheme: CardThemeData(
      color: UbuntuColors.light,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: UbuntuColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: UbuntuColors.orange),
      ),
      fillColor: UbuntuColors.inputFill,
      filled: true,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: UbuntuColors.orange,
    primaryColorLight: const Color(0xFFFFC04C),
    primaryColorDark: const Color(0xFFCC8400),
    canvasColor: UbuntuColors.darkSurface,
    scaffoldBackgroundColor: UbuntuColors.darkSurface,
    cardColor: UbuntuColors.darkCard,
    textTheme: UbuntuTypography.darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: UbuntuColors.darkSurface,
      foregroundColor: UbuntuColors.light,
      elevation: 0,
      iconTheme: IconThemeData(color: UbuntuColors.orange),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    colorScheme: const ColorScheme.dark(
      primary: UbuntuColors.orange,
      secondary: UbuntuColors.accent,
      surface: UbuntuColors.darkCard,
      background: UbuntuColors.darkSurface,
      error: Colors.red,
    ),
    iconTheme: const IconThemeData(color: UbuntuColors.darkTextColor),
    dividerColor: UbuntuColors.darkBorderColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: UbuntuColors.darkSurface,
      selectedItemColor: UbuntuColors.orange,
      unselectedItemColor: Color(0xFF666666),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: UbuntuColors.darkCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: UbuntuColors.darkTextColor,
      titleTextStyle: TextStyle(
        color: UbuntuColors.light,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: UbuntuColors.darkSecondaryTextColor,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    cardTheme: CardThemeData(
      color: UbuntuColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: UbuntuColors.darkInputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: UbuntuColors.orange, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: UbuntuColors.darkInputBorder, width: 1),
      ),
      fillColor: UbuntuColors.darkInputFill,
      filled: true,
      labelStyle: TextStyle(color: UbuntuColors.darkSecondaryTextColor),
      hintStyle: TextStyle(color: UbuntuColors.secondaryTextColor),
    ),
  );

  /// Получить тему на основе яркости
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  /// Получить тему по умолчанию (светлая)
  static ThemeData get light => lightTheme;
  
  /// Получить тему по умолчанию (темная)
  static ThemeData get dark => darkTheme;
}