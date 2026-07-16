import 'dart:convert';
import 'dart:io';

import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:path/path.dart' as p;

/// Errors that can occur during config loading.
sealed class ConfigError implements Exception {
  const ConfigError();
}

class ConfigNotFound extends ConfigError {
  const ConfigNotFound();
}

class ConfigReadError extends ConfigError {
  final String path;
  final String original;

  const ConfigReadError({required this.path, required this.original});

  @override
  String toString() => 'ConfigReadError(path: $path, original: $original)';
}

class ConfigValidationError extends ConfigError {
  final String message;

  const ConfigValidationError(this.message);

  @override
  String toString() => 'ConfigValidationError(message: $message)';
}

/// Responsible for finding and merging `chatorai.json`.
///
/// Precedence (project overrides global, both are merged):
/// 1. `<xdg-config>/chatorai.json` — global user config (base layer)
/// 2. `./.chatorai/chatorai.json` — project-specific config (overlay, wins)
///
/// The two layers are deep-merged: keys present in the project config
/// override the global ones, while keys absent in the project config are
/// inherited from the global config. This mirrors the convention used by
/// tools like opencode (global base + project overlay with deep merge).
///
/// If neither file exists, an empty config object `{}` is returned.
class ConfigLoader {
  static Future<String> load() async {
    final global = await _loadLayer(await _globalConfigPath());
    final project = await _loadLayer(_projectConfigPath());

    // Project config is the overlay: its keys win over the global base.
    final merged = _deepMerge(global, project);
    return jsonEncode(merged);
  }

  static Future<String> _globalConfigPath() async {
    final configDir = await XdgPaths.configHomeAsync;
    return p.join(configDir, 'chatorai.json');
  }

  static String _projectConfigPath() => p.join('.chatorai', 'chatorai.json');

  /// Reads and decodes a single config file into a map.
  ///
  /// Returns an empty map when the file does not exist. Throws
  /// [ConfigReadError] on I/O failure and [ConfigValidationError] on
  /// malformed JSON so that broken configs surface loudly.
  static Future<Map<String, dynamic>> _loadLayer(String path) async {
    final file = File(path);
    if (!await file.exists()) return {};

    String raw;
    try {
      raw = await file.readAsString();
    } on IOException catch (e) {
      throw ConfigReadError(path: path, original: e.toString());
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('top-level JSON must be an object');
    } on FormatException catch (e) {
      throw ConfigValidationError('Malformed JSON in $path: ${e.message}');
    }
  }

  /// Recursively merges [overlay] into [base].
  ///
  /// Nested maps are merged key-by-key; every other value (scalars, lists)
  /// is taken from [overlay] when present, otherwise from [base]. Thus the
  /// overlay layer (project config) has precedence without discarding the
  /// base layer's (global config) unrelated keys.
  static Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> overlay,
  ) {
    final result = <String, dynamic>{};
    for (final entry in base.entries) {
      result[entry.key] = entry.value;
    }
    for (final entry in overlay.entries) {
      final baseValue = result[entry.key];
      if (baseValue is Map<String, dynamic> && entry.value is Map<String, dynamic>) {
        result[entry.key] = _deepMerge(baseValue, entry.value as Map<String, dynamic>);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
