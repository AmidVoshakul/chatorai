import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// ============================================================
/// CHATORAI DESIGN SYSTEM
/// ============================================================
/// Centralized theme constants for the entire application.
/// All colors, spacing, sizes, and styles in one place.
/// Change once - applies everywhere!

// ===============================================================
// COLORS
// ===============================================================
class ChatoraiColors {
  // Primary
  static const Color orange = Color(0xFFFF7F00);
  static const Color dark = Color(0xFF1A0E00);
  static const Color light = Color(0xFFEBEBEB);

  // Grayscale
  static const Color gray = Color(0xFF555555);
  static const Color lightGray = Color(0xFFEEEEEE);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color mediumGray = Color(0xFFB0B0B0);

  // Black/White
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // Semi-transparent blacks (5%-30%)
  static const Color black05 = Color(0x0D000000);
  static const Color black10 = Color(0x1A000000);
  static const Color black12 = Color(0x1F000000);
  static const Color black15 = Color(0x26000000);
  static const Color black20 = Color(0x33000000);
  static const Color black30 = Color(0x4D000000);

  // Semi-transparent whites
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white90 = Color(0xE6FFFFFF);

  // Accent
  static const Color accent = Color(0xFF6B008E);
  static const Color neonBlue = Color(0xFF0091FF);

  // Semantic
  static const Color error = Color(0xFFFF0000);
  static const Color errorLight = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
  static const Color link = Color(0xFF2196F3);
  static const Color warning = Color(0xFFFFC107);

  // Code
  static const Color codeBackgroundLight = Color(0xFFF8F9FA);
  static const Color codeBackgroundDark = Color(0xFF1A1A1A);
  static const Color codeBorderLight = Color(0xFFE9ECEF);
  static const Color codeBorderDark = Color(0xFF23241F);
  static const Color codeHighlightDark = Color(0xFF23241F);
  static const Color codeLight = Color(0xFF1565C0);
  static const Color codeDark = Color(0xFF64B5F6);

  // Surface & Card
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color darkSurface = Color(0xFF0A0A0A);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1A1A1A);

  // Text
  static const Color lightTextColor = Color(0xFF333333);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  static const Color secondaryTextColor = Color(0xFF666666);
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);

  // Borders
  static const Color lightBorderColor = Color(0xFFF5F5F5);
  static const Color darkBorderColor = Color(0xFF0C0C0C);

  // Input
  static const Color inputFill = Color(0xFFF0F0F0);
  static const Color darkInputFill = Color(0xFF252525);
  static const Color inputBorder = Color(0xFFDDDDDD);
  static const Color darkInputBorder = Color(0xFF252525);

  // Navigation
  static const Color navBarBackgroundLight = Color(0xFFF0F0F0);
  static const Color navBarBackgroundDark = Color(0xFF1A1A1A);
  static const Color navBarBorderLight = Color(0xFFE0E0E0);
  static const Color navBarBorderDark = Color(0xFF2A2A2A);

  // Icon
  static const Color lightIconColor = Color(0xFF444444);
  static const Color unselectedItemLight = Color(0xFF888888);
  static const Color unselectedItemDark = Color(0xFF666666);

  // Hover/State
  static const Color hoverLight = Color(0x1AFF7F00);
  static const Color hoverDark = Color(0x1AFF7F00);
  static const Color selectedLight = Color(0x33FF7F00);
  static const Color selectedDark = Color(0x33FF7F00);

  // Input Container
  static const Color inputContainerLight = Color(0xFFFFFFFF);
  static const Color inputContainerDark = Color(0xFF1A1A1A);
  static const Color inputContainerBorderLight = Color(0xFFE0E0E0);
  static const Color inputContainerBorderDark = Color(0xFF2A2A2A);

  // Toggle/Switch
  static const Color toggleInactiveThumbLight = Color(0xFFFAFAFA);
  static const Color toggleInactiveThumbDark = Color(0xFFBDBDBD);
  static const Color toggleInactiveTrackLight = Color(0xFFE0E0E0);
  static const Color toggleInactiveTrackDark = Color(0xFF424242);

  // Speech Overlay
  static const Color speechOverlayBackgroundLight = Color(0xDD000000);
  static const Color speechOverlayBackgroundDark = Color(0xEE000000);
  static const Color speechOverlayTextLight = Color(0xFFFFFFFF);
  static const Color speechOverlayTextDark = Color(0xFFFFFFFF);
  static const Color speechOverlayWaveLight = Color(0xFFFFFFFF);
  static const Color speechOverlayWaveDark = Color(0xFFFFFFFF);
  static const double speechOverlayBlur = 20.0;
}

