/// Authentication configuration for AI providers.
///
/// catalog patterns: schema-driven, immutable, serializable.
/// Supports different auth types: apiKey, oauth, aws (for Bedrock), none (for local models).
/// API keys are stored securely via SecureStorage in production.
library;

import 'package:equatable/equatable.dart';

/// Authentication type for the provider.
enum AuthType {
  /// API key authentication (most common)
  apiKey,

  /// No authentication (for local models like Ollama)
  none,

  /// OAuth authentication (for Anthropic, etc.)
  oauth,

  /// AWS authentication (for Bedrock)
  aws,
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

  /// OAuth access token (for [AuthType.oauth]).
  final String? accessToken;

  /// OAuth refresh token (for [AuthType.oauth]).
  final String? refreshToken;

  /// AWS access key ID (for [AuthType.aws]).
  final String? awsAccessKeyId;

  /// AWS secret access key (for [AuthType.aws]).
  /// Should be stored securely, not hardcoded.
  final String? awsSecretAccessKey;

  /// AWS region (for [AuthType.aws]).
  final String? awsRegion;

  /// Private constructor for general use (fromJson, copyWith).
  const AuthConfig._({
    required this.type,
    this.apiKey,
    this.apiKeyHeader = 'Authorization',
    this.bearerPrefix = 'Bearer ',
    this.accessToken,
    this.refreshToken,
    this.awsAccessKeyId,
    this.awsSecretAccessKey,
    this.awsRegion,
  });

  /// Named constructor for API key auth (sets type to apiKey).
  const AuthConfig._apiKey({
    required this.apiKey,
    this.apiKeyHeader = 'Authorization',
    this.bearerPrefix = 'Bearer ',
  }) : type = AuthType.apiKey,
       accessToken = null,
       refreshToken = null,
       awsAccessKeyId = null,
       awsSecretAccessKey = null,
       awsRegion = null;

  /// Named constructor for no auth (sets type to none).
  const AuthConfig._none()
    : type = AuthType.none,
      apiKey = null,
      apiKeyHeader = 'Authorization',
      bearerPrefix = 'Bearer ',
      accessToken = null,
      refreshToken = null,
      awsAccessKeyId = null,
      awsSecretAccessKey = null,
      awsRegion = null;

  /// Named constructor for OAuth auth (sets type to oauth).
  const AuthConfig._oauth({this.accessToken, this.refreshToken})
    : type = AuthType.oauth,
      apiKey = null,
      apiKeyHeader = 'Authorization',
      bearerPrefix = 'Bearer ',
      awsAccessKeyId = null,
      awsSecretAccessKey = null,
      awsRegion = null;

  /// Named constructor for AWS auth (sets type to aws).
  const AuthConfig._aws({
    this.awsAccessKeyId,
    this.awsSecretAccessKey,
    this.awsRegion,
  }) : type = AuthType.aws,
       apiKey = null,
       apiKeyHeader = 'Authorization',
       bearerPrefix = 'Bearer ',
       accessToken = null,
       refreshToken = null;

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

  /// Create an OAuth authentication config.
  ///
  /// [accessToken] is the current OAuth access token.
  /// [refreshToken] is used to obtain new access tokens when expired.
  const factory AuthConfig.oauth({String? accessToken, String? refreshToken}) =
      AuthConfig._oauth;

  /// Create an AWS authentication config.
  ///
  /// [awsAccessKeyId] is the AWS access key ID.
  /// [awsSecretAccessKey] is the AWS secret access key (stored securely).
  /// [awsRegion] is the AWS region (e.g., 'us-east-1').
  const factory AuthConfig.aws({
    String? awsAccessKeyId,
    String? awsSecretAccessKey,
    String? awsRegion,
  }) = AuthConfig._aws;

  /// Build the authorization header value.
  ///
  /// Returns the formatted header value (e.g., 'Bearer sk-...') or null
  /// if no authentication is required.
  String? buildHeaderValue() {
    switch (type) {
      case AuthType.none:
        return null;
      case AuthType.apiKey:
        if (apiKey == null) return null;
        return '$bearerPrefix$apiKey';
      case AuthType.oauth:
        if (accessToken == null) return null;
        return '$bearerPrefix$accessToken';
      case AuthType.aws:
        // AWS uses SigV4 signing, not simple headers
        return null;
    }
  }

  /// Create a copy with modified fields.
  AuthConfig copyWith({
    AuthType? type,
    String? apiKey,
    String? apiKeyHeader,
    String? bearerPrefix,
    String? accessToken,
    String? refreshToken,
    String? awsAccessKeyId,
    String? awsSecretAccessKey,
    String? awsRegion,
    bool clearApiKey = false,
    bool clearAccessToken = false,
    bool clearRefreshToken = false,
    bool clearAwsSecretKey = false,
  }) {
    return AuthConfig._(
      type: type ?? this.type,
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
      bearerPrefix: bearerPrefix ?? this.bearerPrefix,
      accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
      refreshToken: clearRefreshToken
          ? null
          : (refreshToken ?? this.refreshToken),
      awsAccessKeyId: awsAccessKeyId ?? this.awsAccessKeyId,
      awsSecretAccessKey: clearAwsSecretKey
          ? null
          : (awsSecretAccessKey ?? this.awsSecretAccessKey),
      awsRegion: awsRegion ?? this.awsRegion,
    );
  }

  @override
  List<Object?> get props => [
    type,
    apiKey,
    apiKeyHeader,
    bearerPrefix,
    accessToken,
    refreshToken,
    awsAccessKeyId,
    awsSecretAccessKey,
    awsRegion,
  ];

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (apiKey != null) 'apiKey': apiKey,
      'apiKeyHeader': apiKeyHeader,
      'bearerPrefix': bearerPrefix,
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (awsAccessKeyId != null) 'awsAccessKeyId': awsAccessKeyId,
      if (awsSecretAccessKey != null) 'awsSecretAccessKey': awsSecretAccessKey,
      if (awsRegion != null) 'awsRegion': awsRegion,
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
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      awsAccessKeyId: json['awsAccessKeyId'] as String?,
      awsSecretAccessKey: json['awsSecretAccessKey'] as String?,
      awsRegion: json['awsRegion'] as String?,
    );
  }

  @override
  String toString() {
    return 'AuthConfig(type: $type, apiKeyHeader: $apiKeyHeader, bearerPrefix: $bearerPrefix)';
  }
}
