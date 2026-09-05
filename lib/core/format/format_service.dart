import 'dart:io';
import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/format/built_in_formatters.dart';
import 'package:chatorai/core/format/formatter_definition.dart';
import 'package:chatorai/core/workspace/workspace_runtime.dart';

class FormatResult {
  final String? originalContent;
  final String formattedContent;
  final String formatter;
  final bool changed;
  final String? error;

  FormatResult({
    this.originalContent,
    required this.formattedContent,
    required this.formatter,
    this.changed = false,
    this.error,
  });
}

class FormatService {
  static final FormatService instance = FormatService._internal();
  factory FormatService() => instance;
  FormatService._internal();

  Future<FormatResult> formatFile(
    String filePath, {
    String? preferredFormatter,
    FormatterConfig? formatterConfig,
  }) async {
    final ext = _ext(filePath);
    final rawOverrides = <String, FormatterEntryConfig>{};
    if (formatterConfig != null) {
      rawOverrides.addAll(formatterConfig.formatters);
    }

    final disabled = _linkedDisabled(rawOverrides);

    final candidates = <String>[];
    if (preferredFormatter != null && !disabled.contains(preferredFormatter)) {
      candidates.add(preferredFormatter);
    }
    for (final entry in builtInFormatters.entries) {
      if (!candidates.contains(entry.key) &&
          !disabled.contains(entry.key) &&
          entry.value.extensions.contains(ext)) {
        candidates.add(entry.key);
      }
    }

    String content;
    try {
      content = await File(filePath).readAsString();
    } catch (e) {
      return FormatResult(
        formattedContent: '',
        formatter: preferredFormatter ?? 'unknown',
        error: 'Cannot read file: $e',
      );
    }

    for (final name in candidates) {
      final def = builtInFormatters[name];
      if (def == null) continue;

      final override = rawOverrides[name];
      final resolvedDef = _applyOverride(def, override);
      final resolvedExts = override?.extensions ?? def.extensions;
      if (!resolvedExts.contains(ext)) continue;

      final projectRoot = _findProjectRoot(filePath);
      final ctx = FormatContext(
        filePath: filePath,
        projectRoot: projectRoot,
        config: formatterConfig?.toJson() ?? {},
      );

      List<String>? cmd;
      if (override?.command != null && override!.command!.isNotEmpty) {
        cmd = List<String>.from(override.command!);
      } else {
        final enabledResult = await resolvedDef.enabled(ctx);
        cmd = enabledResult;
      }
      if (cmd == null || cmd.isEmpty) continue;

      final substituted = _substituteFile(cmd, filePath);
      final env = <String, String>{
        ...?resolvedDef.environment,
        if (override?.environment != null) ...override!.environment!,
      };

      final result = await _runProcess(substituted, environment: env);
      if (result.exitCode != 0) continue;

      final formatted = result.stdout;
      final changed = formatted != content;

      return FormatResult(
        originalContent: content,
        formattedContent: formatted,
        formatter: name,
        changed: changed,
      );
    }

    return FormatResult(
      originalContent: content,
      formattedContent: content,
      formatter: 'none',
      error: 'No suitable formatter found for $filePath',
    );
  }

  Future<String> applyFix(
    String filePath, {
    FormatterConfig? formatterConfig,
  }) async {
    final result = await formatFile(filePath, formatterConfig: formatterConfig);
    if (result.error != null) {
      throw Exception(result.error);
    }
    if (!result.changed) return filePath;

    await File(filePath).writeAsString(result.formattedContent);
    return filePath;
  }

  List<Map<String, dynamic>> status(FormatterConfig? formatterConfig) {
    final rawOverrides = <String, FormatterEntryConfig>{};
    if (formatterConfig != null) {
      rawOverrides.addAll(formatterConfig.formatters);
    }
    final disabled = _linkedDisabled(rawOverrides);

    return builtInFormatters.values.map((def) {
      final override = rawOverrides[def.name];
      final extensions = override?.extensions ?? def.extensions;
      final enabledByConfig = override?.disabled == true;
      return {
        'name': def.name,
        'extensions': extensions,
        'enabled': !disabled.contains(def.name) && !enabledByConfig,
        'disabledByConfig': override?.disabled == true,
        'overridden': override != null,
      };
    }).toList();
  }

  static Set<String> _linkedDisabled(
    Map<String, FormatterEntryConfig> overrides,
  ) {
    final disabled = <String>{};
    for (final entry in overrides.entries) {
      if (entry.value.disabled == true) {
        disabled.add(entry.key);
      }
    }
    if (disabled.contains('ruff') && !disabled.contains('uv')) {
      disabled.add('uv');
    }
    if (disabled.contains('uv') && !disabled.contains('ruff')) {
      disabled.add('ruff');
    }
    return disabled;
  }

  static FormatterDefinition _applyOverride(
    FormatterDefinition def,
    FormatterEntryConfig? override,
  ) {
    if (override == null) return def;
    if (override.command != null && override.command!.isNotEmpty) {
      return FormatterDefinition(
        name: def.name,
        extensions: override.extensions ?? def.extensions,
        environment: override.environment ?? def.environment,
        enabled: (_) async => override.command,
      );
    }
    if (override.extensions != null) {
      return FormatterDefinition(
        name: def.name,
        extensions: override.extensions!,
        environment: override.environment ?? def.environment,
        enabled: def.enabled,
      );
    }
    return def;
  }

  Future<ProcessResult> _runProcess(
    List<String> command, {
    Map<String, String>? environment,
  }) async {
    final exec = command.first;
    final args = command.skip(1).toList();
    return await Process.run(
      exec,
      args,
      environment: environment,
      workingDirectory: workspaceRuntimeCurrent.path,
      runInShell: Platform.isWindows,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        return ProcessResult(-1, -1, '', 'Timeout after 30s');
      },
    );
  }

  static String _ext(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '';
  }

  static String _findProjectRoot(String startDir) {
    var current = startDir;
    while (true) {
      if (File('$current/.git').existsSync()) return current;
      final parent = Directory(current).parent.path;
      if (parent == current) return current;
      current = parent;
    }
  }

  static List<String> _substituteFile(List<String> cmd, String filePath) {
    return cmd.map((part) => part.replaceAll('\$FILE', filePath)).toList();
  }
}
