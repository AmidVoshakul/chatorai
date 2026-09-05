import 'package:collection/collection.dart';

/// MCP server type discriminator.
enum McpServerType {
  local('local'),
  remote('remote');

  final String value;
  const McpServerType(this.value);

  static McpServerType fromValue(String value) {
    return switch (value.toLowerCase()) {
      'local' || 'stdio' => McpServerType.local,
      'remote' || 'http' || 'https' || 'sse' => McpServerType.remote,
      _ => throw ArgumentError('Unknown MCP server type: $value'),
    };
  }
}

/// OAuth configuration for remote MCP servers.
class McpOAuthConfig {
  final String? clientId;
  final String? clientSecret;
  final String? scope;
  final int? callbackPort;
  final String? redirectUri;

  const McpOAuthConfig({
    this.clientId,
    this.clientSecret,
    this.scope,
    this.callbackPort,
    this.redirectUri,
  });

  factory McpOAuthConfig.fromJson(Map<String, dynamic> json) {
    return McpOAuthConfig(
      clientId: json['client_id'] as String? ?? json['clientId'] as String?,
      clientSecret:
          json['client_secret'] as String? ?? json['clientSecret'] as String?,
      scope: json['scope'] as String?,
      callbackPort:
          json['callback_port'] as int? ?? json['callbackPort'] as int?,
      redirectUri:
          json['redirect_uri'] as String? ?? json['redirectUri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (clientId != null) map['client_id'] = clientId;
    if (clientSecret != null) map['client_secret'] = clientSecret;
    if (scope != null) map['scope'] = scope;
    if (callbackPort != null) map['callback_port'] = callbackPort;
    if (redirectUri != null) map['redirect_uri'] = redirectUri;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpOAuthConfig &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId &&
          clientSecret == other.clientSecret &&
          scope == other.scope &&
          callbackPort == other.callbackPort &&
          redirectUri == other.redirectUri;

  @override
  int get hashCode =>
      Object.hash(clientId, clientSecret, scope, callbackPort, redirectUri);
}

/// Configuration for a single MCP server (local stdio or remote HTTP/SSE).
class McpServerConfig {
  final McpServerType type;
  final bool enabled;
  final int? timeout;

  // Local fields
  final String command;
  final List<String> args;
  final String? cwd;
  final Map<String, String> environment;

  // Remote fields
  final String? url;
  final Map<String, String>? headers;
  final McpOAuthConfig? oauth;

  const McpServerConfig._({
    required this.type,
    required this.command,
    this.args = const [],
    this.cwd,
    this.environment = const {},
    this.url,
    this.headers,
    this.oauth,
    this.enabled = true,
    this.timeout,
  });

  factory McpServerConfig.local({
    required String command,
    List<String> args = const [],
    String? cwd,
    Map<String, String> environment = const {},
    bool enabled = true,
    int? timeout,
  }) => McpServerConfig._(
    type: McpServerType.local,
    command: command,
    args: args,
    cwd: cwd,
    environment: environment,
    enabled: enabled,
    timeout: timeout,
  );

  factory McpServerConfig.remote({
    required String url,
    bool enabled = true,
    Map<String, String> headers = const {},
    McpOAuthConfig? oauth,
    int? timeout,
  }) => McpServerConfig._(
    type: McpServerType.remote,
    command: '',
    url: url,
    headers: headers,
    oauth: oauth,
    enabled: enabled,
    timeout: timeout,
  );

  bool get isLocal => type == McpServerType.local;
  bool get isRemote => type == McpServerType.remote;

  McpServerConfig copyWith({
    bool? enabled,
    int? timeout,
    String? command,
    List<String>? args,
    String? cwd,
    Map<String, String>? environment,
    String? url,
    Map<String, String>? headers,
    McpOAuthConfig? oauth,
  }) => isLocal
      ? McpServerConfig.local(
          command: command ?? this.command,
          args: args ?? this.args,
          cwd: cwd ?? this.cwd,
          environment: environment ?? this.environment,
          enabled: enabled ?? this.enabled,
          timeout: timeout ?? this.timeout,
        )
      : McpServerConfig.remote(
          url: url ?? this.url!,
          enabled: enabled ?? this.enabled,
          headers: headers ?? this.headers ?? const {},
          oauth: oauth ?? this.oauth,
          timeout: timeout ?? this.timeout,
        );

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as String? ?? 'local';
    final type = McpServerType.fromValue(typeValue);
    final enabled = json['enabled'] as bool? ?? true;
    final timeout = json['timeout'] as int?;

    if (type == McpServerType.local) {
      String command;
      List<String> args;
      final rawCommand = json['command'];
      if (rawCommand is List) {
        //  format: "command": ["bin", "arg1", "arg2"]
        final list = rawCommand.cast<String>();
        if (list.isEmpty) {
          throw ArgumentError.value(
            rawCommand,
            'command',
            'Command array must not be empty',
          );
        }
        command = list.first;
        args = list.sublist(1);
      } else if (rawCommand is String) {
        // ChatORAI format: "command": "bin", "args": ["arg1", "arg2"]
        command = rawCommand;
        args = (json['args'] as List<dynamic>?)?.cast<String>() ?? const [];
      } else {
        throw ArgumentError.value(
          rawCommand,
          'command',
          'Local MCP server requires a non-empty "command"',
        );
      }
      return McpServerConfig.local(
        command: command,
        args: args,
        cwd: json['cwd'] as String?,
        environment: Map<String, String>.from(
          json['environment'] ?? json['env'] ?? const {},
        ),
        enabled: enabled,
        timeout: timeout,
      );
    }

    final rawUrl = json['url'];
    if (rawUrl is! String || rawUrl.trim().isEmpty) {
      throw ArgumentError.value(
        rawUrl,
        'url',
        'Remote MCP server requires a non-empty "url"',
      );
    }

    return McpServerConfig.remote(
      url: rawUrl,
      enabled: enabled,
      headers: Map<String, String>.from(json['headers'] ?? const {}),
      oauth: json['oauth'] != null
          ? McpOAuthConfig.fromJson(json['oauth'] as Map<String, dynamic>)
          : null,
      timeout: timeout,
    );
  }

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{'type': type.value, 'enabled': enabled};
    if (timeout != null) base['timeout'] = timeout;

    if (isLocal) {
      base['command'] = command;
      base['args'] = args;
      if (cwd != null) base['cwd'] = cwd;
      if (environment.isNotEmpty) base['environment'] = environment;
    } else {
      base['url'] = url;
      if (headers != null && headers!.isNotEmpty) base['headers'] = headers;
      if (oauth != null) base['oauth'] = oauth!.toJson();
    }

    return base;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          enabled == other.enabled &&
          timeout == other.timeout &&
          command == other.command &&
          const ListEquality<String>().equals(args, other.args) &&
          cwd == other.cwd &&
          const MapEquality<String, String>().equals(
            environment,
            other.environment,
          ) &&
          url == other.url &&
          const MapEquality<String, String>().equals(
            headers ?? const {},
            other.headers ?? const {},
          ) &&
          oauth == other.oauth;

  @override
  int get hashCode => Object.hash(
    type,
    enabled,
    timeout,
    command,
    Object.hashAll(args),
    cwd,
    const MapEquality<String, String>().hash(environment),
    url,
    const MapEquality<String, String>().hash(headers ?? const {}),
    oauth,
  );
}

/// Top-level MCP configuration.
class McpConfig {
  final Map<String, McpServerConfig> servers;
  final int? defaultTimeout;

  const McpConfig({this.servers = const {}, this.defaultTimeout});

  factory McpConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const McpConfig();

    final servers = <String, McpServerConfig>{};
    Map<String, dynamic> serversJson;

    if (json.containsKey('servers')) {
      serversJson = json['servers'] as Map<String, dynamic>? ?? {};
    } else {
      serversJson = Map<String, dynamic>.from(json)
        ..remove('default_timeout')
        ..remove('defaultTimeout');
    }

    for (final entry in serversJson.entries) {
      if (entry.value is Map<String, dynamic>) {
        servers[entry.key] = McpServerConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return McpConfig(
      servers: servers,
      defaultTimeout:
          json['default_timeout'] as int? ?? json['defaultTimeout'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    // Flat layout: each server is keyed directly under "mcp", with no
    // intermediate "servers" wrapper, keeping the file compact and editable.
    final map = <String, dynamic>{};
    for (final entry in servers.entries) {
      map[entry.key] = entry.value.toJson();
    }
    if (defaultTimeout != null) map['default_timeout'] = defaultTimeout;
    return map;
  }
}
