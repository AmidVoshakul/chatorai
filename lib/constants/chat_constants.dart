class ChatScreenConstants {
  ChatScreenConstants._();

  // UI Constants
  static const double sidebarWidth = 280.0;
  static const double sidebarCollapsedWidth = 40.0;
  static const int mobileBreakpoint = 800;

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const int baseRetryDelaySeconds = 2;

  // Token Management
  static const int defaultMaxTokens = 32000;

  // Adaptive rollback configuration
  static const int maxTokenReductionAttempts = 10;
  static const double reductionFactor = 0.97;
  static const int absoluteMinTokens = 256;

  // Error Handling
  static const int maxErrorLength = 500;
  static const String defaultErrorMessage = '';
  static const String rateLimitMessage = '';

  // Scroll & Animation
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration sidebarUpdateDelay = Duration(milliseconds: 10);
  static const Duration modelLoadWaitTime = Duration(milliseconds: 500);

  // Model Defaults
  static const String defaultModelId = 'nvidia/nemotron-3-nano-30b-a3b:free';

  // Streaming
  static const int streamingUpdateIntervalMs = 50;
}
