/// Authentication configuration for AI providers.
///
/// Follows OpenCode catalog patterns: schema-driven, immutable, serializable.
/// Supports different auth types: apiKey, none (for local models).
/// API keys are stored securely via SecureStorage in production.
library;

import 'package:equatable/equatable.dart';

/// Authentication type for the provider.
enum AuthType {
  /// API key authentication (most common)
  apiKey,

  /// No authentication (for local models like Ollama)
  none,
}

/// Configuration for provider authentication.
///
/// This class is immutable and serializable. It defines how the provider
/// should be authenticated when making API calls.
class AuthConfig extends Equatable {
  /// Type of authentication.
  final AuthType type;

  /// API key value (only for [AuthType.apiKey]).
  /// Should be stored securely, not hardcoded.
  final String? apiKey;

  /// Header name for the API key (default: 'Authorization').
  /// Some providers use custom headers like 'X-API-Key'.
  final String apiKeyHeader;

  /// Bearer token prefix (default: 'Bearer ').
  /// Set to empty string if provider expects raw key without prefix.
  final String bearerPrefix;

  /// Private constructor for general use (fromJson, copyWith).
  const AuthConfig._({
    required this.type,
    this.apiKey,
    this.apiKeyHeader = 'Authorization',
    this.bearerPrefix = 'Bearer ',
  });

  /// Named constructor for API key auth (sets type to apiKey).
  const AuthConfig._apiKey({
    required this.apiKey,
    this.apiKeyHeader = 'Authorization',
    this.bearerPrefix = 'Bearer ',
  }) : type = AuthType.apiKey;

  /// Named constructor for no auth (sets type to none).
  const AuthConfig._none()
    : type = AuthType.none,
      apiKey = null,
      apiKeyHeader = 'Authorization',
      bearerPrefix = 'Bearer ';

  /// Create an API key authentication config.
  ///
  /// [apiKey] is the actual API key. It will be stored securely.
  /// [apiKeyHeader] defaults to 'Authorization'.
  /// [bearerPrefix] defaults to 'Bearer ' (most common).
  factory AuthConfig.apiKey({
    required String apiKey,
    String apiKeyHeader = 'Authorization',
    String bearerPrefix = 'Bearer ',
  }) {
    return AuthConfig._apiKey(
      apiKey: apiKey,
      apiKeyHeader: apiKeyHeader,
      bearerPrefix: bearerPrefix,
    );
  }

  /// Create a no-authentication config (for local models).
  const factory AuthConfig.none() = AuthConfig._none;

  /// Build the authorization header value.
  ///
  /// Returns the formatted header value (e.g., 'Bearer sk-...') or null
  /// if no authentication is required.
  String? buildHeaderValue() {
    if (type == AuthType.none) return null;
    if (apiKey == null) return null;
    return '$bearerPrefix$apiKey';
  }

  /// Create a copy with modified fields.
  AuthConfig copyWith({
    AuthType? type,
    String? apiKey,
    String? apiKeyHeader,
    String? bearerPrefix,
    bool clearApiKey = false,
  }) {
    return AuthConfig._(
      type: type ?? this.type,
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
      bearerPrefix: bearerPrefix ?? this.bearerPrefix,
    );
  }

  @override
  List<Object?> get props => [type, apiKey, apiKeyHeader, bearerPrefix];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (apiKey != null) 'apiKey': apiKey,
      'apiKeyHeader': apiKeyHeader,
      'bearerPrefix': bearerPrefix,
    };
  }

  /// Deserialize from JSON.
  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = AuthType.values.byName(typeStr);

    return AuthConfig._(
      type: type,
      apiKey: json['apiKey'] as String?,
      apiKeyHeader: json['apiKeyHeader'] as String? ?? 'Authorization',
      bearerPrefix: json['bearerPrefix'] as String? ?? 'Bearer ',
    );
  }

  @override
  String toString() {
    return 'AuthConfig(type: $type, apiKeyHeader: $apiKeyHeader, bearerPrefix: $bearerPrefix)';
  }
}
