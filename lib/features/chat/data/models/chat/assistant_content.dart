// ── AssistantContent: Typed parts for assistant messages ───────────────
// Based on OpenCode's Part union type structure.
// Each part has id, sessionId, messageId for proper identity tracking.

import 'package:equatable/equatable.dart';
import 'package:chatorai/features/chat/data/models/chat/message_part.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'todo_part.dart' show TodoItem;

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
      case 'task':
        return AssistantTask.fromJson(json);
      case 'question':
        return AssistantQuestion.fromJson(json);
      case 'todo':
        return AssistantTodo.fromJson(json);
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

  factory AssistantText.raw(String text) =>
      RawText(text: text) as AssistantText;

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
  List<Object?> get props => [
    id,
    sessionId,
    messageId,
    text,
    synthetic,
    ignored,
    title,
  ];
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

  factory AssistantReasoning.fromJson(Map<String, dynamic> json) =>
      AssistantReasoning(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        text: json['text'] as String? ?? '',
        started: json['started'] != null
            ? DateTime.parse(json['started'] as String)
            : DateTime.now(),
        ended: json['ended'] != null
            ? DateTime.parse(json['ended'] as String)
            : null,
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
  List<Object?> get props => [
    id,
    sessionId,
    messageId,
    callId,
    tool,
    state,
    input,
    output,
    durationMs,
  ];

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

// ── Task ───────────────────────────────────────────────────────────────

class AssistantTask extends AssistantContent {
  final String description;
  final String agent;
  final ToolState state;
  final String? taskSessionId;
  final String? error;
  final int? retryAttempt;
  final String? currentTool;
  final String? currentToolTitle;
  final int toolCallsCount;
  final int? durationMs;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const AssistantTask({
    required String id,
    required String sessionId,
    required String messageId,
    required this.description,
    required this.agent,
    this.state = ToolState.running,
    this.taskSessionId,
    this.error,
    this.retryAttempt,
    this.currentTool,
    this.currentToolTitle,
    this.toolCallsCount = 0,
    this.durationMs,
    this.startedAt,
    this.endedAt,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'task',
    'id': id,
    'sessionId': sessionId,
    'messageId': messageId,
    'description': description,
    'agent': agent,
    'state': state.name,
    if (taskSessionId != null) 'taskSessionId': taskSessionId,
    if (error != null) 'error': error,
    if (retryAttempt != null) 'retryAttempt': retryAttempt,
    if (currentTool != null) 'currentTool': currentTool,
    if (currentToolTitle != null) 'currentToolTitle': currentToolTitle,
    'toolCallsCount': toolCallsCount,
    if (durationMs != null) 'durationMs': durationMs,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
    if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
  };

  factory AssistantTask.fromJson(Map<String, dynamic> json) => AssistantTask(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    messageId: json['messageId'] as String,
    description: json['description'] as String,
    agent: json['agent'] as String,
    state: ToolState.values.byName(json['state'] as String? ?? 'running'),
    taskSessionId: json['taskSessionId'] as String?,
    error: json['error'] as String?,
    retryAttempt: json['retryAttempt'] as int?,
    currentTool: json['currentTool'] as String?,
    currentToolTitle: json['currentToolTitle'] as String?,
    toolCallsCount: json['toolCallsCount'] as int? ?? 0,
    durationMs: json['durationMs'] as int?,
    startedAt: json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null,
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
  );

  @override
  List<Object?> get props => [
    id,
    sessionId,
    messageId,
    description,
    agent,
    state,
    taskSessionId,
    error,
    retryAttempt,
    currentTool,
    currentToolTitle,
    toolCallsCount,
    durationMs,
    startedAt,
    endedAt,
  ];

  AssistantTask copyWith({
    String? description,
    String? agent,
    ToolState? state,
    String? taskSessionId,
    String? error,
    int? retryAttempt,
    String? currentTool,
    String? currentToolTitle,
    int? toolCallsCount,
    int? durationMs,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return AssistantTask(
      id: id!,
      sessionId: sessionId!,
      messageId: messageId!,
      description: description ?? this.description,
      agent: agent ?? this.agent,
      state: state ?? this.state,
      taskSessionId: taskSessionId ?? this.taskSessionId,
      error: error ?? this.error,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      currentTool: currentTool ?? this.currentTool,
      currentToolTitle: currentToolTitle ?? this.currentToolTitle,
      toolCallsCount: toolCallsCount ?? this.toolCallsCount,
      durationMs: durationMs ?? this.durationMs,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

// ── Question ───────────────────────────────────────────────────────────

class AssistantQuestion extends AssistantContent {
  final String question;
  final List<QuestionOption> options;
  final String? answer;
  final bool multiple;

  const AssistantQuestion({
    required String id,
    required String sessionId,
    required String messageId,
    required this.question,
    this.options = const [],
    this.answer,
    this.multiple = false,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'question',
    'id': id,
    'sessionId': sessionId,
    'messageId': messageId,
    'question': question,
    'options': options.map((o) => o.toJson()).toList(),
    'multiple': multiple,
    if (answer != null) 'answer': answer,
  };

  factory AssistantQuestion.fromJson(Map<String, dynamic> json) =>
      AssistantQuestion(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        messageId: json['messageId'] as String,
        question: json['question'] as String,
        options:
            (json['options'] as List?)
                ?.map((e) => QuestionOption.fromJson(e))
                .toList() ??
            const [],
        multiple: json['multiple'] as bool? ?? false,
        answer: json['answer'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    sessionId,
    messageId,
    question,
    options,
    answer,
    multiple,
  ];

  AssistantQuestion copyWith({String? answer, bool? multiple}) =>
      AssistantQuestion(
        id: id!,
        sessionId: sessionId!,
        messageId: messageId!,
        question: question,
        options: options,
        answer: answer ?? this.answer,
        multiple: multiple ?? this.multiple,
      );
}

// ── Todo ───────────────────────────────────────────────────────────────

class AssistantTodo extends AssistantContent {
  final List<TodoItem> todos;

  const AssistantTodo({
    required String id,
    required String sessionId,
    required String messageId,
    required this.todos,
  }) : super(id: id, sessionId: sessionId, messageId: messageId);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'todo',
    'id': id,
    'sessionId': sessionId,
    'messageId': messageId,
    'todos': todos.map((t) => t.toJson()).toList(),
  };

  factory AssistantTodo.fromJson(Map<String, dynamic> json) => AssistantTodo(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    messageId: json['messageId'] as String,
    todos:
        (json['todos'] as List?)
            ?.map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  @override
  List<Object?> get props => [id, sessionId, messageId, todos];
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
  List<Object?> get props => [
    id,
    sessionId,
    messageId,
    filename,
    mimeType,
    url,
    source,
  ];
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
  List<Object?> get props => [
    id,
    sessionId,
    messageId,
    mimeType,
    url,
    width,
    height,
    filename,
  ];
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

  factory RawText.fromJson(Map<String, dynamic> json) =>
      RawText(text: json['text'] as String? ?? '');

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
