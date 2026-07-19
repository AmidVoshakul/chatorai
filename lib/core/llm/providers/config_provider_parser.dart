import 'dart:io';

import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/llm/models/auth_config.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:path/path.dart' as p;

/// Maps the declarative `provider` section of `chatorai.json` into runtime
/// [ProviderConfig] objects (all treated as OpenAI-compatible).
///
/// Config providers are read-only: they are applied on top of the built-in
/// catalog at startup and never written back to SharedPreferences/SecureStorage.
///
/// The `apiKey` field supports three forms:
///   * a literal key string — used as-is,
///   * `"{env:VAR}"` — resolved from the process environment, falling back to
///     shell rc files (`~/.bashrc`, `~/.zshrc`, `~/.profile`) on desktop so the
///     key is found even when the app is launched from a GUI launcher,
///   * the literal `"public"` — a key-less provider ([AuthConfig.none]).
class ConfigProviderParser {
  const ConfigProviderParser({this.environment = const {}, this.homeDirectory});

  /// Override environment map (mainly for tests). When empty, falls back to
  /// [Platform.environment].
  final Map<String, String> environment;

  /// Override for the user home directory (mainly for tests). When `null`, the
  /// home is resolved from the `HOME`/`USERPROFILE` environment variable.
  final String? homeDirectory;

  static final RegExp _envPattern = RegExp(r'^\{env:([^}]+)\}$');
  static const List<String> _rcFiles = ['.bashrc', '.zshrc', '.profile'];

  /// Parses every provider entry into a [ProviderConfig].
  ///
  /// A config provider with the same ID as a built-in provider overrides it
  /// (the user config wins). chatorai always uses the OpenAI-compatible SDK
  /// for config providers.
  List<ProviderConfig> parse(ProviderSectionConfig? section) {
    if (section == null) return const [];
    final result = <ProviderConfig>[];
    for (final entry in section.providers.entries) {
      result.add(_parseEntry(entry.key, entry.value));
    }
    return result;
  }

  ProviderConfig _parseEntry(String id, ProviderEntryConfig entry) {
    final auth = _resolveAuth(entry.options?.apiKey);
    final baseUrl = entry.options?.baseURL ?? 'https://api.openai.com/v1';

    final models = entry.models.entries.map((m) {
      final limit = m.value.limit;
      return ModelConfig.basic(
        providerId: id,
        modelName: m.key,
        displayName: m.value.name ?? m.key,
        contextLength: limit?.context ?? 0,
        defaultMaxTokens: limit?.output,
        enabled: true,
      );
    }).toList();

    // extra options + temperature are forwarded as default model-call
    // parameters (merged into providerOptions at call time). The explicit
    // `temperature` is spread last so it always wins over a `temperature`
    // entry that may have landed in `extra` via programmatic construction.
    final defaultBody = <String, dynamic>{
      ...entry.options?.extra ?? {},
      if (entry.options?.temperature != null)
        'temperature': entry.options!.temperature,
    };

    return ProviderConfig.full(
      id: id,
      name: entry.name ?? id,
      baseUrl: baseUrl,
      auth: auth,
      sdk: 'openai-compatible',
      models: models,
      enabled: true,
      defaultBody: defaultBody.isEmpty ? null : defaultBody,
      source: ProviderSource.config,
    );
  }

  /// Resolves the `apiKey` field into an [AuthConfig].
  AuthConfig _resolveAuth(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return const AuthConfig.none();
    if (apiKey == 'public') return const AuthConfig.none();

    final envMatch = _envPattern.firstMatch(apiKey);
    if (envMatch != null) {
      final name = envMatch.group(1)!;
      final value = _resolveEnv(name);
      if (value != null && value.isNotEmpty) {
        return AuthConfig.apiKey(apiKey: value);
      }
      return const AuthConfig.none();
    }

    // Plain literal key.
    return AuthConfig.apiKey(apiKey: apiKey);
  }

  /// Resolves an environment variable, trying the process environment first and
  /// falling back to shell rc files on desktop platforms. Returns null if unset.
  String? _resolveEnv(String name) {
    final env = environment.isNotEmpty ? environment : Platform.environment;
    final direct = env[name];
    if (direct != null && direct.isNotEmpty) return direct;

    if (!_isDesktop) return null;
    return _readFromRcFiles(name);
  }

  bool get _isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  /// Reads `VAR` from shell rc files. Supports both `export VAR="value"` and
  /// `VAR=value` forms. Best-effort: any read/parse error yields null. The
  /// variable name is regex-escaped to avoid injection from unusual names.
  /// Escaped inner quotes (e.g. `"a \"b\""`) are not unescaped — this is a
  /// best-effort parser, not a full shell interpreter.
  String? _readFromRcFiles(String name) {
    final home =
        homeDirectory ??
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];
    if (home == null) return null;
    final escaped = RegExp.escape(name);
    final patterns = [
      RegExp(r'^[ \t]*export[ \t]+' + escaped + r'=([^\n]*)', multiLine: true),
      RegExp(r'^[ \t]*' + escaped + r'=([^\n]*)', multiLine: true),
    ];
    for (final rc in _rcFiles) {
      final file = File(p.join(home, rc));
      if (!file.existsSync()) continue;
      try {
        final content = file.readAsStringSync();
        for (final pattern in patterns) {
          final match = pattern.firstMatch(content);
          if (match != null) {
            return _stripQuotes(match.group(1)!);
          }
        }
      } catch (_) {
        // Ignore unreadable rc files.
      }
    }
    return null;
  }

  String _stripQuotes(String value) {
    final v = value.trim();
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      return v.substring(1, v.length - 1);
    }
    return v;
  }
}
