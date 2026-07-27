class LspPosition {
  final int line;
  final int character;

  const LspPosition({required this.line, required this.character});

  factory LspPosition.fromJson(Map<String, dynamic> json) => LspPosition(
    line: json['line'] as int,
    character: json['character'] as int,
  );

  Map<String, dynamic> toJson() => {'line': line, 'character': character};
}

class LspRange {
  final LspPosition start;
  final LspPosition end;

  const LspRange({required this.start, required this.end});

  factory LspRange.fromJson(Map<String, dynamic> json) => LspRange(
    start: LspPosition.fromJson(json['start'] as Map<String, dynamic>),
    end: LspPosition.fromJson(json['end'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };
}

class LspDiagnostic {
  final LspRange range;
  final int severity;
  final String? code;
  final String? source;
  final String message;
  final Map<String, dynamic>? data;
  final List<LspDiagnostic>? relatedInformation;

  const LspDiagnostic({
    required this.range,
    required this.severity,
    this.code,
    this.source,
    required this.message,
    this.data,
    this.relatedInformation,
  });

  factory LspDiagnostic.fromJson(Map<String, dynamic> json) => LspDiagnostic(
    range: LspRange.fromJson(json['range'] as Map<String, dynamic>),
    severity: json['severity'] as int,
    code: json['code'] as String?,
    source: json['source'] as String?,
    message: json['message'] as String,
    data: json['data'] as Map<String, dynamic>?,
    relatedInformation: (json['relatedInformation'] as List<dynamic>?)
        ?.map((e) => LspDiagnostic.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'range': range.toJson(),
    'severity': severity,
    if (code != null) 'code': code,
    if (source != null) 'source': source,
    'message': message,
    if (data != null) 'data': data,
    if (relatedInformation != null)
      'relatedInformation': relatedInformation!.map((e) => e.toJson()).toList(),
  };
}

class LspPublishDiagnosticsParams {
  final String uri;
  final String version;
  final List<LspDiagnostic> diagnostics;

  const LspPublishDiagnosticsParams({
    required this.uri,
    required this.version,
    required this.diagnostics,
  });

  factory LspPublishDiagnosticsParams.fromJson(Map<String, dynamic> json) =>
      LspPublishDiagnosticsParams(
        uri: json['uri'] as String,
        version: json['version'].toString(),
        diagnostics: (json['diagnostics'] as List<dynamic>)
            .map((e) => LspDiagnostic.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'version': version,
    'diagnostics': diagnostics.map((e) => e.toJson()).toList(),
  };
}

class LspInitializeParams {
  final int? processId;
  final String? rootUri;
  final Map<String, dynamic>? capabilities;
  final Map<String, dynamic>? initializationOptions;
  final List<String>? workspaceFolders;

  const LspInitializeParams({
    this.processId,
    this.rootUri,
    this.capabilities,
    this.initializationOptions,
    this.workspaceFolders,
  });

  factory LspInitializeParams.fromJson(Map<String, dynamic> json) =>
      LspInitializeParams(
        processId: json['processId'] as int?,
        rootUri: json['rootUri'] as String?,
        capabilities: json['capabilities'] as Map<String, dynamic>?,
        initializationOptions:
            json['initializationOptions'] as Map<String, dynamic>?,
        workspaceFolders: (json['workspaceFolders'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    if (processId != null) 'processId': processId,
    if (rootUri != null) 'rootUri': rootUri,
    if (capabilities != null) 'capabilities': capabilities,
    if (initializationOptions != null)
      'initializationOptions': initializationOptions,
    if (workspaceFolders != null) 'workspaceFolders': workspaceFolders,
  };
}

class LspInitializeResult {
  final Map<String, dynamic>? capabilities;
  final String? serverInfo;

  const LspInitializeResult({this.capabilities, this.serverInfo});

  factory LspInitializeResult.fromJson(Map<String, dynamic> json) =>
      LspInitializeResult(
        capabilities: json['capabilities'] as Map<String, dynamic>?,
        serverInfo: json['serverInfo'] as String?,
      );

  Map<String, dynamic> toJson() => {
    if (capabilities != null) 'capabilities': capabilities,
    if (serverInfo != null) 'serverInfo': serverInfo,
  };
}

class LspDiagnosticSeverity {
  static const int error = 1;
  static const int warning = 2;
  static const int info = 3;
  static const int hint = 4;

  static String label(int value) => switch (value) {
    1 => 'Error',
    2 => 'Warning',
    3 => 'Info',
    4 => 'Hint',
    _ => 'Unknown',
  };

  const LspDiagnosticSeverity._();
}

/// Simplified diagnostic line for agent-facing tool output.
class LspDiagnosticLine {
  final String severity;
  final int line;
  final int column;
  final String message;

  const LspDiagnosticLine({
    required this.severity,
    required this.line,
    required this.column,
    required this.message,
  });

  @override
  String toString() => '[ $severity ] $line:$column — $message';
}
