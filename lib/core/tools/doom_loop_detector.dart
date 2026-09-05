import 'package:chatorai/shared/utils/canonical_json.dart';

/// Bounded per-session doom-loop detector.
///
/// Tracks repeated identical tool invocations within a session and flags
/// potential doom loops. History is capped per-tool and per-session to avoid
/// unbounded memory growth.
class DoomLoopDetector {
  final Map<String, Map<String, List<String>>> _history = {};
  static const _maxPerTool = 500;
  static const _maxPerSession = 2000;
  static const _doomLoopThreshold = 3;

  /// Returns `true` if [sessionId]/[toolName]/[input] has been seen at least
  /// [_doomLoopThreshold] times, indicating a potential doom loop.
  bool check(String? sessionId, String toolName, Map<String, dynamic> input) {
    final key = sessionId ?? '_global_null_session';
    _history.putIfAbsent(key, () => {});
    final perTool = _history[key]!;
    perTool.putIfAbsent(toolName, () => []);
    final jsonInput = canonicalJson(input);
    final count = perTool[toolName]!.where((c) => c == jsonInput).length;
    if (count >= _doomLoopThreshold) return true;
    perTool[toolName]!.add(jsonInput);

    // LRU prune per-tool
    if (perTool[toolName]!.length > _maxPerTool) {
      perTool[toolName]!.removeRange(
        0,
        perTool[toolName]!.length - _maxPerTool,
      );
    }
    // LRU prune per-session
    var total = perTool.values.fold<int>(0, (s, e) => s + e.length);
    if (total > _maxPerSession) {
      final excess = total - _maxPerSession;
      for (final key in perTool.keys.toList()) {
        if (excess <= 0) break;
        final entries = perTool[key]!;
        final drop = entries.length < excess ? entries.length : excess;
        entries.removeRange(0, drop);
        if (entries.isEmpty) perTool.remove(key);
      }
    }
    return false;
  }

  /// Purge all history for a closed session.
  void pruneSession(String sessionId) {
    _history.remove(sessionId);
  }
}