// ===============================================================
// SPACING (base unit: 4px)
// ===============================================================
class ChatoraiSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Specific
  static const double sidebarItemHeight = 60.0;
  static const double sidebarIconSpacing = 12.0;
}

// ===============================================================
// BORDER RADIUS
// ===============================================================
class ChatoraiBorderRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;

  // Radius objects
  static final Radius xsRadius = Radius.circular(xs);
  static final Radius smRadius = Radius.circular(sm);
  static final Radius mdRadius = Radius.circular(md);
  static final Radius lgRadius = Radius.circular(lg);
  static final Radius xlRadius = Radius.circular(xl);
}

// ===============================================================
// ICON SIZES
// ===============================================================
class ChatoraiIconSizes {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 60.0;

  // Specific
  static const double actionIcon = 16.0;
  static const double buttonIcon = 20.0;
  static const double sidebarMenuIcon = 18.0;
  static const double sidebarIcon = 20.0;
  static const double emptyStateIcon = 60.0;
}

// ===============================================================
// ICON OPACITY
// ===============================================================
class ChatoraiIconOpacity {
  static const double low = 0.5;
  static const double medium = 0.7;
  static const double high = 0.8;
}

// ===============================================================
// FONT SIZES
// ===============================================================
class ChatoraiFontSizes {
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

// ===============================================================
// SPECIFIC SIZES
// ===============================================================
class ChatoraiSizes {
  // Sidebar
  static const double sidebarActionMenuWidth = 36.0;
  static const double sidebarIconButtonSize = 28.0;
  static const double sidebarSplashRadiusCollapsed = 16.0;
  static const double sidebarSplashRadiusExpanded = 20.0;

  // Loading
  static const double loadingIndicatorMaxWidth = 60.0;
  static const double chatLoadingIndicatorDefaultSize = 12.0;
  static const double chatTypingDotsDefaultSize = 6.0;

  // Code
  static const double codeBlockLineHeight = 1.5;
  static const double codeBlockHeaderHeight = 28.0;

  // Error
  static const double errorTextLineHeight = 1.4;

  // Icon Button
  static const double iconButtonSplashRadius = 18.0;
}

// ===============================================================
// SHADOWS
// ===============================================================
class ChatoraiShadows {
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: ChatoraiColors.black10,
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lightFooterShadow => [
    BoxShadow(
      color: ChatoraiColors.black15,
      blurRadius: 8,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: ChatoraiColors.pureBlack.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get darkFooterShadow => [
    BoxShadow(
      color: ChatoraiColors.pureBlack.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: ChatoraiColors.black10,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get popupShadow => [
    BoxShadow(
      color: ChatoraiColors.black20,
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

// ===============================================================
// BORDER WIDTHS
// ===============================================================
class ChatoraiBorderWidth {
  static const double none = 0.0;
  static const double thin = 0.5;
  static const double thinBold = 1.0;
  static const double medium = 2.0;
  static const double thick = 3.0;
  static const double bold = 4.0;
}

// ===============================================================
// ANIMATION DURATIONS
// ===============================================================
class ChatoraiDurations {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 300);
}

// ===============================================================
// TYPOGRAPHY
// ===============================================================
class ChatoraiTypography {
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

// ===============================================================
// MARKDOWN STYLES
// ===============================================================
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

// ===============================================================
// MAIN THEME
// ===============================================================
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
        fontSize: ChatoraiFontSizes.xxl,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: ChatoraiColors.secondaryTextColor,
        fontSize: ChatoraiFontSizes.base,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
    ),
    cardTheme: CardThemeData(
      color: ChatoraiColors.light,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        borderSide: const BorderSide(color: ChatoraiColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
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
        fontSize: ChatoraiFontSizes.xxl,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: ChatoraiColors.darkSecondaryTextColor,
        fontSize: ChatoraiFontSizes.base,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
    ),
    cardTheme: CardThemeData(
      color: ChatoraiColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        borderSide: const BorderSide(
          color: ChatoraiColors.darkInputBorder,
          width: ChatoraiBorderWidth.thinBold,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        borderSide: const BorderSide(
          color: ChatoraiColors.orange,
          width: ChatoraiBorderWidth.medium,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        borderSide: const BorderSide(
          color: ChatoraiColors.darkInputBorder,
          width: ChatoraiBorderWidth.thinBold,
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
