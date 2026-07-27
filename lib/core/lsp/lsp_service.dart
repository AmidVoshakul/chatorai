import 'dart:async';
import 'dart:io';

import 'package:chatorai/core/config/models/chatorai_config.dart';
import 'package:chatorai/core/lsp/lsp_client.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:path/path.dart' as p;

enum LspServerSource { builtIn, user, legacyFallback }

class LspServerDefinition {
  final String id;
  final String command;
  final List<String> args;
  final List<String> extensions;
  final String? languageId;
  final Map<String, String>? env;
  final AutoInstallHint? autoInstall;

  const LspServerDefinition({
    required this.id,
    required this.command,
    this.args = const [],
    this.extensions = const [],
    this.languageId,
    this.env,
    this.autoInstall,
  });

  LspServerConfig toConfig({String? rootUri}) => LspServerConfig(
    id: id,
    command: command,
    args: args,
    extensions: extensions,
    languageId: languageId,
    rootUri: rootUri ?? p.current,
    env: env,
    enabled: true,
  );
}

class AutoInstallHint {
  final String packageManager; // npm|cargo|brew|pip|go
  final String packageName;
  final List<String>? extraArgs;

  const AutoInstallHint({
    required this.packageManager,
    required this.packageName,
    this.extraArgs,
  });

  Future<bool> install() async {
    final cmds = <List<String>>[];
    switch (packageManager) {
      case 'npm':
        cmds.add(['npm', 'install', '-g', packageName, ...?extraArgs]);
      case 'cargo':
        cmds.add(['cargo', 'install', packageName, ...?extraArgs]);
      case 'brew':
        cmds.add(['brew', 'install', packageName, ...?extraArgs]);
      case 'pip':
        cmds.add(['pip', 'install', packageName, ...?extraArgs]);
      case 'go':
        cmds.add(['go', 'install', packageName]);
      default:
        return false;
    }

    for (final cmd in cmds) {
      try {
        final result = await Process.run(cmd.first, cmd.skip(1).toList());
        if (result.exitCode == 0) return true;
      } on Exception catch (e) {
        LogTags.lsp.logWarning('Auto-install failed: $cmd: $e');
      }
    }
    return false;
  }
}

/// Manages LSP server lifecycle and client instances.
///
/// One LSP client per (rootUri, serverId) tuple. Handles server spawning,
/// initialization, caching, and shutdown.
class LspService {
  final Map<String, LspClient> _clients = {};
  final Set<String> _openedFiles = {};
  bool _disposed = false;
  bool _enabled = true;

  /// User-defined server overrides from chatorai.json.
  /// Maps extension → LspServerConfig (highest priority).
  final Map<String, LspServerConfig> _userServerOverrides = {};

  /// Track auto-install attempts to avoid loops.
  final Set<String> _autoInstallAttempted = {};

  /// Guard concurrent client creation per cache key.
  final Map<String, Completer<void>> _activeCreation = {};

  /// Register and start an LSP server configuration.
  Future<String> registerServer(LspServerConfig config) async {
    if (_disposed) throw StateError('Service is disposed');
    if (!config.enabled) return config.id;

    LogTags.lsp.logInfo('Registering LSP server: ${config.id}');

    final client = LspClient(
      id: config.id,
      serverPath: config.command,
      serverArgs: config.args,
      rootUri: config.rootUri,
      environment: config.env,
    );

    await client.start();
    _clients[config.id] = client;
    return config.id;
  }

  /// Unregister a server and shut down its client.
  Future<void> unregisterServer(String serverId) async {
    final client = _clients.remove(serverId);
    if (client != null) {
      await client.shutdown();
    }
  }

