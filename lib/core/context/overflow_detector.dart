import 'dart:math';

/// Detects context window overflow and reports usable token budget.
class OverflowDetector {
  final int contextLimit;
  final int maxOutputTokens;
  final int reservedBuffer;

  const OverflowDetector._internal(
    this.contextLimit, {
    this.maxOutputTokens = 4096,
    required this.reservedBuffer,
  });

  /// Default constructor kept for backward compatibility.
  const OverflowDetector({
    required this.contextLimit,
    this.maxOutputTokens = 4096,
    this.reservedBuffer = 20000,
  });

  /// Creates an [OverflowDetector] sized for a specific model context window.
  ///
  /// Falls back to 200 000 tokens when [contextLength] is null or non-positive.
  /// The reserved buffer is derived as `min(20 000, contextLimit ~/ 10)` unless
  /// overridden by [compactionBuffer] from config.
  factory OverflowDetector.forModel(
    int? contextLength, {
    int? compactionBuffer,
  }) {
    final limit = (contextLength != null && contextLength > 0)
        ? contextLength
        : 200000;
    final defaultReserved = min(20000, limit ~/ 10);
    final reserved = compactionBuffer ?? defaultReserved;
    return OverflowDetector._internal(
      limit,
      maxOutputTokens: 4096,
      reservedBuffer: reserved,
    );
  }

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
