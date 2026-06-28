import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/truncation_service.dart';
import 'package:chatorai/core/tools/tool_registry.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
import 'package:chatorai/core/permission/rule.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── ToolError sealed class hierarchy ─────────────────────────────────────

void main() {
  group('ToolError hierarchy', () {
    test('ToolNotFoundError stores toolName', () {
      const error = ToolNotFoundError('read');
      expect(error.toolName, 'read');
      expect(error, isA<ToolError>());
    });

    test('ToolTimeoutError stores toolName', () {
      const error = ToolTimeoutError('bash');
      expect(error.toolName, 'bash');
      expect(error, isA<ToolError>());
    });

    test('ToolPermissionDeniedError stores toolName', () {
      const error = ToolPermissionDeniedError('write');
      expect(error.toolName, 'write');
      expect(error, isA<ToolError>());
    });

    test('ToolInvalidArgsError stores toolName and message', () {
      const error = ToolInvalidArgsError('edit', 'missing file_path');
      expect(error.toolName, 'edit');
      expect(error.message, 'missing file_path');
      expect(error, isA<ToolError>());
    });

    test('ToolOverflowError stores toolName and message', () {
      const error = ToolOverflowError('bash', 'output exceeds limit');
      expect(error.toolName, 'bash');
      expect(error.message, 'output exceeds limit');
      expect(error, isA<ToolError>());
    });

    test('ToolExecutionError stores toolName and message', () {
      const error = ToolExecutionError('read', 'file not found');
      expect(error.toolName, 'read');
      expect(error.message, 'file not found');
      expect(error, isA<ToolError>());
    });

    test('all subtypes are distinct', () {
      const notFound = ToolNotFoundError('x');
      const timeout = ToolTimeoutError('x');
      const perm = ToolPermissionDeniedError('x');
      const invalid = ToolInvalidArgsError('x', 'msg');
      const overflow = ToolOverflowError('x', 'msg');
      const execution = ToolExecutionError('x', 'msg');

      final types = [
        notFound,
        timeout,
        perm,
        invalid,
        overflow,
        execution,
      ].map((e) => e.runtimeType).toSet();
      expect(types, hasLength(6));
    });

    test('sealed class exhaustiveness: switch covers all cases', () {
      ToolError classify(ToolError err) => switch (err) {
        ToolNotFoundError() => err,
        ToolTimeoutError() => err,
        ToolPermissionDeniedError() => err,
        ToolInvalidArgsError() => err,
        ToolOverflowError() => err,
        ToolExecutionError() => err,
      };

      const errors = [
        ToolNotFoundError('a'),
        ToolTimeoutError('b'),
        ToolPermissionDeniedError('c'),
        ToolInvalidArgsError('d', 'msg'),
        ToolOverflowError('e', 'msg'),
        ToolExecutionError('f', 'msg'),
      ];

      for (final e in errors) {
        expect(classify(e), equals(e));
      }
    });
  });

  // ── ToolOutput ─────────────────────────────────────────────────────────

  group('ToolOutput', () {
    test('toJson includes output', () {
      const output = ToolOutput('hello');
      final json = output.toJson();
      expect(json['output'], equals('hello'));
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('toJson includes title when present', () {
      const output = ToolOutput('hello', title: 'My Tool');
      final json = output.toJson();
      expect(json['output'], equals('hello'));
      expect(json['title'], equals('My Tool'));
    });

    test('toJson includes metadata when present', () {
      const output = ToolOutput('hello', metadata: {'key': 'value'});
      final json = output.toJson();
      expect(json['output'], equals('hello'));
      expect(json['metadata'], equals({'key': 'value'}));
    });

    test('toJson includes all fields when present', () {
      const output = ToolOutput(
        'result',
        title: 'Test',
        metadata: {'exit_code': 0},
      );
      final json = output.toJson();
      expect(json['output'], equals('result'));
      expect(json['title'], equals('Test'));
      expect(json['metadata'], equals({'exit_code': 0}));
    });
  });

  // ── ToolContext ────────────────────────────────────────────────────────

  group('ToolContext', () {
    test('stores all fields correctly', () {
      final ctx = ToolContext(
        toolCallId: 'call-1',
        sessionId: 'session-1',
        ask:
            ({
              required permission,
              required patterns,
              metadata,
              always,
            }) async {},
        askQuestion:
            ({
              required question,
              List<String> options = const [],
              bool multiple = false,
            }) async => '',
      );

      expect(ctx.toolCallId, equals('call-1'));
      expect(ctx.sessionId, equals('session-1'));
      expect(ctx.abortSignal, isNull);
      expect(ctx.onMetadata, isNull);
    });

    test('optional fields can be null', () {
      const ctx = ToolContext(
        toolCallId: 'call-2',
        sessionId: null,
        ask: _dummyAsk,
        askQuestion: _dummyAskQuestion,
      );

      expect(ctx.sessionId, isNull);
      expect(ctx.abortSignal, isNull);
      expect(ctx.onMetadata, isNull);
    });
  });

  // ── TruncationService ──────────────────────────────────────────────────

  group('TruncationService', () {
    test('returns short output unchanged', () {
      final service = TruncationService.instance;
      const shortText = 'Hello World';
      expect(service.truncate(shortText), equals(shortText));
    });

    test('truncates output exceeding max chars', () {
      final service = TruncationService.instance;
      // Create a string longer than 50000 chars
      final longText = 'A' * 60000;
      final truncated = service.truncate(longText);
      expect(truncated.length, lessThan(longText.length));
      expect(truncated, contains('lines truncated'));
    });

    test('truncation preserves head and tail', () {
      final service = TruncationService.instance;
      final head = 'HEADER_CONTENT_DO_NOT_REMOVE';
      final tail = 'FOOTER_CONTENT_DO_NOT_REMOVE';
      final middle = 'X' * 60000;
      final longText = head + middle + tail;
      final result = service.truncate(longText);

      expect(result, contains('HEADER_CONTENT_DO_NOT_REMOVE'));
      expect(result, contains('FOOTER_CONTENT_DO_NOT_REMOVE'));
    });

    test('truncation includes sentinel with line count', () {
      final service = TruncationService.instance;
      // Create many lines to ensure truncation
      final lines = List.generate(10000, (i) => 'Line $i');
      final longText = lines.join('\n');
      final result = service.truncate(longText);

      expect(result, contains('lines truncated'));
    });

    test('cleanup does not throw', () async {
      final service = TruncationService.instance;
      // Should not throw even if no files exist
      await service.cleanup();
    });
  });

  // ── ToolRegistry ───────────────────────────────────────────────────────

  group('ToolRegistry', () {
    late PermissionService permissions;
    late ToolRegistry registry;

    setUp(() {
      permissions = PermissionService();
      registry = ToolRegistry(permissions, PermissionRuleset.defaults());
    });

    ToolDef _fakeTool(String id, {String description = 'fake'}) {
      return ToolDef(
        id: id,
        description: description,
        inputSchema: {'type': 'object'},
        execute: (input, ctx) async => const ToolOutput('fake'),
      );
    }

    test('register adds tool', () {
      final tool = _fakeTool('test_tool');
      registry.register(tool);
      expect(registry.contains('test_tool'), isTrue);
      expect(registry.all, hasLength(1));
    });

    test('register does not add duplicate', () {
      final tool = _fakeTool('dup_tool');
      registry.register(tool);
      registry.register(tool);
      expect(registry.all, hasLength(1));
    });

    test('get returns tool by id', () {
      final tool = _fakeTool('my_tool', description: 'desc');
      registry.register(tool);
      expect(registry.get('my_tool'), equals(tool));
    });

    test('get returns null for unknown id', () {
      expect(registry.get('unknown'), isNull);
    });

    test('remove deletes tool and returns true', () {
      final tool = _fakeTool('remove_me');
      registry.register(tool);
      expect(registry.remove('remove_me'), isTrue);
      expect(registry.contains('remove_me'), isFalse);
    });

    test('remove returns false for unknown id', () {
      expect(registry.remove('nonexistent'), isFalse);
    });

    test('ids returns all tool ids', () {
      registry.register(_fakeTool('t1'));
      registry.register(_fakeTool('t2'));
      expect(registry.ids, equals(['t1', 't2']));
    });

    test('available filters out denied tools', () {
      final denyRuleset = PermissionRuleset(
        rules: [
          const PermissionRule(
            permission: 'bash',
            pattern: '*',
            action: PermissionAction.deny,
          ),
        ],
      );
      final denyRegistry = ToolRegistry(permissions, denyRuleset);
      denyRegistry.register(_fakeTool('bash'));
      denyRegistry.register(_fakeTool('read'));

      expect(denyRegistry.available.any((t) => t.id == 'bash'), isFalse);
      expect(denyRegistry.available.any((t) => t.id == 'read'), isTrue);
    });

    test('available includes all allowed tools', () {
      registry.register(_fakeTool('read'));
      registry.register(_fakeTool('glob'));
      expect(registry.available.length, equals(2));
    });

    test('toSDKTools returns map with tool entries', () {
      registry.register(_fakeTool('sdk_tool'));
      final sdkTools = registry.toSDKTools();
      expect(sdkTools.containsKey('sdk_tool'), isTrue);
    });

    test('pruneSession does not throw', () {
      registry.register(_fakeTool('t'));
      expect(() => registry.pruneSession('session-1'), returnsNormally);
    });
  });
}

// Dummy functions for ToolContext const constructor
Future<void> _dummyAsk({
  required String permission,
  required List<String> patterns,
  Map<String, dynamic>? metadata,
  List<String>? always,
}) async {}

Future<String> _dummyAskQuestion({
  required String question,
  List<String> options = const [],
  bool multiple = false,
}) async => '';
