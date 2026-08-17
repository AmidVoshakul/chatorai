/// Cache token breakdown extracted from a raw provider `usage` object.
class UsageCacheTokens {
  final int read;
  final int write;

  const UsageCacheTokens({this.read = 0, this.write = 0});
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
UsageCacheTokens extractCacheTokens(Map<String, dynamic> usage) {
  int? read;
  int? write;

  // Read candidates (first non-zero wins).
  final readCandidates = <int?>[
    _deepInt(usage, ['prompt_tokens_details', 'cached_tokens']),
    _deepInt(usage, ['input_tokens_details', 'cached_tokens']),
    _deepInt(usage, ['prompt_cache_hit_tokens']),
    _deepInt(usage, ['cache_read_input_tokens']),
  ];

  for (final candidate in readCandidates) {
    if (candidate != null && candidate > 0) {
      read = candidate;
      break;
    }
  }

  // Write candidates (first non-zero wins).
  final writeCandidates = <int?>[
    _deepInt(usage, ['cache_creation_input_tokens']),
    _deepInt(usage, ['input_tokens_details', 'cache_write_tokens']),
  ];

  for (final candidate in writeCandidates) {
    if (candidate != null && candidate > 0) {
      write = candidate;
      break;
    }
  }

  return UsageCacheTokens(
    read: read ?? 0,
    write: write ?? 0,
  );
}

/// Safely reads a nested int value from [map] following [keys].
///
/// Returns `null` if any intermediate value is missing or cannot be cast to
/// `int` (handles string-encoded numbers and `null`).
int? _deepInt(Map<String, dynamic> map, List<String> keys) {
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
