import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;

class SchemaValidationError {
  final String path;
  final String message;
  final String? schemaPath;

  const SchemaValidationError({
    required this.path,
    required this.message,
    this.schemaPath,
  });

  @override
  String toString() {
    final parts = ['$path: $message'];
    if (schemaPath != null) parts.add('(schema: $schemaPath)');
    return parts.join(' ');
  }
}

class ToolContext {
  final String? agentId;
  final String toolCallId;
  final sdk.CancellationToken? abortSignal;
  final String? sessionId;
  final PermissionRuleset? permissionRuleset;

  final Future<void> Function({
    required String permission,
    required List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  })
  ask;

  final Future<String> Function({
    required String question,
    List<QuestionOption> options,
    bool multiple,
  })
  askQuestion;

  final void Function({String? title, Map<String, dynamic>? metadata})?
  onMetadata;

  final void Function(String agentId, {String? messageText})? switchAgent;

  bool hasPermission(String permission, String pattern) {
    return permissionRuleset?.isAllowed(permission, pattern) ?? false;
  }

  const ToolContext({
    this.agentId,
    required this.toolCallId,
    this.abortSignal,
    this.sessionId,
    this.permissionRuleset,
    required this.ask,
    required this.askQuestion,
    this.onMetadata,
    this.switchAgent,
  });
}

class ToolOutput {
  final String output;
  final Map<String, dynamic>? metadata;
  final String? title;

  const ToolOutput(this.output, {this.metadata, this.title});

  Map<String, dynamic> toJson() => {
    'output': output,
    if (title != null) 'title': title,
    if (metadata != null) 'metadata': metadata,
  };
}

class ToolDef {
  final String id;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<ToolOutput> Function(Map<String, dynamic> input, ToolContext ctx)
  execute;
  final String Function(
    Map<String, dynamic> input,
    List<SchemaValidationError> errors,
  )?
  formatValidationError;
  final bool skipValidation;

  const ToolDef({
    required this.id,
    required this.description,
    required this.inputSchema,
    required this.execute,
    this.formatValidationError,
    this.skipValidation = false,
  });
}
