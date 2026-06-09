import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/features/tools/built_in/built_in_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tool_registry.dart';

final toolRegistryProvider = FutureProvider<ToolRegistry>((ref) async {
  final config = await ref.watch(configProvider.future);
  final rules = PermissionRuleset(
    rules: PermissionRuleset.fromConfig(config.permission),
  );
  final aiService = ref.read(chatAiServiceProvider);
  final registry = ToolRegistry(ref.read(permissionServiceProvider), rules);
  registerBuiltInTools(registry, chatAiService: aiService);
  return registry;
});
