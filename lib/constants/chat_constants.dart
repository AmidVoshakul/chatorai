// ===========================================================================
// CHAT SCREEN CONSTANTS
// ===========================================================================

class ChatScreenConstants {
  ChatScreenConstants._();

  // =======================================================================
  // UI CONSTANTS
  // =======================================================================
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 40.0;
  static const int mobileBreakpoint = 800;

  // =======================================================================
  // ERROR HANDLING
  // =======================================================================
  static const int maxErrorLength = 500;
  static const String defaultErrorMessage = '';
  static const String rateLimitMessage = '';

  // =======================================================================
  // SCROLL & ANIMATION
  // =======================================================================
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration sidebarUpdateDelay = Duration(milliseconds: 10);
  static const Duration modelLoadWaitTime = Duration(milliseconds: 500);

  // =======================================================================
  // STREAMING
  // =======================================================================
  static const int streamingUpdateIntervalMs = 50;
}
