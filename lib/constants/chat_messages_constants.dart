class ChatMessagesConstants {
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 16.0;
  static const double messageSpacing = 8.0;
  static const double loadingIndicatorSize = 12.0;

  static const Duration updateInterval = Duration(milliseconds: 16);
  static const int minChunkLengthForUpdate = 1;

  static const int maxPreviewLength = 50;
  static const int maxReasoningPreviewLength = 100;

  static const String noAssistantMessageError =
      'No assistant message to update';
  static const String noReasoningError =
      'Cannot update reasoning, no assistant message found';
}
