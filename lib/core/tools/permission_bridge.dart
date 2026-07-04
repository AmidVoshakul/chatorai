import 'package:ai_sdk_dart/ai_sdk_dart.dart' as sdk;
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_permission.dart';
import 'package:chatorai/shared/utils/logger.dart';

class PermissionBridge {
  final PermissionService permissions;
  final PermissionRuleset defaultRules;
  final String? sessionId;

  PermissionBridge(this.permissions, this.defaultRules, this.sessionId);

  ToolContext createContext({
    required String toolId,
    required String toolCallId,
    sdk.CancellationToken? abortSignal,
  }) {
    return ToolContext(
      toolCallId: toolCallId,
      sessionId: sessionId,
      abortSignal: abortSignal,
      ask:
          ({
            required String permission,
            required List<String> patterns,
            Map<String, dynamic>? metadata,
            List<String>? always,
          }) async =>
              _ask(toolId, toolCallId, permission, patterns, metadata, always),
      askQuestion:
          ({
            required String question,
            List<String> options = const [],
            bool multiple = false,
          }) async =>
              _askQuestion(toolId, toolCallId, question, options, multiple),
    );
  }

  Future<void> apply(ToolPermissionRule rule) async {
    final reqMetadata = <String, dynamic>{};
    if (sessionId != null) reqMetadata['sessionId'] = sessionId;
    await permissions.ask(
      PermissionRequest(
        id: 'req_${DateTime.now().microsecondsSinceEpoch}',
        toolName: rule.action,
        permission: rule.action,
        patterns: rule.patterns,
        metadata: reqMetadata,
        always: rule.save,
      ),
      PermissionRuleset(
        rules: [...defaultRules.rules],
        sessionApproved: permissions.approvedRules,
      ),
    );
  }

  Future<void> _ask(
    String toolId,
    String toolCallId,
    String permission,
    List<String> patterns,
    Map<String, dynamic>? metadata,
    List<String>? always,
  ) async {
    final reqMetadata = Map<String, dynamic>.from(metadata ?? {});
    if (sessionId != null) reqMetadata['sessionId'] = sessionId;
    await permissions.ask(
      PermissionRequest(
        id: 'req_${DateTime.now().microsecondsSinceEpoch}_$toolId',
        toolName: toolId,
        permission: permission,
        patterns: patterns,
        metadata: reqMetadata,
        always: always ?? [],
      ),
      PermissionRuleset(
        rules: [...defaultRules.rules],
        sessionApproved: permissions.approvedRules,
      ),
    );
  }

  Future<String> _askQuestion(
    String toolId,
    String toolCallId,
    String question,
    List<String> options,
    bool multiple,
  ) async {
    LogTags.permission.logInfo(
      'PermissionBridge._askQuestion: START question="$question", options=$options',
    );

    await permissions.ask(
      PermissionRequest(
        id: 'question_perm_${DateTime.now().microsecondsSinceEpoch}',
        toolName: 'question',
        permission: 'question',
        patterns: ['*'],
        metadata: {
          if (sessionId != null) 'sessionId': sessionId,
          'question': question,
        },
      ),
      PermissionRuleset(
        rules: [...defaultRules.rules],
        sessionApproved: permissions.approvedRules,
      ),
    );

    LogTags.permission.logInfo(
      'PermissionBridge._askQuestion: Permission granted, proceeding with question',
    );

    final id = 'question_${DateTime.now().microsecondsSinceEpoch}';
    LogTags.permission.logInfo(
      'PermissionBridge._askQuestion: id=$id, question="$question", options=$options',
    );
    return permissions.askQuestion(
      id: id,
      question: question,
      options: options,
      multiple: multiple,
    );
  }
}
