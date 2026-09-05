import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';
import 'package:chatorai/core/mcp/mcp_client_service.dart';

// ---------------------------------------------------------------------------
// Fake transport that can simulate MCP server responses
// ---------------------------------------------------------------------------

class FakeTransport implements Transport {
  JsonRpcMessage? _lastSentMessage;
  bool _started = false;
  bool _closed = false;

  /// Callback that receives a request and returns a response (or null).
  JsonRpcMessage? Function(JsonRpcRequest request)? onRequest;

  JsonRpcMessage? get lastSentMessage => _lastSentMessage;
  bool get isStarted => _started;
  bool get isClosed => _closed;

  @override
  Future<void> start() async {
    _started = true;
  }

  @override
  Future<void> send(JsonRpcMessage message, {int? relatedRequestId}) async {
    if (!_started || _closed) {
      throw StateError('Transport not active');
    }
    _lastSentMessage = message;

    // If it's a request, invoke the onRequest callback and deliver the response
    if (message is JsonRpcRequest) {
      final response = onRequest?.call(message);
      if (response != null) {
        // Deliver response asynchronously (like a real transport would)
        Future.microtask(() {
          if (!_closed) {
            onmessage?.call(response);
          }
        });
      }
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    onclose?.call();
  }

  @override
  void Function()? onclose;

  @override
  void Function(Error error)? onerror;

  @override
  void Function(JsonRpcMessage message)? onmessage;

  @override
  String? get sessionId => null;
}

// ---------------------------------------------------------------------------
// Helpers to build valid MCP protocol responses
// ---------------------------------------------------------------------------

JsonRpcResponse _buildInitializeResponse() {
  return JsonRpcResponse(
    id: 0, // First request gets ID 0 from Protocol._requestMessageId++
    result: {
      'protocolVersion': '2025-06-18',
      'capabilities': {'tools': <String, dynamic>{}},
      'serverInfo': {'name': 'test-mcp-server', 'version': '1.0.0'},
    },
  );
}

JsonRpcResponse _buildListToolsResponse({
  required List<Map<String, dynamic>> tools,
  String? cursor,
}) {
  return JsonRpcResponse(
    id: 1,
    result: {'tools': tools, if (cursor != null) 'nextCursor': cursor},
  );
}

JsonRpcResponse _buildCallToolResponse({
  required String content,
  bool isError = false,
  Map<String, dynamic>? structuredContent,
}) {
  return JsonRpcResponse(
    id: 1, // After initialize (id=0), callTool is the next request (id=1)
    result: {
      'content': [
        {'type': 'text', 'text': content},
      ],
      'isError': isError,
      if (structuredContent != null) 'structuredContent': structuredContent,
    },
  );
}

/// Creates a client for the legacy initialize handshake.
///
/// mcp_dart 2.4+ probes `server/discover` before `initialize` by default;
/// the fake transport only implements the legacy flow, so disable probing
/// to keep the request sequence (and response ids) deterministic.
McpClient _createTestClient() {
  return McpClient(
    Implementation(name: 'test-client', version: '1.0.0'),
    options: McpClientOptions(useServerDiscover: false),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    // Reset singleton state via dispose
    McpClientService.instance.dispose();
  });

  tearDown(() async {
    await McpClientService.instance.dispose();
  });

  group('McpClientService initial state', () {
    test('instance is singleton', () {
      final a = McpClientService.instance;
      final b = McpClientService.instance;
      expect(identical(a, b), true);
    });

    test('getAllStatuses returns empty before initialization', () {
      final statuses = McpClientService.instance.getAllStatuses();
      expect(statuses, isEmpty);
    });

    test('getStatus returns "Not configured" for unknown server', () {
      final status = McpClientService.instance.getStatus('nonexistent');
      expect(status.status, McpConnectionStatus.failed);
      expect(status.error, 'Not configured');
    });

    test('listTools returns empty for unknown server', () async {
      final tools = await McpClientService.instance.listTools('unknown');
      expect(tools, isEmpty);
    });

    test('listAllTools returns empty before initialization', () async {
      final tools = await McpClientService.instance.listAllTools();
      expect(tools, isEmpty);
    });

    test('getToolDefs returns empty before initialization', () async {
      final defs = await McpClientService.instance.getToolDefs();
      expect(defs, isEmpty);
    });
  });

