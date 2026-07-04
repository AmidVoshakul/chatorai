// ===========================================================================
// CHAT MESSAGES CONSTANTS
// ===========================================================================

class ChatMessagesConstants {
  ChatMessagesConstants._();

  // =======================================================================
  // PADDING & SPACING
  // =======================================================================
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 16.0;
  static const double messageSpacing = 8.0;

  // =======================================================================
  // LOADING
  // =======================================================================
  static const double loadingIndicatorSize = 12.0;

  // =======================================================================
  // ERROR MESSAGES
  // =======================================================================
  static const String noAssistantMessageError =
      'No assistant message to update';
  static const String noReasoningError =
      'Cannot update reasoning, no assistant message found';
}