  /// Get or create a client for the given workspace root.
  Future<LspClient?> clientForFile(String filePath) async {
    if (_disposed) return null;
    if (!_enabled) return null;

    final extension = p.extension(filePath).toLowerCase();
    final config = _findServerForExtension(extension);
    if (config == null) return null;

    final cacheKey = '${config.rootUri ?? 'default'}_${config.id}';
    final existing = _clients[cacheKey];
    if (existing != null) {
      if (existing.isConnected) return existing;
      await existing.shutdown();
      _clients.remove(cacheKey);
    }

    if (_activeCreation.containsKey(cacheKey)) {
      await _activeCreation[cacheKey]!.future;
      final retry = _clients[cacheKey];
      return retry?.isConnected == true ? retry : null;
    }

    final completer = Completer<void>();
    _activeCreation[cacheKey] = completer;

    try {
      if (!await _commandExists(config.command)) {
        final definition = _findBuiltInDefinition(extension);
        if (definition != null &&
            definition.autoInstall != null &&
            !_autoInstallAttempted.contains(definition.id)) {
          _autoInstallAttempted.add(definition.id);
          LogTags.lsp.logInfo('Auto-installing LSP server: ${definition.id}');
          final installed = await definition.autoInstall!.install();
          if (!installed) {
            LogTags.lsp.logWarning(
              'Auto-install failed for ${definition.id}; falling back',
            );
          }
        }
      }

      final client = LspClient(
        id: cacheKey,
        serverPath: config.command,
        serverArgs: config.args,
        rootUri: config.rootUri,
        environment: config.env,
      );

      try {
        await client.start();
        _clients[cacheKey] = client;
        return client;
      } catch (e) {
        LogTags.lsp.logError('Failed to start LSP client for $filePath', e);
        return null;
      }
    } finally {
      completer.complete();
      _activeCreation.remove(cacheKey);
    }
  }

  /// Request diagnostics for a specific file.
  Stream<LspDiagnostic> diagnostics(String filePath) async* {
    final client = await clientForFile(filePath);
    if (client == null) {
      yield* const Stream.empty();
      return;
    }

    final uri = Uri.file(filePath).toString();
    String content;
    try {
      content = await File(filePath).readAsString();
    } catch (e) {
      yield LspDiagnostic(
        range: const LspRange(
          start: LspPosition(line: 0, character: 0),
          end: LspPosition(line: 0, character: 0),
        ),
        severity: LspDiagnosticSeverity.error,
        message: 'Failed to read file: $e',
      );
      return;
    }

    await client.didOpen(uri, _languageId(filePath), content);
    try {
      yield* client.diagnosticsStream;
    } finally {
      await client.didClose(uri);
    }
  }

  /// Notify LSP that a file's content has changed.
  ///
  /// Uses [didOpen] for first-time files, [didChange] for subsequent changes.
  /// This ensures the LSP server's internal state matches the current file
  /// content before fetching diagnostics.
  Future<void> notifyFileChanged(String filePath) async {
    final client = await clientForFile(filePath);
    if (client == null) return;

    final uri = Uri.file(filePath).toString();
    String content;
    try {
      content = await File(filePath).readAsString();
    } catch (_) {
      return;
    }

    if (_openedFiles.contains(filePath)) {
      await client.didChange(uri, [
        {'text': content},
      ]);
    } else {
      await client.didOpen(uri, _languageId(filePath), content);
      _openedFiles.add(filePath);
    }
  }

  /// Collect diagnostics for a file after notifying LSP of its current state.
  ///
  /// Subscribes to the diagnostics stream [timeout] before sending the
  /// notification, then waits [timeout] for the server to respond with
  /// diagnostics. Returns an empty list if no diagnostics arrive in time.
  Future<List<LspDiagnosticLine>> diagnosticsForFile(
    String filePath, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final client = await clientForFile(filePath);
    if (client == null) return [];

    final collected = <LspDiagnosticLine>[];
    final sub = client.diagnosticsStream.listen((diag) {
      collected.add(
        LspDiagnosticLine(
          severity: LspDiagnosticSeverity.label(diag.severity),
          line: diag.range.start.line + 1,
          column: diag.range.start.character + 1,
          message: diag.message,
        ),
      );
    });

    await notifyFileChanged(filePath);
    await Future.delayed(timeout);
    await sub.cancel();
    await client.didClose(Uri.file(filePath).toString());

    return collected;
  }

  /// Request hover information.
  Future<Map<String, dynamic>?> hover(
    String filePath,
    int line,
    int character,
  ) async {
    final client = await clientForFile(filePath);
    if (client == null) return null;
    return await client.hover(Uri.file(filePath).toString(), line, character);
  }

  /// Request definition locations.
  Future<List<Map<String, dynamic>>> definition(
    String filePath,
    int line,
    int character,
  ) async {
    final client = await clientForFile(filePath);
    if (client == null) return [];
    return await client.definition(
      Uri.file(filePath).toString(),
      line,
      character,
    );
  }

  /// Request references.
  Future<List<Map<String, dynamic>>> references(
    String filePath,
    int line,
    int character,
  ) async {
    final client = await clientForFile(filePath);
    if (client == null) return [];
    return await client.references(
      Uri.file(filePath).toString(),
      line,
      character,
    );
  }

