import 'package:flutter/material.dart';

/// Chatorai color palette.
/// Primary colors, grayscale, semantic, and component-specific colors.
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
