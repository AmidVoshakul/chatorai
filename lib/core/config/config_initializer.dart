import 'dart:io';

import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

/// Ensures `chatorai.json` exists at first launch.
class ConfigInitializer {
  ConfigInitializer._();

  /// Searches for global user config in priority order:
  /// 1. `.chatorai/chatorai.json` — project-specific
  /// 2. `{configHome}/chatorai.json` — global user config
  ///
  /// Creates the file with default content if none is found.
  static Future<void> ensureGlobalConfig() async {
    await XdgPaths.init();

    final projectConfig = File(p.join('.chatorai', 'chatorai.json'));
    if (await projectConfig.exists()) {
      LogTags.settings.logDebug(
        '[ConfigInitializer] Project config already exists',
      );
      return;
    }

    final configDir = await XdgPaths.configHomeAsync;
    final configFile = File(p.join(configDir, 'chatorai.json'));
    if (!await configFile.exists()) {
      await XdgPaths.ensureDir(configDir);
      await configFile.writeAsString(_defaultConfig);
      LogTags.settings.logInfo(
        '[Config] Created default config at $configFile',
      );
    } else {
      LogTags.settings.logDebug(
        '[ConfigInitializer] Global config already exists',
      );
    }
  }

  static const String _defaultConfig = '''{
  "version": 1,
  "permission": {},
  "compaction": {
    "auto": true,
    "prune": false,
    "keep": {"tokens": 8000},
    "buffer": 20000
  }
}''';
}
