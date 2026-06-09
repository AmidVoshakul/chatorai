import 'config_manager.dart';
import 'models/chatorai_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that loads and exposes [ChatOrAIConfig].
final configProvider = FutureProvider<ChatOrAIConfig>((ref) async {
  return await ConfigManager.loadConfig();
});
