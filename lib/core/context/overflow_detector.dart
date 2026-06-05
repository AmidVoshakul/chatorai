import 'dart:math';

/// Detects context window overflow and reports usable token budget.
class OverflowDetector {
  final int contextLimit;
  final int maxOutputTokens;
  final int reservedBuffer;

  const OverflowDetector({
    required this.contextLimit,
    this.maxOutputTokens = 4096,
    this.reservedBuffer = 20000,
  });

  /// Available tokens for input context after reserving buffer.
  int get usable => max(0, contextLimit - reservedBuffer);

  /// Whether current total token usage exceeds usable context.
  bool isOverflow(int totalTokens) => totalTokens >= usable;

  /// Suggested max output tokens after accounting for used context.
  int suggestedMaxOutput(int totalTokens) {
    final remaining = usable - totalTokens;
    return max(0, min(maxOutputTokens, remaining));
  }
}
