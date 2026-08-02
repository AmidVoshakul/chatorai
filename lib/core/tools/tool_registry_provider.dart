import 'dart:async';

import 'package:chatorai/core/agents/agent_provider.dart';
import 'package:chatorai/core/agents/agent_registry.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/lsp/lsp_provider.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
import 'package:chatorai/core/session/session_id.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/skills/skill_providers.dart';
import 'package:chatorai/core/tools/built_in/built_in_tools.dart' as built_in;
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:chatorai/shared/utils/logger.dart';
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
  final fileSnapshotService = await ref.watch(
    fileSnapshotServiceProvider.future,
  );
  final registry = ToolRegistry(ref.read(permissionServiceProvider), rules);

  final holder = SessionRunnerHolder(null, parentSessionId: null);
  ref.read(currentSessionRunnerProvider.notifier).bindHolder(holder);

  await built_in.registerBuiltInTools(
    registry,
    chatAiService: aiService,
    toolRegistry: registry,
    skillService: skillService,
    lspService: lspService,
    fileSnapshotService: fileSnapshotService,
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
      final sessionRepository = await ref.read(
        sessionRepositoryProvider.future,
      );
      final sessionId = SessionID.fromString(
        currentChatId.startsWith('ses_') ? currentChatId : 'ses_$currentChatId',
      );
      final syntheticMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: messageText,
        timestamp: DateTime.now(),
        isComplete: true,
        synthetic: true,
      );
      await sessionRepository.appendEvent(
        MessageAdded(
          sessionId: sessionId,
          messageId: syntheticMessage.id,
          role: syntheticMessage.role.name,
          content: syntheticMessage.content,
          timestamp: syntheticMessage.timestamp,
        ),
      );
      final state = await sessionRepository.loadSession(sessionId);
      if (state != null) {
        final chat = Chat(
          id: currentChatId,
          title: state.title,
          messages: state.messages
              .map(
                (m) => Message(
                  id: m.id,
                  role: MessageRole.values[m.role.index],
                  content: m.content,
                  timestamp: m.createdAt,
                  model: m.model,
                  reasoning: m.reasoning,
                  isComplete: true,
                  isError: m.error != null && m.error!.isNotEmpty,
                ),
              )
              .toList(),
          createdAt: state.createdAt,
          updatedAt: state.updatedAt,
        );
        ref.read(chatListProvider.notifier).updateChat(chat);
      }
    }
  };

  // Initialize MCP in background without blocking tool registry availability.
  if (config.mcp != null && config.mcp!.servers.isNotEmpty) {
    ref.onDispose(() {
      McpClientService.instance.dispose();
    });
    unawaited(_initializeMcpTools(config, registry));
  }

  return registry;
});

Future<void> _initializeMcpTools(
  ChatOrAIConfig config,
  ToolRegistry registry,
) async {
  try {
    await McpClientService.instance.initialize(config.mcp!);
    final mcpToolDefs = await McpClientService.instance.getToolDefs();
    for (final toolDef in mcpToolDefs) {
      registry.register(toolDef);
    }
  } on Object catch (e) {
    LogTags.chatService.logWarning('MCP initialization failed: $e');
  }
}
