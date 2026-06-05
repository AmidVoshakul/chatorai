import 'dart:math';

/// Heuristic token counter with CJK-aware estimation.
/// Uses String.length ~/ 4 baseline, with CJK correction.
class TokenCounter {
  static final RegExp _cjkRegex = RegExp(
    r'[\u3040-\u309F\u30A0-\u30FF\u3400-\u4DBF\u4E00-\u9FAF\uF900-\uFAFF'
    r'\uAC00-\uD7AF]',
  );

  int _systemTokens = 0;
  int _inputTokens = 0;
  int _outputTokens = 0;

  int get totalTokens => _systemTokens + _inputTokens + _outputTokens;

  void reset() {
    _systemTokens = 0;
    _inputTokens = 0;
    _outputTokens = 0;
  }

  /// Estimate tokens for a string using CJK-aware heuristic.
  /// Default: length ~/ 4. With CJK: length * 3 ~/ 4 (more accurate).
  int estimate(String text) {
    if (text.isEmpty) return 0;
    if (_cjkRegex.hasMatch(text)) {
      return max(1, (text.length * 3) ~/ 4);
    }
    return max(1, text.length ~/ 4);
  }

  /// Add system prompt tokens.
  void addSystem(String systemPrompt) {
    _systemTokens += estimate(systemPrompt);
  }

  /// Add user/assistant message tokens.
  void addMessage(String content) {
    _inputTokens += estimate(content);
  }

  /// Add output tokens from API response.
  void addOutput(int tokens) {
    _outputTokens += max(0, tokens);
  }

  /// Record usage from AI SDK finish event.
  void recordUsage({int? promptTokens, int? completionTokens}) {
    if (promptTokens != null && promptTokens > 0) {
      _inputTokens += promptTokens;
    }
    if (completionTokens != null && completionTokens > 0) {
      _outputTokens += completionTokens;
    }
  }
}
