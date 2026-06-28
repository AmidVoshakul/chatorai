class LspMethod {
  // Lifecycle
  static const initialize = 'initialize';
  static const initialized = 'initialized';
  static const shutdown = 'shutdown';
  static const exit = 'exit';

  // Text document sync
  static const textDocumentDidOpen = 'textDocument/didOpen';
  static const textDocumentDidChange = 'textDocument/didChange';
  static const textDocumentDidClose = 'textDocument/didClose';
  static const textDocumentDidSave = 'textDocument/didSave';

  // Features
  static const textDocumentHover = 'textDocument/hover';
  static const textDocumentDefinition = 'textDocument/definition';
  static const textDocumentReferences = 'textDocument/references';
  static const textDocumentImplementation = 'textDocument/implementation';
  static const textDocumentDocumentSymbol = 'textDocument/documentSymbol';
  static const workspaceSymbol = 'workspace/symbol';
  static const textDocumentPublishDiagnostics =
      'textDocument/publishDiagnostics';
  static const textDocumentDiagnostic = 'textDocument/diagnostic';
  static const workspaceDiagnostic = 'workspace/diagnostic';

  // Notifications
  static const windowShowMessage = 'window/showMessage';
  static const windowLogMessage = 'window/logMessage';
  static const windowWorkDoneProgress = 'window/workDoneProgress/create';
}

class LspNotification {
  static const initialized = 'initialized';
  static const exit = 'exit';
  static const textDocumentPublishDiagnostics =
      'textDocument/publishDiagnostics';
  static const windowShowMessage = 'window/showMessage';
  static const windowLogMessage = 'window/logMessage';
}

class LspErrorCode {
  static const parseError = -32700;
  static const invalidRequest = -32600;
  static const methodNotFound = -32601;
  static const invalidParams = -32602;
  static const internalError = -32603;
  static const serverNotInitialized = -32002;
  static const unknownErrorCode = -32001;
}

class LspConnectionState {
  final String value;

  const LspConnectionState._(this.value);

  static const disconnected = LspConnectionState._('disconnected');
  static const connecting = LspConnectionState._('connecting');
  static const connected = LspConnectionState._('connected');
  static const error = LspConnectionState._('error');
  static const shuttingDown = LspConnectionState._('shuttingDown');
  static const shutdown = LspConnectionState._('shutdown');

  @override
  String toString() => value;
}
