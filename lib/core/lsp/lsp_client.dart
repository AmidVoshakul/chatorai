import 'dart:async';
import 'dart:io';
import 'package:chatorai/core/lsp/json_rpc_adapter.dart';
import 'package:chatorai/core/lsp/lsp_methods.dart';
import 'package:chatorai/core/lsp/lsp_types.dart';
import 'package:chatorai/shared/utils/logger.dart';

/// Represents a connected LSP server instance.
///
/// Each instance wraps a long-running server process (e.g. `dart language-server`)
/// and maintains a stdio JSON-RPC connection.
class LspClient {
  final String id;
  final String serverPath;
  final List<String> serverArgs;
  final String? rootUri;
  final Map<String, String>? environment;

  LspConnectionState _state = LspConnectionState.disconnected;
  Process? _process;
  JsonRpcAdapter? _adapter;
  final StreamController<LspDiagnostic> _diagnosticController =
      StreamController.broadcast();

  LspClient({
    required this.id,
    required this.serverPath,
    this.serverArgs = const [],
    this.rootUri,
    this.environment,
  });

  LspConnectionState get state => _state;
  bool get isConnected => _state == LspConnectionState.connected;

  Stream<LspDiagnostic> get diagnosticsStream => _diagnosticController.stream;

  /// Start the LSP server process and perform initialization handshake.
  Future<void> start() async {
    if (_state != LspConnectionState.disconnected &&
        _state != LspConnectionState.error) {
      throw StateError('Cannot start in state $_state');
    }

    _state = LspConnectionState.connecting;
    LogTags.lsp.logInfo(
      'Starting LSP client: $id ($serverPath ${serverArgs.join(' ')})',
    );

    try {
      _process = await Process.start(
        serverPath,
        serverArgs,
        environment: environment,
        runInShell: false,
        workingDirectory: rootUri != null
            ? Uri.parse(rootUri!).toFilePath()
            : null,
      );

      _adapter = JsonRpcAdapter(_process!);

      // Listen for diagnostics notifications
      _adapter!.notifications
          .where((n) => n['method'] == LspMethod.textDocumentPublishDiagnostics)
          .listen((n) {
            try {
              final params = LspPublishDiagnosticsParams.fromJson(
                n['params'] as Map<String, dynamic>,
              );
              for (final diag in params.diagnostics) {
                _diagnosticController.add(diag);
              }
            } catch (e) {
              LogTags.lsp.logWarning('Failed to parse diagnostics: $e');
            }
          });

      // Perform initialize handshake
      final initParams = LspInitializeParams(
        processId: _process!.pid,
        rootUri: rootUri,
        capabilities: {
          'textDocument': {
            'synchronization': {'dynamicRegistration': true},
            'hover': {'dynamicRegistration': true},
            'definition': {'dynamicRegistration': true},
            'references': {'dynamicRegistration': true},
            'documentSymbol': {'dynamicRegistration': true},
            'diagnostic': {'dynamicRegistration': true},
          },
          'workspace': {
            'workspaceFolders': {'supported': true},
            'diagnostics': {'refreshSupport': true},
          },
        },
        initializationOptions: {
          'onlyAnalyzeProjectsWithOpenFiles': false,
          'suggestFromUnimportedLibraries': true,
        },
      );

      final _ = await _adapter!.sendRequest(
        LspMethod.initialize,
        initParams.toJson(),
      );

      _state = LspConnectionState.connected;
      LogTags.lsp.logInfo('LSP client initialized: $id');

      // Send initialized notification
      await _adapter!.sendNotification(LspMethod.initialized, const {});
    } catch (e, st) {
      _state = LspConnectionState.error;
      LogTags.lsp.logError('Failed to start LSP client: $id', e, st);
      await shutdown();
      rethrow;
    }
  }

  /// Send a request and wait for response.
  Future<dynamic> sendRequest(
    String method,
    dynamic params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_adapter == null || !isConnected) {
      throw StateError('LSP client $id is not connected');
    }
    return await _adapter!.sendRequest(method, params, timeout: timeout);
  }

  /// Send a notification (fire-and-forget).
  Future<void> sendNotification(String method, [dynamic params]) async {
    if (_adapter == null || !isConnected) return;
    await _adapter!.sendNotification(method, params);
  }

  /// Notify server that a text document was opened.
  Future<void> didOpen(
    String uri,
    String languageId,
    String content, {
    int version = 1,
  }) async {
    await sendNotification(LspMethod.textDocumentDidOpen, {
      'textDocument': {
        'uri': uri,
        'languageId': languageId,
        'version': version,
        'text': content,
      },
    });
  }

  /// Notify server that a text document changed.
  Future<void> didChange(
    String uri,
    List<Map<String, dynamic>> contentChanges, {
    int version = 1,
  }) async {
    await sendNotification(LspMethod.textDocumentDidChange, {
      'textDocument': {'uri': uri, 'version': version},
      'contentChanges': contentChanges,
    });
  }

  /// Notify server that a text document was closed.
  Future<void> didClose(String uri) async {
    await sendNotification(LspMethod.textDocumentDidClose, {
      'textDocument': {'uri': uri},
    });
  }

  /// Fetch hover information at a position.
  Future<Map<String, dynamic>?> hover(
    String uri,
    int line,
    int character,
  ) async {
    final result = await sendRequest(LspMethod.textDocumentHover, {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': character},
    });
    return result as Map<String, dynamic>?;
  }

  /// Fetch definition location(s) at a position.
  Future<List<Map<String, dynamic>>> definition(
    String uri,
    int line,
    int character,
  ) async {
    final result = await sendRequest(LspMethod.textDocumentDefinition, {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': character},
    });
    if (result == null) return [];
    if (result is List) return result.cast<Map<String, dynamic>>();
    return [result as Map<String, dynamic>];
  }

  /// Fetch references at a position.
  Future<List<Map<String, dynamic>>> references(
    String uri,
    int line,
    int character,
  ) async {
    final result = await sendRequest(LspMethod.textDocumentReferences, {
      'textDocument': {'uri': uri},
      'position': {'line': line, 'character': character},
      'context': {'includeDeclaration': true},
    });
    if (result == null) return [];
    return List<Map<String, dynamic>>.from(result);
  }

  /// Shutdown and cleanup.
  Future<void> shutdown() async {
    if (_state == LspConnectionState.shutdown) return;
    _state = LspConnectionState.shuttingDown;

    try {
      await _adapter?.sendRequest(LspMethod.shutdown, null);
    } catch (e) {
      LogTags.lsp.logWarning('Error during LSP shutdown: $e');
    }

    await _adapter?.shutdown();
    _adapter = null;

    try {
      _process?.kill();
      if (_process != null) await _process!.exitCode;
    } catch (e) {
      LogTags.lsp.logWarning('Error killing LSP process: $e');
    }
    _process = null;

    await _diagnosticController.close();
    _state = LspConnectionState.shutdown;
    LogTags.lsp.logInfo('LSP client shutdown: $id');
  }
}
