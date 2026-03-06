import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Ubuntu-inspired color palette
class ChatoraiColors {
  // Primary colors
  static const Color orange = Color(0xFFFF7F00); // Vibrant Ubuntu orange
  static const Color dark = Color(0xFF1A0E00); // Deep dark brown
  static const Color light = Color(0xFFEBEBEB); // Pure white

  // Grays
  static const Color gray = Color(0xFF555555); // Dark gray for better contrast
  static const Color lightGray = Color(0xFFEEEEEE); // Light gray
  static const Color darkGray = Color(0xFF2A2A2A); // Dark gray for dark theme
  static const Color mediumGray = Color(0xFFB0B0B0); // Medium gray

  // Accent colors
  static const Color accent = Color(0xFF6B008E); // Deep purple
  static const Color neonBlue = Color.fromARGB(255, 0, 145, 255); // Neon blue

  // Border colors
  static const Color lightBorderColor = Color(
    0xFFF5F5F5,
  ); // Light gray for light theme
  static const Color darkBorderColor = Color(
    0xFF0C0C0C,
  ); // Dark border color for dark theme

  // Surface colors
  static const Color lightSurface = Color(
    0xFFF8F9FA,
  ); // Light surface background
  static const Color darkSurface = Color(0xFF0A0A0A); // Dark surface background

  // Card colors
  static const Color lightCard = Color(0xFFFFFFFF); // Light card color
  static const Color darkCard = Color(0xFF1A1A1A); // Dark card color

  // Text colors
  static const Color lightTextColor = Color(
    0xFF333333,
  ); // Primary text for light theme
  static const Color darkTextColor = Color(
    0xFFE0E0E0,
  ); // Primary text for dark theme
  static const Color secondaryTextColor = Color(
    0xFF666666,
  ); // Secondary text for light theme
  static const Color darkSecondaryTextColor = Color(
    0xFFB0B0B0,
  ); // Secondary text for dark theme

  // Input colors
  static const Color inputFill = Color(
    0xFFF0F0F0,
  ); // Input background for light theme
  static const Color darkInputFill = Color(
    0xFF252525,
  ); // Input background for dark theme
  static const Color inputBorder = Color(
    0xFFDDDDDD,
  ); // Input border for light theme
  static const Color darkInputBorder = Color(
    0xFF252525,
  ); // Input border for dark theme

  // Navigation bar colors
  static const Color navBarBackgroundLight = Color(
    0xFFF0F0F0,
  ); // Light theme nav bar background
  static const Color navBarBackgroundDark = Color(
    0xFF1A1A1A,
  ); // Dark theme nav bar background
  static const Color navBarBorderLight = Color(
    0xFFE0E0E0,
  ); // Light theme nav bar border
  static const Color navBarBorderDark = Color(
    0xFF2A2A2A,
  ); // Dark theme nav bar border

  // Input widget container colors
  static const Color inputContainerLight = Color(
    0xFFFFFFFF,
  ); // Light theme input container
  static const Color inputContainerDark = Color(
    0xFF1A1A1A,
  ); // Dark theme input container
  static const Color inputContainerBorderLight = Color(
    0xFFE0E0E0,
  ); // Light theme input border
  static const Color inputContainerBorderDark = Color(
    0xFF2A2A2A,
  ); // Dark theme input border

  // Toggle/Switch colors
  static const Color toggleInactiveThumbLight = Color(
    0xFFFAFAFA,
  ); // Toggle thumb - light theme
  static const Color toggleInactiveThumbDark = Color(
    0xFFBDBDBD,
  ); // Toggle thumb - dark theme
  static const Color toggleInactiveTrackLight = Color(
    0xFFE0E0E0,
  ); // Toggle track - light theme
  static const Color toggleInactiveTrackDark = Color(
    0xFF424242,
  ); // Toggle track - dark theme
}

/// Типографика для разных элементов
class UbuntuTypography {
  // Light theme text styles
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.dark,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: ChatoraiColors.lightTextColor),
    bodyMedium: TextStyle(fontSize: 14, color: ChatoraiColors.secondaryTextColor),
    bodySmall: TextStyle(fontSize: 12, color: ChatoraiColors.secondaryTextColor),
  );

  // Dark theme text styles
  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: const Color.from(alpha: 1, red: 0.541, green: 0.157, blue: 0.157),
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: ChatoraiColors.light,
    ),
    bodyLarge: TextStyle(fontSize: 16, color: ChatoraiColors.darkTextColor),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: ChatoraiColors.darkSecondaryTextColor,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: ChatoraiColors.darkSecondaryTextColor,
    ),
  );
}

