import 'package:chatorai/core/context/overflow_detector.dart';
import 'package:chatorai/core/context/token_counter.dart';

/// Facade that bundles [TokenCounter] and [OverflowDetector] together.
///
/// Provides a single access point for token accounting and overflow checks.
class ChatTokenService {
  final TokenCounter _tokenCounter = TokenCounter();
  late OverflowDetector _overflowDetector;
  int _modelContextLength;

  ChatTokenService({int modelContextLength = 200000})
    : _modelContextLength = modelContextLength {
    _overflowDetector = OverflowDetector.forModel(_modelContextLength);
  }

  /// The underlying token counter.
  TokenCounter get counter => _tokenCounter;

  /// The current overflow detector.
  OverflowDetector get overflowDetector => _overflowDetector;

  /// Total accumulated tokens.
  int get totalTokens => _tokenCounter.totalTokens;

  /// Whether the current token count exceeds the model context limit.
  bool get isOverflow =>
      _overflowDetector.isOverflow(_tokenCounter.totalTokens);

  /// Updates the model context length and rebuilds the overflow detector.
  void updateModelContextLength(int contextLength) {
    _modelContextLength = contextLength;
    _overflowDetector = OverflowDetector.forModel(contextLength);
  }

  /// Expose context length for diagnostic purposes.
  int get modelContextLength => _modelContextLength;
}
