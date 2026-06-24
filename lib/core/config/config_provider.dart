import 'config_manager.dart';
import 'models/chatorai_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
