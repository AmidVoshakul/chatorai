/// Miscellaneous size constants grouped by component.
abstract class ChatoraiSizes {
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

/// Animation durations.
abstract class ChatoraiDurations {
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 300);
}
