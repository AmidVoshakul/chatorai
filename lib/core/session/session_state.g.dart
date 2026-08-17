// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionMessage _$SessionMessageFromJson(Map<String, dynamic> json) =>
    SessionMessage(
      id: json['id'] as String,
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      content: json['content'] as String,
      seq: (json['seq'] as num).toInt(),
      model: json['model'] as String?,
      reasoning: json['reasoning'] as String?,
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompactionTrigger: json['isCompactionTrigger'] as bool? ?? false,
      isCompactionSummary: json['isCompactionSummary'] as bool? ?? false,
      agent: json['agent'] as String?,
      tokensInput: (json['tokensInput'] as num?)?.toInt(),
      tokensOutput: (json['tokensOutput'] as num?)?.toInt(),
      tokensReasoning: (json['tokensReasoning'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SessionMessageToJson(SessionMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'seq': instance.seq,
      'model': instance.model,
      'reasoning': instance.reasoning,
      'error': instance.error,
      'createdAt': instance.createdAt.toIso8601String(),
      'isCompactionTrigger': instance.isCompactionTrigger,
      'isCompactionSummary': instance.isCompactionSummary,
      'agent': instance.agent,
      'tokensInput': instance.tokensInput,
      'tokensOutput': instance.tokensOutput,
      'tokensReasoning': instance.tokensReasoning,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
  MessageRole.tool: 'tool',
};

ToolResult _$ToolResultFromJson(Map<String, dynamic> json) => ToolResult(
  id: json['id'] as String,
  toolName: json['toolName'] as String,
  input: json['input'] as Map<String, dynamic>,
  outputText: json['outputText'] as String,
  durationMs: (json['durationMs'] as num).toInt(),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ToolResultToJson(ToolResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'toolName': instance.toolName,
      'input': instance.input,
      'outputText': instance.outputText,
      'durationMs': instance.durationMs,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };

SessionState _$SessionStateFromJson(Map<String, dynamic> json) => SessionState(
  id: _sessionIdFromJson(json['id'] as String),
  parentId: SessionState._sessionIdNullableFromJson(
    json['parentId'] as String?,
  ),
  title: json['title'] as String? ?? '',
  agent: json['agent'] as String? ?? 'general',
  modelRef: json['modelRef'] as String?,
  cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
  tokensInput: (json['tokensInput'] as num?)?.toInt() ?? 0,
  tokensOutput: (json['tokensOutput'] as num?)?.toInt() ?? 0,
  tokensReasoning: (json['tokensReasoning'] as num?)?.toInt() ?? 0,
  tokensCacheRead: (json['tokensCacheRead'] as num?)?.toInt() ?? 0,
  tokensCacheWrite: (json['tokensCacheWrite'] as num?)?.toInt() ?? 0,
  permission: SessionState._permissionFromJson(
    json['permission'] as Map<String, dynamic>?,
  ),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => SessionMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  toolResults:
      (json['toolResults'] as List<dynamic>?)
          ?.map((e) => ToolResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  compactedContext: (json['compactedContext'] as List<dynamic>?)
      ?.map((e) => SessionMessage.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
);

Map<String, dynamic> _$SessionStateToJson(SessionState instance) =>
    <String, dynamic>{
      'id': _sessionIdToJson(instance.id),
      'parentId': SessionState._sessionIdNullableToJson(instance.parentId),
      'title': instance.title,
      'agent': instance.agent,
      'modelRef': instance.modelRef,
      'cost': instance.cost,
      'tokensInput': instance.tokensInput,
      'tokensOutput': instance.tokensOutput,
      'tokensReasoning': instance.tokensReasoning,
      'tokensCacheRead': instance.tokensCacheRead,
      'tokensCacheWrite': instance.tokensCacheWrite,
      'permission': SessionState._permissionToJson(instance.permission),
      'messages': instance.messages,
      'toolResults': instance.toolResults,
      'compactedContext': instance.compactedContext,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'archivedAt': instance.archivedAt?.toIso8601String(),
    };
