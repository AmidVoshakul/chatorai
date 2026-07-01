// ── AssistantContent: Typed parts for assistant messages ───────────────
// Based on OpenCode's Part union type structure.
// Each part has id, sessionId, messageId for proper identity tracking.

import 'package:equatable/equatable.dart';

enum ToolState { pending, running, completed, error }

/// Base sealed class for assistant message content parts.
/// Using abstract class pattern for cross-file subclasses.
abstract class AssistantContent extends Equatable {
  final String? id;
  final String? sessionId;
  final String? messageId;

  const AssistantContent({this.id, this.sessionId, this.messageId});

  Map<String, dynamic> toJson();

  static AssistantContent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'text':
        return AssistantText.fromJson(json);
      case 'reasoning':
        return AssistantReasoning.fromJson(json);
      case 'tool':
        return AssistantTool.fromJson(json);
      case 'file':
        return AssistantFile.fromJson(json);
      case 'image':
        return AssistantImage.fromJson(json);
      case 'agent':
        return AssistantAgent.fromJson(json);
      case 'rawText':
        return RawText.fromJson(json);
      case 'rawReasoning':
        return RawReasoning.fromJson(json);
      default:
        return RawText(text: json['text'] as String? ?? '');
    }
  }

  String get type {
    final json = toJson();
    return json['type'] as String? ?? 'unknown';
  }
}

// ── Text ───────────────────────────────────────────────────────────────

class AssistantText extends AssistantContent {
  final String text;
  final bool synthetic;
  final bool ignored;
  final String? title;

  const AssistantText({
    required String id,
    required String sessionId,
    required String messageId,
    required this.text,
    this.synthetic = false,
    this.ignored = false,
    this.title,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  factory AssistantText.raw(String text) => RawText(text: text) as AssistantText;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'id': id,
        'sessionId': sessionId,
        'messageId': messageId,
        'text': text,
        'synthetic': synthetic,
        'ignored': ignored,
        if (title != null) 'title': title,
      };

  factory AssistantText.fromJson(Map<String, dynamic> json) => AssistantText(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        text: json['text'] as String? ?? '',
        synthetic: json['synthetic'] as bool? ?? false,
        ignored: json['ignored'] as bool? ?? false,
        title: json['title'] as String?,
      );

  @override
  List<Object?> get props => [id, sessionId, messageId, text, synthetic, ignored, title];
}

// ── Reasoning ──────────────────────────────────────────────────────────

class AssistantReasoning extends AssistantContent {
  final String text;
  final DateTime started;
  final DateTime? ended;

  const AssistantReasoning({
    required String id,
    required String sessionId,
    required String messageId,
    required this.text,
    required this.started,
    this.ended,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'reasoning',
        'id': id,
        'sessionId': sessionId,
        'messageId': messageId,
        'text': text,
        'started': started.toIso8601String(),
        if (ended != null) 'ended': ended!.toIso8601String(),
      };

  factory AssistantReasoning.fromJson(Map<String, dynamic> json) => AssistantReasoning(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        text: json['text'] as String? ?? '',
        started: json['started'] != null
            ? DateTime.parse(json['started'] as String)
            : DateTime.now(),
        ended: json['ended'] != null ? DateTime.parse(json['ended'] as String) : null,
      );

  @override
  List<Object?> get props => [id, sessionId, messageId, text, started, ended];
}

// ── Tool ───────────────────────────────────────────────────────────────

class AssistantTool extends AssistantContent {
  final String callId;
  final String tool;
  final ToolState state;
  final Map<String, dynamic> input;
  final String? output;
  final int durationMs;

