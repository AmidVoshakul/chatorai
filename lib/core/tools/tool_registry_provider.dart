import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/lsp/lsp_provider.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/session/session_runner.dart';
import 'package:chatorai/core/skills/skill_providers.dart';
import 'package:chatorai/core/tools/built_in/built_in_tools.dart' as built_in;
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/sessions/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final toolRegistryProvider = FutureProvider<ToolRegistry>((ref) async {
  final config = await ref.watch(configProvider.future);

  final defaults = PermissionRuleset.defaults();
  final rules = config.permission.isNotEmpty
      ? PermissionRuleset(
          rules: [
            ...defaults.rules,
            ...PermissionRuleset.fromConfig(
              config.permission as Map<String, dynamic>,
            ),
          ],
        )
      : defaults;
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
