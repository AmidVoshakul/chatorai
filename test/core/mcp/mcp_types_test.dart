import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/mcp/mcp_types.dart';

void main() {
  group('McpToolInfo', () {
    test('constructor with required fields', () {
      const tool = McpToolInfo(
        name: 'read_file',
        inputSchema: {'type': 'object'},
      );
      expect(tool.name, 'read_file');
      expect(tool.description, isNull);
      expect(tool.inputSchema, {'type': 'object'});
    });

    test('constructor with all fields', () {
      const tool = McpToolInfo(
        name: 'write_file',
        description: 'Writes content to a file',
        inputSchema: {
          'type': 'object',
          'properties': {
            'path': {'type': 'string'},
            'content': {'type': 'string'},
          },
        },
      );
      expect(tool.name, 'write_file');
      expect(tool.description, 'Writes content to a file');
      expect(tool.inputSchema['type'], 'object');
    });

    test('fromJson with required fields only', () {
      final json = {
        'name': 'search',
        'inputSchema': {'type': 'object', 'properties': {}},
      };
      final tool = McpToolInfo.fromJson(json);
      expect(tool.name, 'search');
      expect(tool.description, isNull);
      expect(tool.inputSchema['type'], 'object');
    });

    test('fromJson with description', () {
      final json = {
        'name': 'shell',
        'description': 'Execute a shell command',
        'inputSchema': {'type': 'object'},
      };
      final tool = McpToolInfo.fromJson(json);
      expect(tool.name, 'shell');
      expect(tool.description, 'Execute a shell command');
    });

    test('fromJson with empty inputSchema when missing', () {
      final json = {'name': 'simple'};
      final tool = McpToolInfo.fromJson(json);
      expect(tool.inputSchema, isEmpty);
    });

    test('toJson includes name and inputSchema', () {
      const tool = McpToolInfo(
        name: 'test_tool',
        inputSchema: {'type': 'object'},
      );
      final json = tool.toJson();
      expect(json['name'], 'test_tool');
      expect(json['inputSchema'], {'type': 'object'});
      expect(json.containsKey('description'), false);
    });

    test('toJson includes description when present', () {
      const tool = McpToolInfo(
        name: 'test_tool',
        description: 'A test tool',
        inputSchema: {'type': 'object'},
      );
      final json = tool.toJson();
      expect(json['description'], 'A test tool');
    });

    test('roundtrip: toJson → fromJson preserves all fields', () {
      const original = McpToolInfo(
        name: 'roundtrip_tool',
        description: 'Tests roundtrip',
        inputSchema: {
          'type': 'object',
          'properties': {
            'x': {'type': 'number'},
          },
          'required': ['x'],
        },
      );
      final restored = McpToolInfo.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.inputSchema, original.inputSchema);
    });
  });

  group('McpCallResult', () {
    test('constructor with error flag and content', () {
      const result = McpCallResult(
        isError: true,
        content: [McpContentPart(type: 'text', text: 'Something went wrong')],
      );
      expect(result.isError, true);
      expect(result.content, hasLength(1));
      expect(result.structuredContent, isNull);
    });

    test('constructor with structured content', () {
      const result = McpCallResult(
        isError: false,
        content: [McpContentPart(type: 'text', text: 'OK')],
        structuredContent: {'status': 'success', 'code': 200},
      );
      expect(result.isError, false);
      expect(result.structuredContent, {'status': 'success', 'code': 200});
    });

    test('textContent extracts text parts joined by double newlines', () {
      const result = McpCallResult(
        isError: false,
        content: [
          McpContentPart(type: 'text', text: 'First paragraph'),
          McpContentPart(type: 'text', text: 'Second paragraph'),
        ],
      );
      expect(result.textContent, 'First paragraph\n\nSecond paragraph');
    });

    test('textContent filters out non-text parts', () {
      const result = McpCallResult(
        isError: false,
        content: [
          McpContentPart(type: 'text', text: 'Text content'),
          McpContentPart(type: 'image', mimeType: 'image/png', data: [1, 2, 3]),
        ],
      );
      expect(result.textContent, 'Text content');
    });

    test('textContent filters out empty text parts', () {
      const result = McpCallResult(
        isError: false,
        content: [
          McpContentPart(type: 'text', text: 'Real content'),
          McpContentPart(type: 'text', text: '  '),
          McpContentPart(type: 'text', text: ''),
        ],
      );
      expect(result.textContent, 'Real content');
    });

    test('textContent returns empty string when no text parts', () {
      const result = McpCallResult(
        isError: false,
        content: [
          McpContentPart(type: 'image', mimeType: 'image/png', data: [1]),
        ],
      );
      expect(result.textContent, '');
    });

    test('toString returns textContent when available', () {
      const result = McpCallResult(
        isError: false,
        content: [McpContentPart(type: 'text', text: 'Hello world')],
      );
      expect(result.toString(), 'Hello world');
    });

    test('toString returns structured info when no text', () {
      const result = McpCallResult(
        isError: true,
        content: [
          McpContentPart(type: 'image', mimeType: 'img', data: [1]),
        ],
      );
      expect(result.toString(), contains('isError: true'));
      expect(result.toString(), contains('1 parts'));
    });

    test('fromJson with minimal fields', () {
      final json = {'isError': false, 'content': <Map<String, dynamic>>[]};
      final result = McpCallResult.fromJson(json);
      expect(result.isError, false);
      expect(result.content, isEmpty);
      expect(result.structuredContent, isNull);
    });

    test('fromJson with content list', () {
      final json = {
        'isError': false,
        'content': [
          {'type': 'text', 'text': 'Result text'},
          {
            'type': 'image',
            'mimeType': 'image/jpeg',
            'data': [255, 0],
          },
        ],
        'structuredContent': {
          'result': [1, 2, 3],
        },
      };
      final result = McpCallResult.fromJson(json);
      expect(result.isError, false);
      expect(result.content, hasLength(2));
      expect(result.content[0].type, 'text');
      expect(result.content[0].text, 'Result text');
      expect(result.content[1].type, 'image');
      expect(result.content[1].mimeType, 'image/jpeg');
      expect(result.structuredContent, {
        'result': [1, 2, 3],
      });
    });

    test('fromJson defaults isError to false', () {
      final json = {'content': <Map<String, dynamic>>[]};
      final result = McpCallResult.fromJson(json);
      expect(result.isError, false);
    });

    test('toJson includes all fields', () {
      const result = McpCallResult(
        isError: true,
        content: [McpContentPart(type: 'text', text: 'Error occurred')],
        structuredContent: {'error_code': 42},
      );
      final json = result.toJson();
      expect(json['isError'], true);
      expect(json['content'], hasLength(1));
      expect(json['structuredContent'], {'error_code': 42});
    });

    test('toJson omits null structuredContent', () {
      const result = McpCallResult(
        isError: false,
        content: [McpContentPart(type: 'text', text: 'OK')],
      );
      final json = result.toJson();
      expect(json.containsKey('structuredContent'), false);
    });

    test('roundtrip: toJson → fromJson preserves all fields', () {
      const original = McpCallResult(
        isError: true,
        content: [
          McpContentPart(type: 'text', text: 'Error msg'),
          McpContentPart(type: 'image', mimeType: 'png', data: [1, 2]),
        ],
        structuredContent: {'details': 'full error'},
      );
      final restored = McpCallResult.fromJson(original.toJson());
      expect(restored.isError, original.isError);
      expect(restored.content, hasLength(2));
      expect(restored.content[0].text, 'Error msg');
      expect(restored.structuredContent, {'details': 'full error'});
    });
  });

  group('McpContentPart', () {
    test('constructor with type only', () {
      const part = McpContentPart(type: 'text');
      expect(part.type, 'text');
      expect(part.text, isNull);
      expect(part.mimeType, isNull);
      expect(part.data, isNull);
    });

    test('constructor with all fields', () {
      const part = McpContentPart(
        type: 'image',
        text: null,
        mimeType: 'image/png',
        data: [137, 80, 78, 71],
      );
      expect(part.type, 'image');
      expect(part.text, isNull);
      expect(part.mimeType, 'image/png');
      expect(part.data, [137, 80, 78, 71]);
    });

    test('fromJson with text content', () {
      final json = {'type': 'text', 'text': 'Hello, world!'};
      final part = McpContentPart.fromJson(json);
      expect(part.type, 'text');
      expect(part.text, 'Hello, world!');
      expect(part.mimeType, isNull);
      expect(part.data, isNull);
    });

    test('fromJson with image content', () {
      final json = {
        'type': 'image',
        'mimeType': 'image/jpeg',
        'data': [255, 216, 255],
      };
      final part = McpContentPart.fromJson(json);
      expect(part.type, 'image');
      expect(part.mimeType, 'image/jpeg');
      expect(part.data, [255, 216, 255]);
    });

    test('fromJson with snake_case mime_type', () {
      final json = {
        'type': 'image',
        'mime_type': 'image/svg+xml',
        'data': [60, 63, 120, 109],
      };
      final part = McpContentPart.fromJson(json);
      expect(part.mimeType, 'image/svg+xml');
    });

    test('fromJson with camelCase mimeType', () {
      final json = {'type': 'resource', 'mimeType': 'application/json'};
      final part = McpContentPart.fromJson(json);
      expect(part.mimeType, 'application/json');
    });

    test('fromJson with empty data list', () {
      final json = {'type': 'blob', 'data': <int>[]};
      final part = McpContentPart.fromJson(json);
      expect(part.data, isEmpty);
    });

    test('toJson includes all non-null fields', () {
      const part = McpContentPart(type: 'text', text: 'Output text');
      final json = part.toJson();
      expect(json['type'], 'text');
      expect(json['text'], 'Output text');
      expect(json.containsKey('mimeType'), false);
      expect(json.containsKey('data'), false);
    });

    test('toJson includes mimeType when present', () {
      const part = McpContentPart(
        type: 'image',
        mimeType: 'image/gif',
        data: [71, 73, 70],
      );
      final json = part.toJson();
      expect(json['type'], 'image');
      expect(json['mimeType'], 'image/gif');
      expect(json['data'], [71, 73, 70]);
    });

    test('toJson omits null fields', () {
      const part = McpContentPart(type: 'text', text: 'Only text');
      final json = part.toJson();
      expect(json.keys, containsAll(['type', 'text']));
      expect(json.keys, isNot(contains('mimeType')));
      expect(json.keys, isNot(contains('data')));
    });

    test('roundtrip: toJson → fromJson preserves all fields', () {
      const original = McpContentPart(
        type: 'image',
        mimeType: 'image/webp',
        data: [119, 101, 98, 112],
      );
      final restored = McpContentPart.fromJson(original.toJson());
      expect(restored.type, original.type);
      expect(restored.mimeType, original.mimeType);
      expect(restored.data, original.data);
    });

    test('roundtrip with text content', () {
      const original = McpContentPart(type: 'text', text: 'Roundtrip text');
      final restored = McpContentPart.fromJson(original.toJson());
      expect(restored.type, 'text');
      expect(restored.text, 'Roundtrip text');
    });
  });

  group('McpConnectionStatus', () {
    test('connected has correct value', () {
      expect(McpConnectionStatus.connected.value, 'connected');
    });

    test('disabled has correct value', () {
      expect(McpConnectionStatus.disabled.value, 'disabled');
    });

    test('failed has correct value', () {
      expect(McpConnectionStatus.failed.value, 'failed');
    });

    test('needsAuth has correct value', () {
      expect(McpConnectionStatus.needsAuth.value, 'needs_auth');
    });

    test('needsClientRegistration has correct value', () {
      expect(
        McpConnectionStatus.needsClientRegistration.value,
        'needs_client_registration',
      );
    });

    test('fromValue returns correct enum for each value', () {
      expect(
        McpConnectionStatus.fromValue('connected'),
        McpConnectionStatus.connected,
      );
      expect(
        McpConnectionStatus.fromValue('disabled'),
        McpConnectionStatus.disabled,
      );
      expect(
        McpConnectionStatus.fromValue('failed'),
        McpConnectionStatus.failed,
      );
      expect(
        McpConnectionStatus.fromValue('needs_auth'),
        McpConnectionStatus.needsAuth,
      );
      expect(
        McpConnectionStatus.fromValue('needs_client_registration'),
        McpConnectionStatus.needsClientRegistration,
      );
    });

    test('fromValue returns failed for unknown value', () {
      expect(
        McpConnectionStatus.fromValue('unknown'),
        McpConnectionStatus.failed,
      );
    });

    test('fromValue returns failed for empty string', () {
      expect(McpConnectionStatus.fromValue(''), McpConnectionStatus.failed);
    });
  });

  group('McpServerStatus', () {
    test('connected factory creates connected status without error', () {
      final status = McpServerStatus.connected();
      expect(status.status, McpConnectionStatus.connected);
      expect(status.error, isNull);
    });

    test('disabled factory creates disabled status', () {
      final status = McpServerStatus.disabled();
      expect(status.status, McpConnectionStatus.disabled);
      expect(status.error, isNull);
    });

    test('failed factory creates failed status with error', () {
      final status = McpServerStatus.failed('Connection refused');
      expect(status.status, McpConnectionStatus.failed);
      expect(status.error, 'Connection refused');
    });

    test('failed factory with empty error message', () {
      final status = McpServerStatus.failed('');
      expect(status.status, McpConnectionStatus.failed);
      expect(status.error, '');
    });

    test('needsAuth factory creates needs_auth status', () {
      final status = McpServerStatus.needsAuth();
      expect(status.status, McpConnectionStatus.needsAuth);
      expect(status.error, isNull);
    });

    test(
      'needsClientRegistration factory creates needs_client_registration',
      () {
        final status = McpServerStatus.needsClientRegistration(
          'Register first',
        );
        expect(status.status, McpConnectionStatus.needsClientRegistration);
        expect(status.error, 'Register first');
      },
    );

    test('fromJson with connected status', () {
      final json = {'status': 'connected'};
      final status = McpServerStatus.fromJson(json);
      expect(status.status, McpConnectionStatus.connected);
      expect(status.error, isNull);
    });

    test('fromJson with failed status and error', () {
      final json = {'status': 'failed', 'error': 'Timeout after 30s'};
      final status = McpServerStatus.fromJson(json);
      expect(status.status, McpConnectionStatus.failed);
      expect(status.error, 'Timeout after 30s');
    });

    test('fromJson with needs_auth status', () {
      final json = {'status': 'needs_auth'};
      final status = McpServerStatus.fromJson(json);
      expect(status.status, McpConnectionStatus.needsAuth);
    });

    test('fromJson with needs_client_registration and error', () {
      final json = {
        'status': 'needs_client_registration',
        'error': 'No client ID configured',
      };
      final status = McpServerStatus.fromJson(json);
      expect(status.status, McpConnectionStatus.needsClientRegistration);
      expect(status.error, 'No client ID configured');
    });

    test('fromJson defaults to failed when status missing', () {
      final json = <String, dynamic>{};
      final status = McpServerStatus.fromJson(json);
      expect(status.status, McpConnectionStatus.failed);
    });

    test('fromJson defaults to failed for unknown status', () {
      final json = {'status': 'bogus_status'};
      final status = McpServerStatus.fromJson(json);
      expect(status.status, McpConnectionStatus.failed);
    });

    test('toJson includes status value', () {
      final status = McpServerStatus.connected();
      final json = status.toJson();
      expect(json['status'], 'connected');
      expect(json.containsKey('error'), false);
    });

    test('toJson includes error when present', () {
      final status = McpServerStatus.failed('Something broke');
      final json = status.toJson();
      expect(json['status'], 'failed');
      expect(json['error'], 'Something broke');
    });

    test('toJson omits null error', () {
      final status = McpServerStatus.needsAuth();
      final json = status.toJson();
      expect(json.containsKey('error'), false);
    });

    test('roundtrip: toJson → fromJson preserves connected', () {
      final original = McpServerStatus.connected();
      final restored = McpServerStatus.fromJson(original.toJson());
      expect(restored.status, original.status);
      expect(restored.error, original.error);
    });

    test('roundtrip: toJson → fromJson preserves failed with error', () {
      final original = McpServerStatus.failed('Detailed error message');
      final restored = McpServerStatus.fromJson(original.toJson());
      expect(restored.status, McpConnectionStatus.failed);
      expect(restored.error, 'Detailed error message');
    });

    test('roundtrip: toJson → fromJson preserves needsClientRegistration', () {
      final original = McpServerStatus.needsClientRegistration(
        'Register at example.com',
      );
      final restored = McpServerStatus.fromJson(original.toJson());
      expect(restored.status, McpConnectionStatus.needsClientRegistration);
      expect(restored.error, 'Register at example.com');
    });
  });
}
