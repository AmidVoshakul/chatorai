import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/tools/built_in/built_in_tools.dart'
    as built_in;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/skills/presentation/providers/skill_providers.dart';
import 'package:chatorai/features/tools/data/models/tool_registry.dart';

final toolRegistryProvider = FutureProvider<ToolRegistry>((ref) async {
  final config = await ref.watch(configProvider.future);
  // Use default rules if config does not provide any permission rules
  final rules = config.permission.isNotEmpty
      ? PermissionRuleset(
          rules: PermissionRuleset.fromConfig(
            config.permission as Map<String, dynamic>,
          ),
        )
      : PermissionRuleset.defaults();
  final aiService = ref.read(chatAiServiceProvider);
  final skillService = await ref.read(skillServiceProvider.future);
  final registry = ToolRegistry(ref.read(permissionServiceProvider), rules);
  await built_in.registerBuiltInTools(
    registry,
    chatAiService: aiService,
    toolRegistry: registry,
    skillService: skillService,
  );
  return registry;
});
