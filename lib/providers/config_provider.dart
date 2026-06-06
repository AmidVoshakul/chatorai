import 'package:chatorai/config/config_manager.dart';
import 'package:chatorai/config/models/chatorai_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that loads and exposes [ChatOrAIConfig].
final configProvider = FutureProvider<ChatOrAIConfig>((ref) async {
  return await ConfigManager.loadConfig();
});
