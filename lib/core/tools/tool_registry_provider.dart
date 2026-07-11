import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/lsp/lsp_provider.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/skills/skill_providers.dart';
import 'package:chatorai/core/tools/built_in/built_in_tools.dart' as built_in;
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final toolRegistryProvider = FutureProvider<ToolRegistry>((ref) async {
  final config = await ref.watch(configProvider.future);

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
  final aiService = ref.read(chatAiServiceProvider);
  final skillService = await ref.read(skillServiceProvider.future);
  final lspService = await ref.watch(lspServiceProvider.future);
  final registry = ToolRegistry(ref.read(permissionServiceProvider), rules);

  final holder = SessionRunnerHolder(null, parentSessionId: null);
  ref.read(currentSessionRunnerProvider.notifier).bindHolder(holder);

  await built_in.registerBuiltInTools(
    registry,
    chatAiService: aiService,
    toolRegistry: registry,
    skillService: skillService,
    lspService: lspService,
    formatService: FormatService.instance,
    formatterConfig: config.formatter,
    currentSessionRunner: holder,
  );

  void applyAgentRules(AgentDefinition agent) {
    registry.agentRules = PermissionRuleset(rules: agent.permissions.rules);
  }

  final initialAgent = ref.read(currentAgentProvider);
  applyAgentRules(initialAgent);

  ref.listen<AgentDefinition>(currentAgentProvider, (previous, next) {
    if (previous != next) {
      applyAgentRules(next);
    }
  });

  registry.switchAgent = (agentId, {String? messageText}) async {
    final agent = AgentRegistry().get(agentId);
    if (agent == null) return;
    final notifier = ref.read(currentAgentProvider.notifier);
    notifier.setAgent(agent);

    final currentChatId = ref.read(currentChatIdProvider);
    if (currentChatId != null && messageText != null) {
      final chatStorage = ref.read(chatStorageServiceProvider);
      final chat = await chatStorage.getChat(currentChatId);
      if (chat != null) {
        final syntheticMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.user,
          content: messageText,
          timestamp: DateTime.now(),
          isComplete: true,
          synthetic: true,
        );
        await chatStorage.addMessageToChat(currentChatId, syntheticMessage);
        final freshChat = await chatStorage.getChat(currentChatId);
        if (freshChat != null) {
          ref.read(chatListProvider.notifier).updateChat(freshChat);
        }
      }
    }
  };

  // Initialize MCP and register discovered tools
  if (config.mcp != null && config.mcp!.servers.isNotEmpty) {
    await McpClientService.instance.initialize(config.mcp!);
    final mcpToolDefs = await McpClientService.instance.getToolDefs();
    for (final toolDef in mcpToolDefs) {
      registry.register(toolDef);
    }
  }

  return registry;
});
