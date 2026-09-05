import 'package:chatorai/core/workspace/process_workspace_port.dart';
import 'package:chatorai/core/workspace/workspace_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config_manager.dart';
import 'instructions_resolver.dart';
import 'models/chatorai_config.dart';

/// Which project folder is current. The app overrides this with the
/// folder list screen value; the terminal keeps the process default.
final workspacePortProvider = Provider<WorkspacePort>((ref) {
  return ProcessWorkspacePort();
});

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
  // The project root comes from the shared workspace rule, so the app
  // (folder list screen) and the terminal (launch folder) resolve the
  // same project config. Auto-discovery (AGENTS.md walk-up) and relative
  // `instructions[]` entries resolve from it.
  final workspace = ref.watch(workspacePortProvider);
  InstructionsCache.instance.setRaw(
    config.instructions,
    cwd: workspace.directory,
  );
  return InstructionsCache.instance.resolved;
});
