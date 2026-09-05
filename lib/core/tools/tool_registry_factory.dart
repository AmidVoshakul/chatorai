import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/chat/services/chat_ai_service.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/lsp/lsp_service.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/file_snapshot_service.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/skills/skill_service.dart';
import 'package:chatorai/core/tools/built_in/built_in_tools.dart' as built_in;
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_registry.dart';

PermissionRuleset _buildToolsRules(Map<String, dynamic>? toolsConfig) {
  if (toolsConfig == null || toolsConfig.isEmpty) return PermissionRuleset();
  final rules = <PermissionRule>[];
  for (final entry in toolsConfig.entries) {
    final action = resolveToolAction(entry.value);
    if (action == null) continue;
    rules.add(
      PermissionRule(permission: entry.key, pattern: '*', action: action),
    );
  }
  return PermissionRuleset(rules: rules);
}

/// One shared assembly of the tool list for the app and the terminal.
///
/// Takes settings from `chatorai.json` plus ready services, returns
/// a filled registry. No screens and no Riverpod inside: the app
/// and the terminal call it with their own data in the same way.
Future<ToolRegistry> createToolRegistry(
  ChatOrAIConfig config, {
  required PermissionService permissions,
  SkillService? skillService,
  LspService? lspService,
  FileSnapshotService? fileSnapshotService,
  FormatService? formatService,
  ChatAiService? chatAiService,
  SessionRunnerHolder? sessionRunnerHolder,
  String? initialAgentId,
  List<ToolDef>? extraTools,
}) async {
  final defaults = PermissionRuleset.defaults();
  final permissionRules = config.permission.isNotEmpty
      ? PermissionRuleset(
          rules: [
            ...defaults.rules,
            ...PermissionRuleset.fromConfig(
              config.permission as Map<String, dynamic>,
            ),
          ],
        )
      : defaults;
  final globalToolsRules = _buildToolsRules(config.tools);
  final rules = PermissionRuleset(
    rules: [...permissionRules.rules, ...globalToolsRules.rules],
  );

  final registry = ToolRegistry(permissions, rules);

  await built_in.registerBuiltInTools(
    registry,
    chatAiService: chatAiService,
    toolRegistry: registry,
    skillService: skillService,
    lspService: lspService,
    fileSnapshotService: fileSnapshotService,
    formatService: formatService,
    formatterConfig: config.formatter,
    currentSessionRunner: sessionRunnerHolder,
  );

  if (extraTools != null) {
    for (final tool in extraTools) {
      registry.register(tool);
    }
  }

  if (initialAgentId != null) {
    final agent = AgentRegistry().get(initialAgentId);
    if (agent != null) {
      registry.agentRules = PermissionRuleset(rules: agent.permissions.rules);
    }
  }

  return registry;
}