/// Стили для Markdown в зависимости от темы
class UbuntuMarkdownStyles {
  /// Получить стили для Markdown в зависимости от текущей темы
  static MarkdownStyleSheet getMarkdownStyles(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = Theme.of(context);

    // Начинаем с базовых стилей темы
    final baseStyle = MarkdownStyleSheet.fromTheme(theme);

    if (brightness == Brightness.light) {
      return baseStyle.copyWith(
        // Цитаты - светлая тема с оранжевым акцентом
        blockquote: baseStyle.blockquote?.copyWith(
          color: ChatoraiColors.secondaryTextColor,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
        blockquoteDecoration: BoxDecoration(
          color: ChatoraiColors.lightGray.withAlpha(50), // Очень легкий серый
          border: Border(
            left: BorderSide(color: ChatoraiColors.orange, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),

        // Код - улучшаем видимость
        code: baseStyle.code?.copyWith(
          backgroundColor: ChatoraiColors.lightGray.withAlpha(
            150,
          ), // Светлый фон с хорошей видимостью
          color: Colors.blue[700],
          fontFamily: 'Monaco, Consolas, "Courier New", monospace',
          fontSize: 13,
          shadows: [
            Shadow(
              color: ChatoraiColors.lightGray.withAlpha(150),
              offset: const Offset(-2, 0),
              blurRadius: 0,
            ),
            Shadow(
              color: ChatoraiColors.lightGray.withAlpha(150),
              offset: const Offset(2, 0),
              blurRadius: 0,
            ),
          ], // Визуальное расширение фона слева и справа
        ),

        // Ссылки - оранжевые
        a: baseStyle.a?.copyWith(
          color: ChatoraiColors.orange,
          decoration: TextDecoration.underline,
        ),

        // Заголовки - улучшаем контраст
        h1: baseStyle.h1?.copyWith(color: ChatoraiColors.dark),
        h2: baseStyle.h2?.copyWith(color: ChatoraiColors.dark),
        h3: baseStyle.h3?.copyWith(color: ChatoraiColors.dark),
      );
    } else {
      return baseStyle.copyWith(
        // Цитаты - темная тема с оранжевым акцентом
        blockquote: baseStyle.blockquote?.copyWith(
          color: ChatoraiColors.darkSecondaryTextColor,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
        blockquoteDecoration: BoxDecoration(
          color: ChatoraiColors.darkGray.withAlpha(
            150,
          ), // Темный фон с легкой прозрачностью
          border: Border(
            left: BorderSide(color: ChatoraiColors.orange, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),

        // Код - темная тема
        code: baseStyle.code?.copyWith(
          // backgroundColor: ChatoraiColors.darkGray.withAlpha(200), // Темный фон с увеличенной непрозрачностью
          color: Colors.blue[300],
          fontFamily: 'Monaco, Consolas, "Courier New", monospace',
          fontSize: 13,
        ),

        // Ссылки - оранжевые
        a: baseStyle.a?.copyWith(
          color: ChatoraiColors.orange,
          decoration: TextDecoration.underline,
        ),

        // Заголовки - светлые в темной теме
        h1: baseStyle.h1?.copyWith(color: ChatoraiColors.light),
        h2: baseStyle.h2?.copyWith(color: ChatoraiColors.light),
        h3: baseStyle.h3?.copyWith(color: ChatoraiColors.light),
      );
    }
  }
}

/// Конфигурация темы приложения
class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: ChatoraiColors.orange,
    primaryColorLight: const Color(0xFFFFC04C),
    primaryColorDark: const Color(0xFFCC8400),
    canvasColor: ChatoraiColors.light,
    scaffoldBackgroundColor: ChatoraiColors.lightSurface,
    cardColor: ChatoraiColors.lightCard,
    textTheme: UbuntuTypography.lightTextTheme,
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
      error: Colors.red,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF444444)),
    dividerColor: ChatoraiColors.lightBorderColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ChatoraiColors.light,
      selectedItemColor: ChatoraiColors.orange,
      unselectedItemColor: Color(0xFF888888),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ChatoraiColors.light,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: ChatoraiColors.dark,
      titleTextStyle: TextStyle(
        color: ChatoraiColors.dark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: ChatoraiColors.secondaryTextColor,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    cardTheme: CardThemeData(
      color: ChatoraiColors.light,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChatoraiColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChatoraiColors.orange),
      ),
      fillColor: ChatoraiColors.inputFill,
      filled: true,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: ChatoraiColors.orange,
    primaryColorLight: const Color(0xFFFFC04C),
    primaryColorDark: const Color(0xFFCC8400),
    canvasColor: ChatoraiColors.darkSurface,
    scaffoldBackgroundColor: ChatoraiColors.darkSurface,
    cardColor: ChatoraiColors.darkCard,
    textTheme: UbuntuTypography.darkTextTheme,
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
      error: Colors.red,
    ),
    iconTheme: const IconThemeData(color: ChatoraiColors.darkTextColor),
    dividerColor: ChatoraiColors.darkBorderColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ChatoraiColors.darkSurface,
      selectedItemColor: ChatoraiColors.orange,
      unselectedItemColor: Color(0xFF666666),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ChatoraiColors.darkCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconColor: ChatoraiColors.darkTextColor,
      titleTextStyle: TextStyle(
        color: ChatoraiColors.light,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: ChatoraiColors.darkSecondaryTextColor,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    cardTheme: CardThemeData(
      color: ChatoraiColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChatoraiColors.darkInputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChatoraiColors.orange, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ChatoraiColors.darkInputBorder, width: 1),
      ),
      fillColor: ChatoraiColors.darkInputFill,
      filled: true,
      labelStyle: TextStyle(color: ChatoraiColors.darkSecondaryTextColor),
      hintStyle: TextStyle(color: ChatoraiColors.secondaryTextColor),
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
