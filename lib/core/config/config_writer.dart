import 'dart:convert';
import 'dart:io';

import 'package:chatorai/core/config/chatorai_schema.dart';
import 'package:chatorai/core/config/config_loader.dart';
import 'package:chatorai/core/config/file_lock_service.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

/// Writes user configuration back to a `chatorai.json` file.
///
/// Unlike [ConfigLoader] (which only reads + deep-merges the global and
/// project layers), this writer mutates a **single concrete file** so the
/// project overlay semantics are preserved: a write to the project file wins
/// over the global one at read time.
///
/// Validation mirrors [ConfigManager]: every write is checked against
/// [chatoraiSchema] before being committed. On validation failure the original
/// file content is restored and a [ConfigValidationError] is thrown, so a bad
/// edit can never leave `chatorai.json` in a broken state.
class ConfigWriter {
  const ConfigWriter._();

  /// Path of the config file for the given [global]/project scope.
  ///
  /// - global: `<configHome>/chatorai.json`
  /// - project: `<workspaceRuntimeCurrent.path>/.chatorai/chatorai.json`
  static Future<String> resolveConfigPath({
    required bool global,
    Directory? projectRoot,
  }) async {
    return ConfigLoader.resolveConfigPath(
      global: global,
      projectRoot: projectRoot,
    );
  }

