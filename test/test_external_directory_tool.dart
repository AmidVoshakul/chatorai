import 'package:chatorai/features/chat/data/models/chat/question_option.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/external_directory.dart';
import 'package:path/path.dart' as p;

class _AskRecord {
  final String permission;
  final List<String> patterns;
  final Map<String, dynamic> metadata;
  final List<String> always;
  _AskRecord({
    required this.permission,
    required this.patterns,
    required this.metadata,
    required this.always,
  });
}

ToolContext _fakeContext(List<_AskRecord> asks) {
  return ToolContext(
    toolCallId: 'test-call',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {
          asks.add(
            _AskRecord(
              permission: permission,
              patterns: List.from(patterns),
              metadata: Map.from(metadata ?? {}),
              always: List.from(always ?? []),
            ),
          );
        },
    askQuestion:
        ({
          required question,
          List<QuestionOption> options = const [],
          bool multiple = false,
        }) async => '',
  );
}

void main() {
  group('createExternalDirectoryTool', () {
    late ToolDef tool;

    setUp(() {
      tool = createExternalDirectoryTool();
    });

    test('returns ok without asking when path is null', () async {
      final asks = <_AskRecord>[];
      final ctx = _fakeContext(asks);
      final result = await tool.execute({}, ctx);
      expect(result.output, equals('ok'));
      expect(asks, isEmpty);
    });

    test('returns ok without asking when path is empty string', () async {
      final asks = <_AskRecord>[];
      final ctx = _fakeContext(asks);
      final result = await tool.execute({'path': ''}, ctx);
      expect(result.output, equals('ok'));
      expect(asks, isEmpty);
    });

    test('returns ok without asking for internal workspace path', () async {
      final asks = <_AskRecord>[];
      final ctx = _fakeContext(asks);
      final wsPath = Directory.current.path;
      final result = await tool.execute({
        'path': p.join(wsPath, 'lib', 'main.dart'),
      }, ctx);
      expect(result.output, equals('ok'));
      expect(asks, isEmpty);
    });

    test('asks for permission when path is outside workspace', () async {
      final asks = <_AskRecord>[];
      final ctx = _fakeContext(asks);
      final result = await tool.execute({
        'path': '/tmp/external_file.txt',
      }, ctx);
      expect(result.output, equals('ok'));
      expect(asks.length, equals(1));
      expect(asks.first.permission, equals('external_directory'));
      expect(asks.first.patterns, contains('/tmp/*'));
      expect(asks.first.always, contains('/tmp/*'));
      expect(asks.first.metadata['filepath'], equals('/tmp/external_file.txt'));
      expect(asks.first.metadata['rule'], equals('ask'));
    });

    test('skips permission when bypass=true', () async {
      final asks = <_AskRecord>[];
      final ctx = _fakeContext(asks);
      final result = await tool.execute({
        'path': '/tmp/external_file.txt',
        'bypass': true,
      }, ctx);
      expect(result.output, equals('ok'));
      expect(asks, isEmpty);
    });

    test('metadata contains parentDir for external path', () async {
      final asks = <_AskRecord>[];
      final ctx = _fakeContext(asks);
      await tool.execute({'path': '/tmp/external/file.txt'}, ctx);
      expect(asks.first.metadata['parentDir'], equals('/tmp/external'));
    });

    test('tool id and description are set correctly', () {
      expect(tool.id, equals('external-directory'));
      expect(tool.description, isNotEmpty);
    });

    test('schema has path and bypass fields', () {
      final schema = tool.inputSchema;
      final props = schema['properties'] as Map<String, dynamic>;
      expect(props.containsKey('path'), isTrue);
      expect(props.containsKey('bypass'), isTrue);
    });
  });
}