  group('McpClientService.initialize — disabled servers', () {
    test('disabled server gets disabled status', () async {
      final config = McpConfig(
        servers: {
          'disabled-server': McpServerConfig.local(
            command: 'echo',
            enabled: false,
          ),
        },
      );

      await McpClientService.instance.initialize(config);

      final status = McpClientService.instance.getStatus('disabled-server');
      expect(status.status, McpConnectionStatus.disabled);
    });

    test('multiple disabled servers all get disabled status', () async {
      final config = McpConfig(
        servers: {
          'a': McpServerConfig.local(command: 'echo', enabled: false),
          'b': McpServerConfig.remote(
            url: 'https://example.com',
            enabled: false,
          ),
        },
      );

      await McpClientService.instance.initialize(config);

      expect(
        McpClientService.instance.getStatus('a').status,
        McpConnectionStatus.disabled,
      );
      expect(
        McpClientService.instance.getStatus('b').status,
        McpConnectionStatus.disabled,
      );
    });
  });

  group('McpClientService.initialize — empty config', () {
    test('initialize completes without error', () async {
      const config = McpConfig();
      await expectLater(
        McpClientService.instance.initialize(config),
        completes,
      );
    });

    test('servers map is empty after initialization', () async {
      const config = McpConfig();
      await McpClientService.instance.initialize(config);
      expect(McpClientService.instance.getAllStatuses(), isEmpty);
    });
  });

  group('McpClientService.disconnect', () {
    test('disconnect unknown server does not throw', () async {
      await expectLater(
        McpClientService.instance.disconnect('nonexistent'),
        completes,
      );
    });

    test('disconnect after initialization marks server as disabled', () async {
      final config = McpConfig(
        servers: {
          'srv': McpServerConfig.local(command: 'echo', enabled: false),
        },
      );
      await McpClientService.instance.initialize(config);
      await McpClientService.instance.disconnect('srv');

      final status = McpClientService.instance.getStatus('srv');
      expect(status.status, McpConnectionStatus.disabled);
    });
  });

  group('McpClientService.callTool — not connected', () {
    test('returns error when server not connected', () async {
      final result = await McpClientService.instance.callTool(
        serverName: 'not-connected',
        toolName: 'some_tool',
        arguments: {},
      );
      expect(result.isError, true);
      expect(result.content, hasLength(1));
      expect(result.content[0].text, contains('not connected'));
      expect(result.content[0].text, contains('not-connected'));
    });

    test('returns error with empty arguments', () async {
      final result = await McpClientService.instance.callTool(
        serverName: 'missing',
        toolName: 'tool',
        arguments: const {},
      );
      expect(result.isError, true);
      expect(result.textContent, contains('not connected'));
    });
  });

  group('McpClientService.connect — unknown server', () {
    test('returns failed status for unknown server', () async {
      final status = await McpClientService.instance.connect('nonexistent');
      expect(status.status, McpConnectionStatus.failed);
      expect(status.error, contains('not found'));
    });
  });

  group('McpClientService.initialize — idempotency', () {
    test('calling initialize twice does not re-process', () async {
      final config = McpConfig(
        servers: {'a': McpServerConfig.local(command: 'echo', enabled: false)},
      );

      await McpClientService.instance.initialize(config);
      final firstStatus = McpClientService.instance.getStatus('a');

      await McpClientService.instance.initialize(config);
      final secondStatus = McpClientService.instance.getStatus('a');

      expect(secondStatus.status, firstStatus.status);
      expect(secondStatus.error, firstStatus.error);
    });
  });

  // ---------------------------------------------------------------------------
  // McpClient + Transport integration tests using a real McpClient
  // ---------------------------------------------------------------------------

  group('McpClient integration with FakeTransport', () {
    test('client can initialize through fake transport', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        return null;
      };

      await client.connect(transport);
      await client.close();
    });