  /// Reads the raw JSON map from [path], or `{}` when the file is absent.
  static Future<Map<String, dynamic>> readRawConfig(String path) async {
    final file = File(path);
    if (!await file.exists()) return {};

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return {};

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('top-level JSON must be an object');
    } on FormatException catch (e) {
      throw ConfigValidationError('Malformed JSON in $path: ${e.message}');
    }
  }

  /// Validates [data] before it is written to disk.
  ///
  /// Combines a targeted structural check of the `mcp` section (which the
  /// `json_schema` package does not reliably enforce for nested
  /// `additionalProperties`) with a best-effort schema validation. Either
  /// failure throws [ConfigValidationError] with a readable message.
  static void _validate(Map<String, dynamic> data) {
    _validateMcpStructure(data);

    try {
      final schema = JsonSchema.create(
        chatoraiSchema,
        schemaVersion: SchemaVersion.draft2020_12,
      );
      final result = schema.validate(data);
      if (!result.isValid && result.errors.isNotEmpty) {
        throw ConfigValidationError(result.errors.first.toString());
      }
    } on ConfigValidationError {
      rethrow;
    } catch (_) {
      // json_schema engine errors defer to the structural check above.
    }
  }

  /// Structural check of the `mcp` section.
  ///
  /// Guarantees that every declared server has a known [McpServerType] and the
  /// fields required for that type, so a typo can never produce a config that
  /// [McpClientService] would choke on at startup.
  ///
  /// Servers may live either under `mcp.servers` or directly under `mcp`
  /// (flat layout); both are validated.
  static void _validateMcpStructure(Map<String, dynamic> data) {
    final mcp = data['mcp'];
    if (mcp == null) return;
    if (mcp is! Map<String, dynamic>) {
      throw ConfigValidationError('"mcp" must be an object');
    }
    // Collect every server object, whether nested under "servers" or flat.
    final servers = <String, dynamic>{};
    final nested = mcp['servers'];
    if (nested != null) {
      if (nested is! Map<String, dynamic>) {
        throw ConfigValidationError('"mcp.servers" must be an object');
      }
      servers.addAll(nested);
    }
    for (final entry in mcp.entries) {
      if (entry.key == 'servers' || entry.key == 'default_timeout') continue;
      if (entry.value is Map<String, dynamic>) {
        servers[entry.key] = entry.value;
      }
    }
    for (final entry in servers.entries) {
      final name = entry.key;
      final server = entry.value;
      if (server is! Map<String, dynamic>) {
        throw ConfigValidationError('MCP server "$name" must be an object');
      }
      final type = server['type'];
      if (type != 'local' && type != 'remote') {
        throw ConfigValidationError(
          'MCP server "$name" has invalid type "$type" '
          '(expected "local" or "remote")',
        );
      }
      if (type == 'local') {
        final command = server['command'];
        if (command is! String || command.trim().isEmpty) {
          throw ConfigValidationError(
            'MCP server "$name" (local) requires a non-empty "command"',
          );
        }
        final args = server['args'];
        if (args != null && args is! List) {
          throw ConfigValidationError(
            'MCP server "$name" (local) "args" must be an array',
          );
        }
        final env = server['environment'];
        if (env != null && env is! Map) {
          throw ConfigValidationError(
            'MCP server "$name" (local) "environment" must be an object',
          );
        }
      } else {
        final url = server['url'];
        if (url is! String || url.trim().isEmpty) {
          throw ConfigValidationError(
            'MCP server "$name" (remote) requires a non-empty "url"',
          );
        }
        final uri = Uri.tryParse(url);
        if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
          throw ConfigValidationError(
            'MCP server "$name" has invalid "url": $url',
          );
        }
        final headers = server['headers'];
        if (headers != null && headers is! Map) {
          throw ConfigValidationError(
            'MCP server "$name" (remote) "headers" must be an object',
          );
        }
      }

      final timeout = server['timeout'];
      if (timeout != null && (timeout is! int || timeout < 0)) {
        throw ConfigValidationError(
          'MCP server "$name" has invalid "timeout": must be a non-negative integer',
        );
      }
    }
  }

  /// Writes [data] to [path] with 2-space indentation, then validates it.
  ///
  /// The write is atomic: the payload is encoded to a sibling temp file and
  /// committed with [File.rename], so a concurrent writer or a crashed write
  /// can never leave `chatorai.json` half-written or clobber another process's
  /// valid content (TOCTOU-safe). On validation failure the previous file
  /// content is restored and a [ConfigValidationError] is thrown. The file (and
  /// its parent directory) is created when missing.
  static Future<void> writeRawConfig(
    String path,
    Map<String, dynamic> data,
  ) async {
    _validate(data);

    await FileLockService.withLock(path, () async {
      final file = File(path);
      final previous = await file.exists() ? await file.readAsString() : null;

      await XdgPaths.ensureDir(p.dirname(path));
      final encoded = JsonEncoder.withIndent('  ').convert(data);

      final tempPath = '$path.tmp';
      final tempFile = File(tempPath);
      try {
        await tempFile.writeAsString(encoded);
      } catch (e) {
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
        rethrow;
      }

      try {
        await tempFile.rename(path);
      } catch (e) {
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
        rethrow;
      }

      try {
        final reread = json.decode(await file.readAsString());
        if (reread is Map<String, dynamic>) {
          _validate(reread);
        } else {
          throw const FormatException('top-level JSON must be an object');
        }
      } on Exception catch (e) {
        if (previous != null) {
          await file.writeAsString(previous);
        } else {
          try {
            await file.delete();
          } catch (_) {}
        }
        throw ConfigValidationError('Corrupted write to $path: $e');
      }
    });
  }

  /// Reads the existing MCP configuration from [config], tolerating both the
  /// flat `mcp.<name>` layout and the nested `mcp.servers.*` layout. Always
  /// round-trips through [McpConfig] so no declared server is ever dropped
  /// on write.
  static McpConfig _readMcp(Map<String, dynamic> config) =>
      McpConfig.fromJson(config['mcp'] as Map<String, dynamic>?);

  /// Inserts or replaces `mcp.servers[name]` from [cfg].
  ///
  /// Pre-existing servers (in either flat or `servers` layout) are preserved.
  static Future<void> upsertMcpServer(
    String name,
    McpServerConfig cfg, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    final mcp = _readMcp(config);
    final servers = {...mcp.servers, name: cfg};
    config['mcp'] = McpConfig(
      servers: servers,
      defaultTimeout: mcp.defaultTimeout,
    ).toJson();
    await writeRawConfig(path, config);
  }

  /// Removes `mcp.servers[name]`. No-op if absent or if `mcp` is missing.
  static Future<void> removeMcpServer(
    String name, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    final mcp = _readMcp(config);
    if (!mcp.servers.containsKey(name)) return;
    final servers = {...mcp.servers}..remove(name);
    if (servers.isEmpty) {
      config.remove('mcp');
    } else {
      config['mcp'] = McpConfig(
        servers: servers,
        defaultTimeout: mcp.defaultTimeout,
      ).toJson();
    }
    await writeRawConfig(path, config);
  }

  // ---------------------------------------------------------------------------
  // Instructions
  // ---------------------------------------------------------------------------

  /// Reads the `instructions` array from [config] as a `List<String>`,
  /// tolerating a missing or malformed value (returns an empty list).
  static List<String> _readInstructions(Map<String, dynamic> config) {
    final raw = config['instructions'];
    if (raw is List) return List<String>.of(raw.whereType<String>());
    return <String>[];
  }

  /// Writes [entries] back to [config] under `instructions`, dropping the key
  /// entirely when the list is empty so the file stays minimal.
  static void _writeInstructions(
    Map<String, dynamic> config,
    List<String> entries,
  ) {
    if (entries.isEmpty) {
      config.remove('instructions');
    } else {
      config['instructions'] = entries;
    }
  }

  /// Appends [entry] to the `instructions` array (idempotent — a duplicate is
  /// ignored, preserving insertion order). Creates the array when absent.
  static Future<void> addInstruction(
    String entry, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    final entries = _readInstructions(config);
    if (entries.contains(entry)) return;
    entries.add(entry);
    _writeInstructions(config, entries);
    await writeRawConfig(path, config);
  }

  /// Removes [entry] from the `instructions` array. No-op when absent. Drops
  /// the `instructions` key when the array becomes empty.
  static Future<void> removeInstruction(
    String entry, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    final entries = _readInstructions(config);
    if (!entries.contains(entry)) return;
    entries.removeWhere((e) => e == entry);
    _writeInstructions(config, entries);
    await writeRawConfig(path, config);
  }

  /// Replaces [oldEntry] with [newEntry] in place, preserving its position.
  ///
  /// If [oldEntry] is absent this behaves like [addInstruction]. If [newEntry]
  /// already exists elsewhere, the [oldEntry] slot is removed (dedupe) so the
  /// array never holds duplicates.
  static Future<void> updateInstruction(
    String oldEntry,
    String newEntry, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    final entries = _readInstructions(config);

    final index = entries.indexOf(oldEntry);
    if (index < 0) {
      if (!entries.contains(newEntry)) entries.add(newEntry);
    } else if (entries.contains(newEntry) &&
        entries.indexOf(newEntry) != index) {
      entries.removeAt(index);
    } else {
      entries[index] = newEntry;
    }

    _writeInstructions(config, entries);
    await writeRawConfig(path, config);
  }

  /// Toggles `enabled` on `mcp.servers[name]`. Throws if the server is absent.
  static Future<void> setMcpEnabled(
    String name,
    bool enabled, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    final mcp = _readMcp(config);
    final existing = mcp.servers[name];
    if (existing == null) {
      throw ConfigValidationError('MCP server "$name" not found in $path');
    }
    final updated = existing.copyWith(enabled: enabled);
    final servers = {...mcp.servers, name: updated};
    config['mcp'] = McpConfig(
      servers: servers,
      defaultTimeout: mcp.defaultTimeout,
    ).toJson();
    await writeRawConfig(path, config);
  }

  // ---------------------------------------------------------------------------
  // Permission section
  // ---------------------------------------------------------------------------

  /// Replaces the `permission` section in [config] with [section].
  ///
  /// Writes to the global user config by default, or to a project-scoped
  /// `chatorai.json` when [global] is `false` or [configPath] is provided.
  static Future<void> upsertPermissionSection(
    Map<String, dynamic> section, {
    bool global = true,
    String? configPath,
  }) async {
    final path = configPath ?? await resolveConfigPath(global: global);
    final config = await readRawConfig(path);
    config['permission'] = section;
    await writeRawConfig(path, config);
  }
}
