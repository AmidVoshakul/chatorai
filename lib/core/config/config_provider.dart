import 'config_manager.dart';
import 'instructions_resolver.dart';
import 'models/chatorai_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/shared/workspace/workspace_runtime.dart';

/// Riverpod provider that loads and exposes [ChatOrAIConfig].
final configProvider = FutureProvider<ChatOrAIConfig>((ref) async {
  return await ConfigManager.loadConfig();
});

/// Riverpod provider that exposes [CompactionConfig] from the loaded config,
/// falling back to defaults when the `compaction` section is absent.
final compactionConfigProvider = Provider<CompactionConfig>((ref) {
  final config = ref.watch(configProvider).value;
  return config?.compaction ?? const CompactionConfig();
});

/// Resolves `instructions` entries from the loaded config into system-prompt
/// blocks (`Instructions from: <path>\n<content>`). Resolution is memoized in
/// [InstructionsCache] so the (potentially I/O-heavy) work happens once and is
/// shared with non-UI consumers (e.g. the task tool).
final resolvedInstructionsProvider = FutureProvider<List<String>>((ref) async {
  final config = await ref.watch(configProvider.future);
  // The project root is always the process working directory, matching the
  // config loader and the built-in tools. Auto-discovery (AGENTS.md walk-up)
  // and relative `instructions[]` entries resolve from it.
  InstructionsCache.instance.setRaw(
    config.instructions,
    cwd: workspaceRuntimeCurrent,
  );
  return InstructionsCache.instance.resolved;
});
