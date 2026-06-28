import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chatorai/shared/utils/logger.dart';

/// Simple JSON-RPC 2.0 client over stdio for LSP.
///
/// Handles:
/// - Content-Length framing (LSP requirement)
/// - Request/response correlation via ID
/// - Notification dispatch
class JsonRpcAdapter {
  final Process _process;
  late final StreamController<String> _outputSink;
  late final StreamSubscription<List<int>> _stdoutSubscription;
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  int _nextId = 1;

  // Notification streams
  final StreamController<dynamic> _notificationController =
      StreamController.broadcast();

  bool _disposed = false;

  JsonRpcAdapter(this._process) {
    _outputSink = StreamController<String>();
    _setupReader();
    _setupWriter();
  }

  void _setupReader() {
    // LSP uses Content-Length + \r\n\r\n framing over stdio
    String buffer = '';
    _stdoutSubscription = _process.stdout.listen(
      (List<int> data) {
        buffer += utf8.decode(data);
        _processFrames(buffer);
      },
      onError: (e) {
        LogTags.lsp.logError('JSON-RPC stdin error', e);
      },
      onDone: () {
        LogTags.lsp.logInfo('JSON-RPC stdin closed');
      },
    );
  }

  void _processFrames(String buffer) {
    while (buffer.isNotEmpty) {
      final headerEnd = buffer.indexOf('\r\n\r\n');
      if (headerEnd == -1) break;

      final header = buffer.substring(0, headerEnd);
      final match = RegExp(r'Content-Length: (\d+)').firstMatch(header);
      if (match == null) {
        buffer = buffer.isEmpty ? '' : buffer.substring(headerEnd + 4);
        continue;
      }

      final length = int.parse(match.group(1)!);
      final contentStart = headerEnd + 4;
      if (buffer.length < contentStart + length) break;

      final jsonStr = buffer.substring(contentStart, contentStart + length);
      buffer = buffer.substring(contentStart + length);

      _handleMessage(jsonStr);
    }
  }

  void _handleMessage(String jsonStr) {
    try {
      final msg = jsonDecode(jsonStr) as Map<String, dynamic>;
      final id = msg['id'];
      final method = msg['method'] as String?;
      final result = msg['result'];
      final error = msg['error'];

      if (method != null) {
        // Notification (no id) or server request (rare)
        if (id == null) {
          _notificationController.add(msg);
        }
        // Ignore server-initiated requests for now
        return;
      }

      if (id != null) {
        // Response
        final key = id.toString();
        final completer = _pendingRequests.remove(key);
        if (completer != null) {
          if (error != null) {
            completer.completeError(
              RpcException(
                code: error['code'] as int? ?? -1,
                message: error['message'] as String? ?? 'Unknown error',
                data: error['data'],
              ),
            );
          } else {
            completer.complete(result);
          }
        }
      }
    } catch (e, st) {
      LogTags.lsp.logError('Failed to parse JSON-RPC message', e, st);
    }
  }

  void _setupWriter() {
    _process.stdin.addStream(
      _outputSink.stream
          .map((json) {
            final encoded = jsonEncode(json);
            return 'Content-Length: ${encoded.length}\r\n\r\n$encoded';
          })
          .transform(utf8.encoder),
    );
  }

  /// Send a request and wait for response.
  Future<dynamic> sendRequest(
    String method,
    dynamic params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_disposed) throw StateError('Adapter is disposed');

    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pendingRequests[id.toString()] = completer;

    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': ?params,
    };

    _outputSink.add(jsonEncode(request));

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingRequests.remove(id.toString());
          throw TimeoutException('Request $method timed out after $timeout');
        },
      );
    } catch (e) {
      _pendingRequests.remove(id.toString());
      rethrow;
    }
  }

  /// Send a notification (fire-and-forget).
  Future<void> sendNotification(String method, [dynamic params]) async {
    if (_disposed) return;
    final notification = {
      'jsonrpc': '2.0',
      'method': method,
      'params': ?params,
    };
    _outputSink.add(jsonEncode(notification));
  }

  Stream<dynamic> get notifications => _notificationController.stream;

  Future<void> shutdown() async {
    if (_disposed) return;
    _disposed = true;
    await _outputSink.close();
    await _stdoutSubscription.cancel();
    await _process.stdin.close();
    _process.kill();
    await _process.exitCode;
    _notificationController.close();
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Shutdown'));
      }
    }
    _pendingRequests.clear();
  }

  bool get isDisposed => _disposed;
}

class RpcException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const RpcException({required this.code, required this.message, this.data});

  @override
  String toString() => 'RpcException($code): $message';
}