  /// Shutdown all clients.
  Future<void> shutdownAll() async {
    if (_disposed) return;
    _disposed = true;
    _openedFiles.clear();
    _activeCreation.clear();
    LogTags.lsp.logInfo('Shutting down all LSP clients');
    final futures = <Future>[];
    for (final entry in _clients.entries) {
      futures.add(entry.value.shutdown());
    }
    await Future.wait(futures);
    _clients.clear();
  }

  /// Load user-defined LSP server configs from chatorai.json.
  ///
  /// User configs take highest priority over built-in servers.
  void loadUserServers(LspConfig config) {
    _userServerOverrides.clear();
    _enabled = config.enabled;
    if (!_enabled) return;

    for (final entry in config.servers.entries) {
      final serverConfig = entry.value;
      if (serverConfig.disabled == true) continue;

      final extensions = serverConfig.extensions;
      if (extensions == null || extensions.isEmpty) continue;

      final command = serverConfig.command;
      if (command == null || command.isEmpty) continue;

      final lspConfig = LspServerConfig(
        id: entry.key,
        command: command.first,
        args: serverConfig.args ?? const [],
        extensions: extensions,
        languageId: serverConfig.languageId,
        rootUri: p.current,
        env: serverConfig.environment,
        enabled: serverConfig.autoInstall != false,
      );

      for (final ext in extensions) {
        _userServerOverrides[ext.toLowerCase()] = lspConfig;
      }
    }
  }

  LspServerConfig? _findServerForExtension(String extension) {
    // 1. User override (highest priority)
    final userOverride = _userServerOverrides[extension];
    if (userOverride != null) return userOverride;

    // 2. Built-in table
    final builtIn = _builtInByExtension[extension];
    if (builtIn != null) {
      final definition = _builtInServers[builtIn];
      if (definition != null) {
        return definition.toConfig(rootUri: p.current);
      }
    }

    return null;
  }

  String _languageId(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.dart':
        return 'dart';
      case '.py':
      case '.pyi':
        return 'python';
      case '.java':
        return 'java';
      case '.kt':
      case '.kts':
        return 'kotlin';
      case '.go':
        return 'go';
      case '.rs':
        return 'rust';
      case '.cs':
      case '.csx':
        return 'csharp';
      case '.js':
      case '.jsx':
      case '.mjs':
      case '.cjs':
        return 'javascript';
      case '.ts':
      case '.tsx':
      case '.mts':
      case '.cts':
        return 'typescript';
      case '.lua':
        return 'lua';
      case '.yaml':
      case '.yml':
        return 'yaml';
      case '.sh':
      case '.shell':
      case '.zsh':
        return 'shell';
      case '.c':
      case '.h':
        return 'c';
      case '.cpp':
      case '.cc':
      case '.cxx':
      case '.c++':
      case '.hpp':
      case '.hh':
      case '.hxx':
      case '.h++':
        return 'cpp';
      case '.md':
      case '.markdown':
        return 'markdown';
      case '.swift':
        return 'swift';
      case '.zig':
        return 'zig';
      default:
        return ext.substring(1);
    }
  }

  LspServerDefinition? _findBuiltInDefinition(String extension) {
    final builtIn = _builtInByExtension[extension];
    if (builtIn == null) return null;
    return _builtInServers[builtIn];
  }

  /// Check whether [command] is available on PATH.
  Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        command,
      ]).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } on Exception {
      return false;
    }
  }
}

