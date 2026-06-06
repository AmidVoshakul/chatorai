import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/permissions/permission_provider.dart';
import 'package:chatorai/permissions/ruleset.dart';
import 'package:chatorai/providers/config_provider.dart';
import 'package:chatorai/providers/chat/chat_providers.dart';
import 'tool_registry.dart';
import 'built_in/built_in_tools.dart';

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
