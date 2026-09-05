import 'dart:convert';

import 'package:chatorai/core/mcp/mcp_config.dart';

/// Error thrown when user-entered JSON in the "Add MCP server" dialog cannot
/// be parsed into the expected shape.
class McpDialogParseError implements Exception {
  McpDialogParseError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// User-facing label for the JSON field that failed to parse.
const String mcpDialogErrorLabel = 'Invalid JSON';

/// Multi-line, indented example shown as the hint inside the Raw JSON tab so
/// users can paste a whole server object exactly like in the docs — the server
/// name is the OUTER key (e.g. `"searxng"`), no need to retype it. Kept here
/// (not in ARB) because the ICU lexer rejects the `{`/`}` braces a real JSON
/// example requires.
const String mcpRawExample = '''
{
  "mcpServers": {
    "searxng": {
      "type": "local",
      "enabled": true,
      "command": ["uvx", "--from", "searxng-mcp", "searxng-mcp"],
      "environment": {
        "SEARXNG_URL": "http://localhost:8081"
      },
      "timeout": 300000
    }
  }
}
''';

/// Authentication scheme for a remote MCP server token. The user pastes only
/// the bare token; the dialog wraps it into the correct header following
/// common API best practices:
/// - [noAuth]  -> no headers (public servers)
/// - [token]   -> `Authorization: Bearer <token>` (OAuth2 standard / API key)
/// - [oauth]   -> OAuth 2.1 configuration (client credentials flow)
enum AuthType {
  noAuth('No Auth'),
  token('Token'),
  oauth('OAuth 2.1');

  const AuthType(this.label);
  final String label;
}

/// Wraps a bare [token] into the headers map dictated by [type].
///
/// Returns an empty map when [type] is [AuthType.noAuth] or when [token]
/// is blank.
Map<String, String> buildAuthHeaders(String token, AuthType type) {
  if (type == AuthType.noAuth) return const {};
  final trimmed = token.trim();
  if (trimmed.isEmpty) return const {};

  return switch (type) {
    AuthType.token => {'Authorization': 'Bearer $trimmed'},
    AuthType.oauth => const {},
    AuthType.noAuth => const {},
  };
}

/// Parses a raw MCP server declaration (as pasted from docs) into an
/// [McpServerConfig] plus its server name.
///
/// Two shapes are accepted for convenience:
/// 1. The whole-object form documented everywhere — the server name is the
///    OUTER key: `{"searxng": { "type": "local", ... }}`.
/// 2. The documented wrapper form, e.g. `{"mcpServers": {"searxng": {...}}}`
///    — the single wrapper key is unwrapped transparently.
/// 3. Legacy single-object form with `name` inside: `{"name": "x", ...}`.
///
/// Throws [McpDialogParseError] on malformed JSON, more than one top-level key,
/// or a structurally invalid server declaration.
(String, McpServerConfig) parseRawServerJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw McpDialogParseError('$mcpDialogErrorLabel: server object is empty');
  }

  Object? decoded;
  try {
    decoded = json.decode(trimmed);
  } on FormatException catch (e) {
    throw McpDialogParseError('$mcpDialogErrorLabel: ${e.message}');
  }

  if (decoded is! Map<String, dynamic>) {
    throw McpDialogParseError('$mcpDialogErrorLabel: expected a server object');
  }

  // Transparently unwrap a single-key wrapper such as "mcpServers" so users
  // can paste the server block exactly as published in the MCP docs.
  final Map<String, dynamic> body = _unwrapWrapper(decoded);

  late final String name;
  late final Map<String, dynamic> serverJson;

  if (body.containsKey('name') && body['name'] is String) {
    // Legacy: name is inside the object.
    name = body['name'] as String;
    serverJson = body;
  } else if (body.length == 1) {
    // Documented form: name is the single outer key; the server JSON is the
    // value of that key.
    final entry = body.entries.single;
    name = entry.key;
    if (entry.value is! Map<String, dynamic>) {
      throw McpDialogParseError(
        '$mcpDialogErrorLabel: value of "$name" must be a server object',
      );
    }
    serverJson = entry.value as Map<String, dynamic>;
  } else {
    throw McpDialogParseError(
      '$mcpDialogErrorLabel: paste one server at a time — use the outer key '
      'as its name (e.g. "searxng": { ... })',
    );
  }

  if (name.trim().isEmpty) {
    throw McpDialogParseError('$mcpDialogErrorLabel: server name is empty');
  }

  try {
    return (name, McpServerConfig.fromJson(serverJson));
  } on ArgumentError catch (e) {
    throw McpDialogParseError('$mcpDialogErrorLabel: ${e.message}');
  }
}

/// Well-known wrapper keys used by MCP docs / client config files
/// (`claude_desktop_config.json`, `mcp.json`, ChatORAI's own `chatorai.json`).
const Set<String> _mcpWrapperKeys = {'mcpServers', 'servers', 'mcp'};

/// Strips a single-key wrapper (e.g. `mcpServers`) so a server block copied
/// verbatim from the MCP docs resolves to the inner server map. Returns [map]
/// unchanged when it is not such a wrapper.
///
/// Only the documented wrapper keys are unwrapped (not every single-key map),
/// so a target form like `{"searxng": {...}}` keeps `searxng` as the server
/// name rather than being mistaken for a wrapper.
Map<String, dynamic> _unwrapWrapper(Map<String, dynamic> map) {
  if (map.length == 1) {
    final entry = map.entries.single;
    if (_mcpWrapperKeys.contains(entry.key) &&
        entry.value is Map<String, dynamic>) {
      return entry.value as Map<String, dynamic>;
    }
  }
  return map;
}

Map<String, String> _parseStringMap(String raw, String field) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const {};

  Object? decoded;
  try {
    decoded = json.decode(trimmed);
  } on FormatException catch (e) {
    throw McpDialogParseError('$mcpDialogErrorLabel in $field: ${e.message}');
  }

  if (decoded is! Map) {
    throw McpDialogParseError(
      '$mcpDialogErrorLabel in $field: expected an object',
    );
  }

  final result = <String, String>{};
  for (final entry in decoded.entries) {
    if (entry.value is! String) {
      throw McpDialogParseError(
        '$mcpDialogErrorLabel in $field: values must be strings',
      );
    }
    result[entry.key.toString()] = entry.value as String;
  }
  return result;
}

/// Parses an optional `environment` JSON object into a string map.
///
/// Returns an empty map for blank input. Throws [McpDialogParseError] when the
/// text is not a JSON object whose values are all strings.
Map<String, String> parseEnvJson(String raw) =>
    _parseStringMap(raw, 'environment');

/// Parses an optional `headers` JSON object into a string map.
///
/// Returns an empty map for blank input. Throws [McpDialogParseError] when the
/// text is not a JSON object whose values are all strings.
Map<String, String> parseHeadersJson(String raw) =>
    _parseStringMap(raw, 'headers');

/// Parses an optional `environment` JSON object into a string map.
