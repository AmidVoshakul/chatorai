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
  // RETRY CONFIGURATION
  // =======================================================================
  static const int maxRetryAttempts = 3;
  static const int baseRetryDelaySeconds = 2;

  // =======================================================================
  // TOKEN MANAGEMENT
  // =======================================================================
  static const int defaultMaxTokens = 32000;
  static const int absoluteMinTokens = 256;

  // =======================================================================
  // ADAPTIVE ROLLBACK
  // =======================================================================
  static const int maxTokenReductionAttempts = 10;
  static const double reductionFactor = 0.97;

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
  // MODEL DEFAULTS
  // =======================================================================
  static const String defaultModelId = 'nvidia/nemotron-3-nano-30b-a3b:free';

  // =======================================================================
  // STREAMING
  // =======================================================================
  static const int streamingUpdateIntervalMs = 50;
}
