import 'dart:io';

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

/// Responsible for finding and reading `chatorai.json`.
///
/// Search order:
/// 1. `~/.config/chatorai/chatorai.json`
/// 2. `./chatorai.json` (project root)
/// 3. Fallback: empty config object `{}`
class ConfigLoader {
  static Future<String> load() async {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final userConfig = File('$home/.config/chatorai/chatorai.json');
      if (await userConfig.exists()) {
        try {
          return await userConfig.readAsString();
        } on IOException catch (e) {
          throw ConfigReadError(path: userConfig.path, original: e.toString());
        }
      }
    }

    final projectConfig = File('chatorai.json');
    if (await projectConfig.exists()) {
      try {
        return await projectConfig.readAsString();
      } on IOException catch (e) {
        throw ConfigReadError(path: projectConfig.path, original: e.toString());
      }
    }

    // Fallback: empty config
    return '{}';
  }
}