    test('client listTools returns tools from server', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      final toolsJson = [
        {
          'name': 'read_file',
          'description': 'Read a file',
          'inputSchema': {'type': 'object'},
        },
        {
          'name': 'write_file',
          'description': 'Write a file',
          'inputSchema': {'type': 'object'},
        },
      ];

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/list') {
          return _buildListToolsResponse(tools: toolsJson);
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.listTools();
      expect(result.tools, hasLength(2));
      expect(result.tools[0].name, 'read_file');
      expect(result.tools[1].name, 'write_file');

      await client.close();
    });

    test('client callTool returns result from server', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/call') {
          return _buildCallToolResponse(content: 'File written successfully');
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.callTool(
        CallToolRequest(name: 'write_file', arguments: {'path': '/test.txt'}),
      );

      expect(result.isError, false);
      expect(result.content, hasLength(1));
      expect(
        (result.content[0] as TextContent).text,
        'File written successfully',
      );

      await client.close();
    });

    test('client callTool handles error response', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/call') {
          return _buildCallToolResponse(
            content: 'File not found',
            isError: true,
          );
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.callTool(
        CallToolRequest(name: 'read_file', arguments: {'path': '/missing.txt'}),
      );

      expect(result.isError, true);
      expect((result.content[0] as TextContent).text, 'File not found');

      await client.close();
    });

    test('client handles structuredContent in call result', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/call') {
          return _buildCallToolResponse(
            content: '{"count": 5}',
            structuredContent: {'count': 5},
          );
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.callTool(
        CallToolRequest(name: 'count', arguments: {}),
      );

      expect(result.structuredContent, {'count': 5});

      await client.close();
    });

    test('client listTools with multiple tools preserves all', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      final toolsJson = [
        {
          'name': 'shell',
          'description': 'Run shell',
          'inputSchema': {'type': 'object'},
        },
        {
          'name': 'read',
          'description': 'Read file',
          'inputSchema': {'type': 'object'},
        },
        {
          'name': 'write',
          'description': 'Write file',
          'inputSchema': {'type': 'object'},
        },
        {
          'name': 'edit',
          'description': 'Edit file',
          'inputSchema': {'type': 'object'},
        },
        {
          'name': 'glob',
          'description': 'Find files',
          'inputSchema': {'type': 'object'},
        },
      ];

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/list') {
          return _buildListToolsResponse(tools: toolsJson);
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.listTools();
      expect(result.tools, hasLength(5));
      expect(result.tools.map((t) => t.name).toList(), [
        'shell',
        'read',
        'write',
        'edit',
        'glob',
      ]);

      await client.close();
    });

    test('client handles paginated listTools with nextCursor', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      final toolsJson = [
        {
          'name': 'tool_1',
          'inputSchema': {'type': 'object'},
        },
        {
          'name': 'tool_2',
          'inputSchema': {'type': 'object'},
        },
      ];

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/list') {
          return _buildListToolsResponse(tools: toolsJson, cursor: 'page2');
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.listTools();
      expect(result.tools, hasLength(2));
      expect(result.nextCursor, 'page2');

      await client.close();
    });

    test('client handles tool with complex inputSchema', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      final toolsJson = [
        {
          'name': 'complex_tool',
          'description': 'A tool with complex schema',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'query': {'type': 'string', 'description': 'Search query'},
              'limit': {'type': 'integer', 'minimum': 1, 'maximum': 100},
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
            'required': ['query'],
          },
        },
      ];

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/list') {
          return _buildListToolsResponse(tools: toolsJson);
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.listTools();
      expect(result.tools, hasLength(1));
      expect(result.tools[0].name, 'complex_tool');
      expect(result.tools[0].description, 'A tool with complex schema');
      expect(result.tools[0].inputSchema.toJson()['type'], 'object');
      expect(result.tools[0].inputSchema.toJson()['properties'], isNotNull);

      await client.close();
    });

    test('client handles empty tools list', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/list') {
          return _buildListToolsResponse(tools: []);
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.listTools();
      expect(result.tools, isEmpty);

      await client.close();
    });

    test('client callTool passes correct arguments', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      Map<String, dynamic>? capturedArgs;

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/call') {
          capturedArgs = request.params;
          return _buildCallToolResponse(content: 'Done');
        }
        return null;
      };

      await client.connect(transport);

      await client.callTool(
        CallToolRequest(
          name: 'my_tool',
          arguments: {'path': '/test.txt', 'verbose': true, 'count': 5},
        ),
      );

      // The params contain name and arguments from CallToolRequest.toJson()
      expect(capturedArgs, isNotNull);
      expect(capturedArgs!['name'], 'my_tool');
      expect(capturedArgs!['arguments']['path'], '/test.txt');
      expect(capturedArgs!['arguments']['verbose'], true);
      expect(capturedArgs!['arguments']['count'], 5);

      await client.close();
    });

    test('client callTool with empty arguments', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/call') {
          return _buildCallToolResponse(content: 'No args needed');
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.callTool(
        CallToolRequest(name: 'no_args_tool', arguments: {}),
      );

      expect(result.isError, false);
      expect((result.content[0] as TextContent).text, 'No args needed');

      await client.close();
    });

    test('client handles multiple content parts in result', () async {
      final transport = FakeTransport();
      final client = _createTestClient();

      transport.onRequest = (request) {
        if (request.method == 'initialize') {
          return _buildInitializeResponse();
        }
        if (request.method == 'tools/call') {
          return JsonRpcResponse(
            id: 1,
            result: {
              'content': [
                {'type': 'text', 'text': 'Part 1'},
                {'type': 'text', 'text': 'Part 2'},
                {
                  'type': 'image',
                  'mimeType': 'image/png',
                  // mcp_dart 2.4+ validates that image data is real base64.
                  'data': 'ZmFrZS1pbWFnZQ==',
                },
              ],
              'isError': false,
            },
          );
        }
        return null;
      };

      await client.connect(transport);

      final result = await client.callTool(
        CallToolRequest(name: 'multi_part', arguments: {}),
      );

      expect(result.content, hasLength(3));
      expect(result.content[0], isA<TextContent>());
      expect(result.content[1], isA<TextContent>());
      expect((result.content[0] as TextContent).text, 'Part 1');
      expect((result.content[1] as TextContent).text, 'Part 2');

      await client.close();
    });
  });

  // ---------------------------------------------------------------------------
  // ToolDef format validation (indirect _sanitize test)
  // ---------------------------------------------------------------------------

  group('ToolDef format validation', () {
    test('sanitize replaces non-alphanumeric chars with underscore', () {
      expect(
        'my.server.tool'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'),
        'my_server_tool',
      );
      expect('server-1'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'), 'server-1');
      expect(
        'my@server/tool'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'),
        'my_server_tool',
      );
      expect('simple'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'), 'simple');
      expect(
        'with space'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_'),
        'with_space',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling verification
  // ---------------------------------------------------------------------------

  group('Error handling', () {
    test('service handles callTool gracefully when server missing', () async {
      final result = await McpClientService.instance.callTool(
        serverName: 'missing-server',
        toolName: 'missing-tool',
        arguments: {'key': 'value'},
      );

      expect(result.isError, true);
      expect(result.content, isNotEmpty);
      expect(result.content[0].type, 'text');
    });

    test('service returns empty listTools when client not connected', () async {
      final tools = await McpClientService.instance.listTools(
        'never-connected',
      );
      expect(tools, isEmpty);
    });

    test('service handles listAllTools when no clients connected', () async {
      final tools = await McpClientService.instance.listAllTools();
      expect(tools, isEmpty);
    });

    test('service handles connect with invalid local command', () async {
      final config = McpConfig(
        servers: {
          'bad-local': McpServerConfig.local(
            command: '/nonexistent/binary/that/does/not/exist',
            enabled: true,
          ),
        },
      );

      await McpClientService.instance.initialize(config);
      // Give async connect a moment to attempt
      await Future.delayed(const Duration(milliseconds: 500));

      final status = McpClientService.instance.getStatus('bad-local');
      expect(status.status, McpConnectionStatus.failed);
    });
  });

  // ---------------------------------------------------------------------------
  // Dispose and cleanup tests
  // ---------------------------------------------------------------------------

  group('dispose', () {
    test('dispose resets initialized state', () async {
      final config = McpConfig(
        servers: {
          'srv': McpServerConfig.local(command: 'echo', enabled: false),
        },
      );

      await McpClientService.instance.initialize(config);
      expect(McpClientService.instance.getAllStatuses(), isNotEmpty);

      await McpClientService.instance.dispose();
      expect(McpClientService.instance.getAllStatuses(), isEmpty);
    });

    test('dispose after initialize allows re-initialize', () async {
      final config1 = McpConfig(
        servers: {
          'server-a': McpServerConfig.local(command: 'echo', enabled: false),
        },
      );

      await McpClientService.instance.initialize(config1);
      await McpClientService.instance.dispose();

      final config2 = McpConfig(
        servers: {
          'server-b': McpServerConfig.local(command: 'cat', enabled: false),
        },
      );

      await McpClientService.instance.initialize(config2);
      expect(
        McpClientService.instance.getStatus('server-b').status,
        McpConnectionStatus.disabled,
      );
      expect(
        McpClientService.instance.getStatus('server-a').status,
        McpConnectionStatus.failed, // not configured anymore
      );
    });

    test('multiple dispose calls are safe', () async {
      await McpClientService.instance.dispose();
      await expectLater(McpClientService.instance.dispose(), completes);
    });
  });
}
