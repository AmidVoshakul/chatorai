import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/features/chat/data/models/chat/assistant_content.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'session_id.dart';

part 'session_state.g.dart';

enum MessageRole { user, assistant, tool }

/// Converter for [SessionID] — bridges brand type to plain JSON string.
class SessionIDConverter implements JsonConverter<SessionID, String> {
  const SessionIDConverter();

  @override
  SessionID fromJson(String value) => SessionID.fromString(value);

  @override
  String toJson(SessionID value) => value.value;
}

/// Converter for nullable [SessionID].
class SessionIDNullableConverter implements JsonConverter<SessionID?, String?> {
  const SessionIDNullableConverter();

  @override
  SessionID? fromJson(String? value) =>
      value == null ? null : SessionID.fromString(value);

  @override
  String? toJson(SessionID? value) => value?.value;
}

SessionID _sessionIdFromJson(String value) => SessionID.fromString(value);
String _sessionIdToJson(SessionID value) => value.value;

@JsonSerializable()
class SessionMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final int seq;
  final String? model;
  final String? reasoning;
  final String? error;
  final DateTime createdAt;

  const SessionMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.seq,
    this.model,
    this.reasoning,
    this.error,
    required this.createdAt,
  });

  factory SessionMessage.fromJson(Map<String, dynamic> json) =>
      _$SessionMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SessionMessageToJson(this);

  SessionMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    int? seq,
    String? model,
    String? reasoning,
    String? error,
    DateTime? createdAt,
  }) {
    return SessionMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      seq: seq ?? this.seq,
      model: model ?? this.model,
      reasoning: reasoning ?? this.reasoning,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    content,
    seq,
    model,
    reasoning,
    error,
    createdAt,
  ];
}

@JsonSerializable()
class ToolResult extends Equatable {
  final String id;
  final String toolName;
  final Map<String, dynamic> input;
  final String outputText;
  final int durationMs;
  final String status;
  final DateTime createdAt;

  const ToolResult({
    required this.id,
    required this.toolName,
    required this.input,
    required this.outputText,
    required this.durationMs,
    required this.status,
    required this.createdAt,
  });

  factory ToolResult.fromJson(Map<String, dynamic> json) =>
      _$ToolResultFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResultToJson(this);

  ToolResult copyWith({
    String? id,
    String? toolName,
    Map<String, dynamic>? input,
    String? outputText,
    int? durationMs,
    String? status,
    DateTime? createdAt,
  }) {
    return ToolResult(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      input: input ?? this.input,
      outputText: outputText ?? this.outputText,
      durationMs: durationMs ?? this.durationMs,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    toolName,
    input,
    outputText,
    durationMs,
    status,
    createdAt,
  ];
}

@JsonSerializable()
class SessionState extends Equatable {
  @JsonKey(fromJson: _sessionIdFromJson, toJson: _sessionIdToJson)
  final SessionID id;

  @JsonKey(
    fromJson: _sessionIdNullableFromJson,
    toJson: _sessionIdNullableToJson,
  )
  final SessionID? parentId;

  @Default('')
  final String title;

  @Default('general')
  final String agent;

  final String? modelRef;

  @Default(0.0)
  final double cost;

  @Default(0)
  final int tokensInput;

  @Default(0)
  final int tokensOutput;

  @Default(0)
  final int tokensReasoning;

  @Default(0)
  final int tokensCacheRead;

  @Default(0)
  final int tokensCacheWrite;

  @JsonKey(fromJson: _permissionFromJson, toJson: _permissionToJson)
  final PermissionRuleset? permission;

  @Default([])
  final List<SessionMessage> messages;

  @Default([])
  final List<ToolResult> toolResults;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @Default([])
  final List<AssistantContent> parts;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? archivedAt;

