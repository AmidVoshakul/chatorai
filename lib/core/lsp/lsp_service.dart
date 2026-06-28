import 'dart:async';
import 'dart:io';
import 'package:chatorai/core/lsp/lsp_client.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:path/path.dart' as p;

/// Manages LSP server lifecycle and client instances.
///
/// One LSP client per (rootUri, serverId) tuple. Handles server spawning,
/// initialization, caching, and shutdown.
class LspService {
  final Map<String, LspClient> _clients = {};
  bool _disposed = false;

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
    yield* client.diagnosticsStream;
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
    LogTags.lsp.logInfo('Shutting down all LSP clients');
    final futures = <Future>[];
    for (final entry in _clients.entries) {
      futures.add(entry.value.shutdown());
    }
    await Future.wait(futures);
    _clients.clear();
  }

  LspServerConfig? _findServerForExtension(String extension) {
    if (extension == '.dart') {
      return LspServerConfig(
        id: 'dart',
        command: 'dart',
        args: const ['language-server'],
        extensions: const ['.dart'],
        rootUri: p.current,
      );
    }
    return null;
  }

  String _languageId(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.dart':
        return 'dart';
      case '.py':
        return 'python';
      case '.rs':
        return 'rust';
      case '.go':
        return 'go';
      default:
        return ext.substring(1);
    }
  }
}

/// Configuration for an LSP server.
class LspServerConfig {
  final String id;
  final String command;
  final List<String> args;
  final List<String> extensions;
  final String? rootUri;
  final Map<String, String>? env;
  final bool enabled;

  const LspServerConfig({
    required this.id,
    required this.command,
    this.args = const [],
    this.extensions = const [],
    this.rootUri,
    this.env,
    this.enabled = true,
  });
}
