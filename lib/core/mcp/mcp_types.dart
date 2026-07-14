/// MCP tool information returned by `tools/list`.
class McpToolInfo {
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  const McpToolInfo({
    required this.name,
    this.description,
    required this.inputSchema,
  });

  factory McpToolInfo.fromJson(Map<String, dynamic> json) {
    return McpToolInfo(
      name: json['name'] as String,
      description: json['description'] as String?,
      inputSchema: Map<String, dynamic>.from(json['inputSchema'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'inputSchema': inputSchema,
  };
}

/// Result of calling an MCP tool via `tools/call`.
class McpCallResult {
  final bool isError;
  final List<McpContentPart> content;
  final Map<String, dynamic>? structuredContent;

  const McpCallResult({
    required this.isError,
    required this.content,
    this.structuredContent,
  });

  factory McpCallResult.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    final content = contentList
        .map((item) => McpContentPart.fromJson(item as Map<String, dynamic>))
        .toList();
    final structured = json['structuredContent'] as Map<String, dynamic>?;

    return McpCallResult(
      isError: json['isError'] as bool? ?? false,
      content: content,
      structuredContent: structured,
    );
  }

  Map<String, dynamic> toJson() => {
    'isError': isError,
    'content': content.map((c) => c.toJson()).toList(),
    if (structuredContent != null) 'structuredContent': structuredContent,
  };

  /// Extracts text content joined by newlines.
  String get textContent => content
      .where((c) => c.type == 'text')
      .map((c) => c.text ?? '')
      .where((t) => t.trim().isNotEmpty)
      .join('\n\n');

  @override
  String toString() => textContent.isNotEmpty
      ? textContent
      : 'McpCallResult(isError: $isError, content: ${content.length} parts)';
}

/// Part of an MCP tool result (text, image, etc.).
class McpContentPart {
  final String type;
  final String? text;
  final String? mimeType;
  final List<int>? data;

  const McpContentPart({
    required this.type,
    this.text,
    this.mimeType,
    this.data,
  });

  factory McpContentPart.fromJson(Map<String, dynamic> json) {
    return McpContentPart(
      type: json['type'] as String,
      text: json['text'] as String?,
      mimeType: json['mimeType'] as String? ?? json['mime_type'] as String?,
      data: json['data'] != null
          ? (json['data'] as List<dynamic>).cast<int>()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (text != null) 'text': text,
    if (mimeType != null) 'mimeType': mimeType,
    if (data != null) 'data': data,
  };
}

/// Connection status for an MCP server.
enum McpConnectionStatus {
  connected('connected'),
  disabled('disabled'),
  failed('failed'),
  needsAuth('needs_auth'),
  needsClientRegistration('needs_client_registration');

  final String value;
  const McpConnectionStatus(this.value);

  static McpConnectionStatus fromValue(String value) {
    return switch (value) {
      'connected' => McpConnectionStatus.connected,
      'disabled' => McpConnectionStatus.disabled,
      'failed' => McpConnectionStatus.failed,
      'needs_auth' => McpConnectionStatus.needsAuth,
      'needs_client_registration' =>
        McpConnectionStatus.needsClientRegistration,
      _ => McpConnectionStatus.failed,
    };
  }
}

/// Connection status with optional error message.
class McpServerStatus {
  final McpConnectionStatus status;
  final String? error;

  const McpServerStatus({required this.status, this.error});

  factory McpServerStatus.connected() =>
      const McpServerStatus(status: McpConnectionStatus.connected);

  factory McpServerStatus.disabled() =>
      const McpServerStatus(status: McpConnectionStatus.disabled);

  factory McpServerStatus.failed(String error) =>
      McpServerStatus(status: McpConnectionStatus.failed, error: error);

  factory McpServerStatus.needsAuth() =>
      const McpServerStatus(status: McpConnectionStatus.needsAuth);

  factory McpServerStatus.needsClientRegistration(String error) =>
      McpServerStatus(
        status: McpConnectionStatus.needsClientRegistration,
        error: error,
      );

  factory McpServerStatus.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'] as String? ?? 'failed';
    return McpServerStatus(
      status: McpConnectionStatus.fromValue(statusValue),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.value,
    if (error != null) 'error': error,
  };
}
