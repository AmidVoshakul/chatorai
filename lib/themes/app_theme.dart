import 'package:flutter/material.dart';

class AppTheme {
  // Ubuntu-inspired color palette
  static const Color ubuntuOrange = Color(0xFFFF7F00); // More vibrant orange
  static const Color ubuntuDark = Color(0xFF1A0E00); // Deeper dark brown
  static const Color ubuntuLight = Color(0xFFFFFFFF);
  static const Color ubuntuGray = Color(0xFF555555); // Darker gray for better contrast
  static const Color ubuntuLightGray = Color(0xFFEEEEEE);
  static const Color ubuntuDarkGray = Color(0xFF2A2A2A);
  static const Color ubuntuAccent = Color(0xFF6B008E); // Deeper purple
  static const Color ubuntuLightBorderColor = Color(0xFFF5F5F5); // Light gray for light theme
  static const Color ubuntuDarkBorderColor = Color(0xFF0C0C0C); // Dark border color for dark theme

// Light theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: ubuntuOrange,
    primaryColorLight: Color(0xFFFFC04C),
    primaryColorDark: Color(0xFFCC8400),
    canvasColor: const Color(0xFFFFFFFF),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    cardColor: const Color(0xFFFFFFFF),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: ubuntuDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ubuntuDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: const Color(0xFF333333),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: const Color(0xFF666666),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: const Color(0xFF666666),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ubuntuDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: ubuntuDark,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: ubuntuDark,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ubuntuLight,
      foregroundColor: ubuntuDark,
      elevation: 0,
      iconTheme: IconThemeData(color: ubuntuOrange),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    colorScheme: ColorScheme.light(
      primary: ubuntuOrange,
      secondary: ubuntuAccent,
      surface: ubuntuLight,
      background: const Color(0xFFF8F9FA),
      error: Colors.red,
    ),
    iconTheme: IconThemeData(color: const Color(0xFF444444)),
    dividerColor: ubuntuLightBorderColor,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: ubuntuLight,
      selectedItemColor: ubuntuOrange,
      unselectedItemColor: const Color(0xFF888888),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ubuntuLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: ubuntuDark,
      titleTextStyle: TextStyle(
        color: ubuntuDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: const Color(0xFF666666),
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    cardTheme: CardThemeData(
      color: ubuntuLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ubuntuOrange),
      ),
      fillColor: const Color(0xFFF0F0F0),
      filled: true,
    ),
  );

// Dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: ubuntuOrange,
    primaryColorLight: Color(0xFFFFC04C),
    primaryColorDark: Color(0xFFCC8400),
    canvasColor: const Color(0xFF0A0A0A),
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    cardColor: const Color(0xFF1A1A1A),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: ubuntuLight,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ubuntuLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: const Color(0xFFE0E0E0),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: const Color(0xFFB0B0B0),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: const Color(0xFFB0B0B0),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ubuntuLight,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: ubuntuLight,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: ubuntuLight,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0A0A0A),
      foregroundColor: ubuntuLight,
      elevation: 0,
      iconTheme: IconThemeData(color: ubuntuOrange),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    colorScheme: ColorScheme.dark(
      primary: ubuntuOrange,
      secondary: ubuntuAccent,
      surface: const Color(0xFF1A1A1A),
      background: const Color(0xFF0A0A0A),
      error: Colors.red,
    ),
    iconTheme: IconThemeData(color: const Color(0xFFE0E0E0)),
    dividerColor: ubuntuDarkBorderColor,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF0A0A0A),
      selectedItemColor: ubuntuOrange,
      unselectedItemColor: const Color(0xFF666666),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: const Color(0xFFE0E0E0),
      titleTextStyle: TextStyle(
        color: ubuntuLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: const Color(0xFFB0B0B0),
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFF252525), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ubuntuOrange, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFF252525), width: 1),
      ),
      fillColor: const Color(0xFF252525),
      filled: true,
      labelStyle: TextStyle(color: const Color(0xFFB0B0B0)),
      hintStyle: TextStyle(color: const Color(0xFF666666)),
    ),
  );

  // Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }
}