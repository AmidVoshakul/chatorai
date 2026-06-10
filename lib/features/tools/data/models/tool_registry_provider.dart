import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/tools/built_in/built_in_tools.dart'
    as built_in;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/skills/presentation/providers/skill_providers.dart';
import 'package:chatorai/features/skills/built_in/skill_tool.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';

final toolRegistryProvider = FutureProvider<ToolRegistry>((ref) async {
  final config = await ref.watch(configProvider.future);
  // Use default rules if config does not provide any permission rules
  final rules = config.permission.isNotEmpty
      ? PermissionRuleset(
          rules: PermissionRuleset.fromConfig(config.permission),
        )
      : PermissionRuleset.defaults();
  final aiService = ref.read(chatAiServiceProvider);
  final skillService = await ref.read(skillServiceProvider.future);
  final registry = ToolRegistry(ref.read(permissionServiceProvider), rules);
  built_in.registerBuiltInTools(
    registry,
    chatAiService: aiService,
    skillService: skillService,
  );
  // Fetch all skills for dynamic tool description
  final allSkills = await skillService.listAll();
  registry.register(createSkillTool(skillService, allSkills));
  return registry;
});