/// Built-in LSP server definitions for popular languages.
///
/// Lazy: servers are only started when a matching file extension is first
/// detected. No startup cost for unused languages.
const Map<String, LspServerDefinition> _builtInServers = {
  'dart': LspServerDefinition(
    id: 'dart',
    command: 'dart',
    args: ['language-server'],
    extensions: ['.dart'],
    languageId: 'dart',
  ),
  'typescript': LspServerDefinition(
    id: 'typescript-language-server',
    command: 'typescript-language-server',
    args: ['--stdio'],
    extensions: ['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs'],
    languageId: 'typescript',
    autoInstall: AutoInstallHint(
      packageManager: 'npm',
      packageName: 'typescript-language-server',
      extraArgs: ['--global'],
    ),
  ),
  'python': LspServerDefinition(
    id: 'pyright-langserver',
    command: 'pyright-langserver',
    args: ['--stdio'],
    extensions: ['.py', '.pyi'],
    languageId: 'python',
    autoInstall: AutoInstallHint(packageManager: 'pip', packageName: 'pyright'),
  ),
  'java': LspServerDefinition(
    id: 'jdtls',
    command: 'jdtls',
    args: [],
    extensions: ['.java'],
    languageId: 'java',
  ),
  'kotlin': LspServerDefinition(
    id: 'kotlin-language-server',
    command: 'kotlin-language-server',
    args: [],
    extensions: ['.kt', '.kts'],
    languageId: 'kotlin',
  ),
  'go': LspServerDefinition(
    id: 'gopls',
    command: 'gopls',
    args: [],
    extensions: ['.go'],
    languageId: 'go',
  ),
  'rust': LspServerDefinition(
    id: 'rust-analyzer',
    command: 'rust-analyzer',
    args: [],
    extensions: ['.rs'],
    languageId: 'rust',
  ),
  'csharp': LspServerDefinition(
    id: 'csharp-ls',
    command: 'csharp-ls',
    args: [],
    extensions: ['.cs', '.csx'],
    languageId: 'csharp',
  ),
  'yaml': LspServerDefinition(
    id: 'yaml-language-server',
    command: 'yaml-language-server',
    args: ['--stdio'],
    extensions: ['.yaml', '.yml'],
    languageId: 'yaml',
    autoInstall: AutoInstallHint(
      packageManager: 'npm',
      packageName: 'yaml-language-server',
      extraArgs: ['--global'],
    ),
  ),
  'shell': LspServerDefinition(
    id: 'shell-language-server',
    command: 'shell-language-server',
    args: ['stdio'],
    extensions: ['.sh', '.shell', '.zsh', '.ksh'],
    languageId: 'shell',
    autoInstall: AutoInstallHint(
      packageManager: 'npm',
      packageName: 'shell-language-server',
      extraArgs: ['--global'],
    ),
  ),
  'clangd': LspServerDefinition(
    id: 'clangd',
    command: 'clangd',
    args: [],
    extensions: [
      '.c',
      '.cpp',
      '.cc',
      '.cxx',
      '.c++',
      '.h',
      '.hpp',
      '.hh',
      '.hxx',
      '.h++',
    ],
    languageId: 'c',
  ),
  'lua': LspServerDefinition(
    id: 'lua-language-server',
    command: 'lua-language-server',
    args: [],
    extensions: ['.lua'],
    languageId: 'lua',
  ),
  'markdown': LspServerDefinition(
    id: 'marksman',
    command: 'marksman',
    args: ['server'],
    extensions: ['.md', '.markdown'],
    languageId: 'markdown',
    autoInstall: AutoInstallHint(
      packageManager: 'npm',
      packageName: 'marksman',
      extraArgs: ['--global'],
    ),
  ),
  'swift': LspServerDefinition(
    id: 'sourcekit-lsp',
    command: 'sourcekit-lsp',
    args: [],
    extensions: ['.swift'],
    languageId: 'swift',
  ),
  'zig': LspServerDefinition(
    id: 'zls',
    command: 'zls',
    args: [],
    extensions: ['.zig', '.zon'],
    languageId: 'zig',
  ),
};

/// Extension → built-in server ID mapping for fast lookup.
const Map<String, String> _builtInByExtension = {
  '.dart': 'dart',
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.js': 'typescript',
  '.jsx': 'typescript',
  '.mjs': 'typescript',
  '.cjs': 'typescript',
  '.py': 'python',
  '.pyi': 'python',
  '.java': 'java',
  '.kt': 'kotlin',
  '.kts': 'kotlin',
  '.go': 'go',
  '.rs': 'rust',
  '.cs': 'csharp',
  '.csx': 'csharp',
  '.yaml': 'yaml',
  '.yml': 'yaml',
  '.sh': 'shell',
  '.shell': 'shell',
  '.zsh': 'shell',
  '.ksh': 'shell',
  '.c': 'clangd',
  '.cpp': 'clangd',
  '.cc': 'clangd',
  '.cxx': 'clangd',
  '.c++': 'clangd',
  '.h': 'clangd',
  '.hpp': 'clangd',
  '.hh': 'clangd',
  '.hxx': 'clangd',
  '.h++': 'clangd',
  '.lua': 'lua',
  '.md': 'markdown',
  '.markdown': 'markdown',
  '.swift': 'swift',
  '.zig': 'zig',
  '.zon': 'zig',
};

/// Configuration for an LSP server.
class LspServerConfig {
  final String id;
  final String command;
  final List<String> args;
  final List<String> extensions;
  final String? rootUri;
  final Map<String, String>? env;
  final bool enabled;
  final String? languageId;

  const LspServerConfig({
    required this.id,
    required this.command,
    this.args = const [],
    this.extensions = const [],
    this.rootUri,
    this.env,
    this.enabled = true,
    this.languageId,
  });
}
