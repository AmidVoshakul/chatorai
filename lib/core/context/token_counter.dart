import 'dart:math';

/// Heuristic token counter with CJK-aware estimation.
///
/// Tracks three primary buckets and two cache buckets:
/// - `system` — system prompt tokens
/// - `input` — user/assistant message tokens (heuristic or API-reported)
/// - `output` — generated output tokens (from API usage headers)
/// - `cacheRead` — prompt caching read tokens (e.g. Anthropic)
/// - `cacheWrite` — prompt caching write tokens (e.g. Anthropic)
///
/// Uses `String.length ~/ 4` baseline with CJK correction for estimation.
/// API-reported tokens (via [recordUsage]) take precedence over estimates
/// and are added on top of whatever is already tracked.
class TokenCounter {
  static final RegExp _cjkRegex = RegExp(
    r'[\u3040-\u309F\u30A0-\u30FF\u3400-\u4DBF\u4E00-\u9FAF\uF900-\uFAFF'
    r'\uAC00-\uD7AF]',
  );

  int _systemTokens = 0;
  int _inputTokens = 0;
  int _outputTokens = 0;
  int _cacheReadTokens = 0;
  int _cacheWriteTokens = 0;

  int get totalTokens =>
      _systemTokens +
      _inputTokens +
      _outputTokens +
      _cacheReadTokens +
      _cacheWriteTokens;

  int get inputTokens => _inputTokens;
  int get outputTokens => _outputTokens;
  int get cacheReadTokens => _cacheReadTokens;
  int get cacheWriteTokens => _cacheWriteTokens;

  void reset() {
    _systemTokens = 0;
    _inputTokens = 0;
    _outputTokens = 0;
    _cacheReadTokens = 0;
    _cacheWriteTokens = 0;
  }

  /// Estimate tokens for a string using CJK-aware heuristic.
  /// Default: length ~/ 4. With CJK: length * 3 ~/ 4 (more accurate).
  static int estimate(String text) {
    if (text.isEmpty) return 0;
    if (_cjkRegex.hasMatch(text)) {
      return (text.length * 3) ~/ 4;
    }
    return text.length ~/ 4;
  }

  /// Add system prompt tokens.
  void addSystem(String systemPrompt) {
    _systemTokens += estimate(systemPrompt);
  }

  /// Add user/assistant message tokens.
  void addMessage(String content) {
    _inputTokens += estimate(content);
  }

  /// Add raw output tokens from API response.
  void addOutput(int tokens) {
    _outputTokens += max(0, tokens);
  }

  /// Add prompt-cache read tokens (e.g. Anthropic cache_read).
  void addCacheRead(int tokens) {
    _cacheReadTokens += max(0, tokens);
  }

  /// Add prompt-cache write tokens (e.g. Anthropic cache_creation).
  void addCacheWrite(int tokens) {
    _cacheWriteTokens += max(0, tokens);
  }

  /// Record usage from AI SDK finish event.
  void recordUsage({
    int? promptTokens,
    int? completionTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
  }) {
    if (promptTokens != null && promptTokens > 0) {
      _inputTokens += promptTokens;
    }
    if (completionTokens != null && completionTokens > 0) {
      _outputTokens += completionTokens;
    }
    if (cacheReadTokens != null && cacheReadTokens > 0) {
      _cacheReadTokens += cacheReadTokens;
    }
    if (cacheWriteTokens != null && cacheWriteTokens > 0) {
      _cacheWriteTokens += cacheWriteTokens;
    }
  }
}