  const SessionState({
    required this.id,
    this.parentId,
    this.title = '',
    this.agent = 'general',
    this.modelRef,
    this.cost = 0.0,
    this.tokensInput = 0,
    this.tokensOutput = 0,
    this.tokensReasoning = 0,
    this.tokensCacheRead = 0,
    this.tokensCacheWrite = 0,
    this.permission,
    this.messages = const [],
    this.toolResults = const [],
    this.parts = const [],
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) =>
      _$SessionStateFromJson(json);

  Map<String, dynamic> toJson() => _$SessionStateToJson(this);

  SessionState copyWith({
    SessionID? id,
    SessionID? parentId,
    String? title,
    String? agent,
    String? modelRef,
    double? cost,
    int? tokensInput,
    int? tokensOutput,
    int? tokensReasoning,
    int? tokensCacheRead,
    int? tokensCacheWrite,
    PermissionRuleset? permission,
    List<SessionMessage>? messages,
    List<ToolResult>? toolResults,
    List<AssistantContent>? parts,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearParentId = false,
    bool clearModelRef = false,
    bool clearPermission = false,
    bool clearArchivedAt = false,
  }) {
    return SessionState(
      id: id ?? this.id,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      title: title ?? this.title,
      agent: agent ?? this.agent,
      modelRef: clearModelRef ? null : (modelRef ?? this.modelRef),
      cost: cost ?? this.cost,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      tokensReasoning: tokensReasoning ?? this.tokensReasoning,
      tokensCacheRead: tokensCacheRead ?? this.tokensCacheRead,
      tokensCacheWrite: tokensCacheWrite ?? this.tokensCacheWrite,
      permission: clearPermission ? null : (permission ?? this.permission),
      messages: messages ?? this.messages,
      toolResults: toolResults ?? this.toolResults,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }

  static SessionID? _sessionIdNullableFromJson(String? value) =>
      value == null ? null : SessionID.fromString(value);

  static String? _sessionIdNullableToJson(SessionID? value) => value?.value;

  static PermissionRuleset? _permissionFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rules = (json['rules'] as List?)
        ?.map(
          (e) => PermissionRule(
            permission: e['permission'] as String,
            pattern: e['pattern'] as String,
            action: PermissionAction.values.firstWhere(
              (a) => a.name == e['action'] as String,
              orElse: () => PermissionAction.ask,
            ),
          ),
        )
        .toList();
    final sessionApproved = (json['sessionApproved'] as List?)
        ?.map(
          (e) => PermissionRule(
            permission: e['permission'] as String,
            pattern: e['pattern'] as String,
            action: PermissionAction.values.firstWhere(
              (a) => a.name == e['action'] as String,
              orElse: () => PermissionAction.ask,
            ),
          ),
        )
        .toList();
    return PermissionRuleset(
      rules: rules ?? const [],
      sessionApproved: sessionApproved ?? const [],
    );
  }

  static Map<String, dynamic>? _permissionToJson(PermissionRuleset? pr) {
    if (pr == null) return null;
    if (pr.rules.isEmpty && pr.sessionApproved.isEmpty) return null;
    return {
      'rules': pr.rules
          .map(
            (r) => {
              'permission': r.permission,
              'pattern': r.pattern,
              'action': r.action.name,
            },
          )
          .toList(),
      'sessionApproved': pr.sessionApproved
          .map(
            (r) => {
              'permission': r.permission,
              'pattern': r.pattern,
              'action': r.action.name,
            },
          )
          .toList(),
    };
  }

  /// Raw string form for code that hasn't migrated to `SessionID` yet.
  String get sessionIdRaw => id.value;
  String? get parentIdRaw => parentId?.value;

  @override
  List<Object?> get props => [
    id,
    parentId,
    title,
    agent,
    modelRef,
    cost,
    tokensInput,
    tokensOutput,
    tokensReasoning,
    tokensCacheRead,
    tokensCacheWrite,
    permission,
    messages,
    toolResults,
    parts,
    createdAt,
    updatedAt,
    archivedAt,
  ];
}
