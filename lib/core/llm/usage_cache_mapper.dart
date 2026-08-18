/// Cache token breakdown extracted from a raw provider `usage` object.
class UsageCacheTokens {
  final int read;
  final int write;

  const UsageCacheTokens({this.read = 0, this.write = 0});
}

/// Reasoning token breakdown extracted from a raw provider `usage` object.
class UsageReasoningTokens {
  final int reasoning;

  const UsageReasoningTokens({this.reasoning = 0});
}

/// Raw usage data extracted from a provider's raw `usage` map.
///
/// Combines totals, cache breakdown, and reasoning tokens in one pass.
class UsageRawData {
  final int inputTotal;
  final int outputTotal;
  final int cacheRead;
  final int cacheWrite;
  final int reasoning;

  const UsageRawData({
    this.inputTotal = 0,
    this.outputTotal = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
    this.reasoning = 0,
  });
}

/// Maps provider-specific cache fields into a unified breakdown.
///
/// Supported providers:
/// - OpenAI Chat Completions: `prompt_tokens_details.cached_tokens`.
/// - OpenAI Responses: `input_tokens_details.cached_tokens` / `cache_write_tokens`.
/// - DeepSeek: `prompt_cache_hit_tokens` (miss tokens are NOT cache writes —
///   they are billed at full input price).
/// - Anthropic-compatible gateways: `cache_read_input_tokens` /
///   `cache_creation_input_tokens`.
UsageCacheTokens extractCacheTokens(Object? rawUsage) {
  final map = rawUsage is Map<String, dynamic> ? rawUsage : null;
  int? read;
  int? write;

  // Read candidates (first non-zero wins).
  final readCandidates = <int?>[
    _deepInt(map, ['prompt_tokens_details', 'cached_tokens']),
    _deepInt(map, ['input_tokens_details', 'cached_tokens']),
    _deepInt(map, ['prompt_cache_hit_tokens']),
    _deepInt(map, ['cache_read_input_tokens']),
  ];

  for (final candidate in readCandidates) {
    if (candidate != null && candidate > 0) {
      read = candidate;
      break;
    }
  }

  // Write candidates (first non-zero wins).
  final writeCandidates = <int?>[
    _deepInt(map, ['cache_creation_input_tokens']),
    _deepInt(map, ['input_tokens_details', 'cache_write_tokens']),
  ];

  for (final candidate in writeCandidates) {
    if (candidate != null && candidate > 0) {
      write = candidate;
      break;
    }
  }

  return UsageCacheTokens(read: read ?? 0, write: write ?? 0);
}

/// Maps provider-specific reasoning fields into a unified count.
///
/// Supported providers:
/// - OpenAI-compatible (kilo, etc.): `completion_tokens_details.reasoning_tokens`.
/// - Other gateways: top-level `reasoning_tokens`.
int extractReasoningTokens(Object? rawUsage) {
  final map = rawUsage is Map<String, dynamic> ? rawUsage : null;
  final direct = _deepInt(map, ['reasoning_tokens']);
  if (direct != null && direct > 0) return direct;
  return _deepInt(map, ['completion_tokens_details', 'reasoning_tokens']) ?? 0;
}

/// Extracts all usage fields from a raw provider `usage` map in one pass.
///
/// Returns [UsageRawData] with totals, cache breakdown, and reasoning tokens.
/// Null-safe: returns zeros for missing or non-map input.
UsageRawData extractUsageRawData(Object? rawUsage) {
  final map = rawUsage is Map<String, dynamic> ? rawUsage : null;
  return UsageRawData(
    inputTotal:
        _deepInt(map, ['prompt_tokens']) ??
        _deepInt(map, ['input_tokens']) ??
        0,
    outputTotal:
        _deepInt(map, ['completion_tokens']) ??
        _deepInt(map, ['output_tokens']) ??
        0,
    cacheRead: extractCacheTokens(rawUsage).read,
    cacheWrite: extractCacheTokens(rawUsage).write,
    reasoning: extractReasoningTokens(rawUsage),
  );
}

/// Safely reads a nested int value from [map] following [keys].
///
/// Returns `null` if any intermediate value is missing or cannot be cast to
/// `int` (handles string-encoded numbers and `null`).
int? _deepInt(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) return null;
  dynamic current = map;
  for (final key in keys) {
    if (current is Map<String, dynamic>) {
      current = current[key];
    } else {
      return null;
    }
  }
  if (current == null) return null;
  if (current is int) return current;
  if (current is double) return current.toInt();
  if (current is String) return int.tryParse(current);
  return null;
}