  const AssistantTool({
    required String id,
    required String sessionId,
    required String messageId,
    required this.callId,
    required this.tool,
    required this.state,
    this.input = const {},
    this.output,
    this.durationMs = 0,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool',
        'id': id,
        'sessionId': sessionId,
        'messageId': messageId,
        'callId': callId,
        'tool': tool,
        'state': state.name,
        'input': input,
        if (output != null) 'output': output,
        'durationMs': durationMs,
      };

  factory AssistantTool.fromJson(Map<String, dynamic> json) => AssistantTool(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        callId: json['callId'] as String,
        tool: json['tool'] as String,
        state: ToolState.values.byName(json['state'] as String),
        input: json['input'] as Map<String, dynamic>? ?? {},
        output: json['output'] as String?,
        durationMs: json['durationMs'] as int? ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, sessionId, messageId, callId, tool, state, input, output, durationMs];

  AssistantTool copyWith({
    String? id,
    String? sessionId,
    String? messageId,
    String? callId,
    String? tool,
    ToolState? state,
    Map<String, dynamic>? input,
    String? output,
    int? durationMs,
  }) {
    return AssistantTool(
      id: id ?? this.id!,
      sessionId: sessionId ?? this.sessionId!,
      messageId: messageId ?? this.messageId!,
      callId: callId ?? this.callId,
      tool: tool ?? this.tool,
      state: state ?? this.state,
      input: input ?? this.input,
      output: output ?? this.output,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

// ── File ───────────────────────────────────────────────────────────────

class AssistantFile extends AssistantContent {
  final String filename;
  final String mimeType;
  final String url;
  final String? source;

  const AssistantFile({
    required String id,
    required String sessionId,
    required String messageId,
    required this.filename,
    required this.mimeType,
    required this.url,
    this.source,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'file',
        'id': id,
        'sessionId': sessionId,
        'messageId': messageId,
        'filename': filename,
        'mimeType': mimeType,
        'url': url,
        if (source != null) 'source': source,
      };

  factory AssistantFile.fromJson(Map<String, dynamic> json) => AssistantFile(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        filename: json['filename'] as String,
        mimeType: json['mimeType'] as String,
        url: json['url'] as String,
        source: json['source'] as String?,
      );

  @override
  List<Object?> get props => [id, sessionId, messageId, filename, mimeType, url, source];
}

// ── Image ──────────────────────────────────────────────────────────────

class AssistantImage extends AssistantContent {
  final String mimeType;
  final String url;
  final int? width;
  final int? height;
  final String? filename;

  const AssistantImage({
    required String id,
    required String sessionId,
    required String messageId,
    required this.mimeType,
    required this.url,
    this.width,
    this.height,
    this.filename,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'image',
        'id': id,
        'sessionId': sessionId,
        'messageId': messageId,
        'mimeType': mimeType,
        'url': url,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (filename != null) 'filename': filename,
      };

  factory AssistantImage.fromJson(Map<String, dynamic> json) => AssistantImage(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        mimeType: json['mimeType'] as String,
        url: json['url'] as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
        filename: json['filename'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, sessionId, messageId, mimeType, url, width, height, filename];
}

// ── Agent ──────────────────────────────────────────────────────────────

class AssistantAgent extends AssistantContent {
  final String name;

  const AssistantAgent({
    required String id,
    required String sessionId,
    required String messageId,
    required this.name,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'agent',
        'id': id,
        'sessionId': sessionId,
        'messageId': messageId,
        'name': name,
      };

  factory AssistantAgent.fromJson(Map<String, dynamic> json) => AssistantAgent(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [id, sessionId, messageId, name];
}

// ── Raw (synthetic, for streaming) ─────────────────────────────────────

class RawText extends AssistantContent {
  final String text;

  const RawText({required this.text}) : super();

  @override
  Map<String, dynamic> toJson() => {'type': 'rawText', 'text': text};

  factory RawText.fromJson(Map<String, dynamic> json) => RawText(text: json['text'] as String? ?? '');

  @override
  List<Object?> get props => [text];
}

class RawReasoning extends AssistantContent {
  final String text;
  final String? title;

  const RawReasoning({required this.text, this.title}) : super();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rawReasoning',
        'text': text,
        if (title != null) 'title': title,
      };

  factory RawReasoning.fromJson(Map<String, dynamic> json) => RawReasoning(
        text: json['text'] as String? ?? '',
        title: json['title'] as String?,
      );

  @override
  List<Object?> get props => [text, title];
}

// ── Helpers ────────────────────────────────────────────────────────────

extension AssistantContentHelpers on AssistantContent {
  /// Check if this content belongs to a specific session
  bool belongsToSession(String sessionId) => this.sessionId == sessionId;

  /// Check if this content belongs to a specific message
  bool belongsToMessage(String messageId) => this.messageId == messageId;

  /// Convert to legacy MessagePart for widget compatibility
  Map<String, dynamic> toPartMap() => toJson();
}