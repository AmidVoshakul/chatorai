import 'dart:convert';

/// Canonical JSON representation of [input] with sorted keys.
///
/// Used for stable cache keys and doom-loop detection across runs with
/// different map key orders.
String canonicalJson(Map<String, dynamic> input) {
  final sorted = Map<String, dynamic>.fromEntries(
    input.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return jsonEncode(sorted);
}
