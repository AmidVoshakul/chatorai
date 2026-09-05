import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/tools/built_in/edit.dart';
import 'package:chatorai/core/tools/built_in/write.dart';
import 'package:chatorai/core/tools/built_in/apply_patch.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/format/format_service.dart';
import 'package:chatorai/core/chat/chat/question_option.dart';

String _tempDir() {
  final d = Directory('test/temp_format_workspace');
  if (!d.existsSync()) d.createSync(recursive: true);
  return d.path;
}

void _cleanup() {
  final d = Directory('test/temp_format_workspace');
  if (d.existsSync()) d.deleteSync(recursive: true);
}

ToolContext makeCtx() => ToolContext(
  ask:
      ({
        required String permission,
        required List<String> patterns,
        Map<String, dynamic>? metadata,
        List<String>? always,
      }) async {},
  askQuestion:
      ({
        required String question,
        List<QuestionOption>? options,
        bool multiple = false,
      }) async => '',
  toolCallId: 'test-call',
  sessionId: 'test-session',
);

void main() {
  setUp(() => _cleanup());
  tearDown(() => _cleanup());

  group('edit tool', () {
    test('succeeds with formatService: null (backward compat)', () async {
      _writeFile('test.dart', 'void main(){print("hi");}');
      final tool = createEditTool();
      final r = await tool.execute({
        'file_path': '${_tempDir()}/test.dart',
        'old_string': 'print("hi")',
        'new_string': 'print("hello")',
        'replace_all': false,
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });

    test('calls applyFix without crashing', () async {
      _writeFile('test.dart', 'void main(){print("hi");}');
      final tool = createEditTool(formatService: FormatService());
      final r = await tool.execute({
        'file_path': '${_tempDir()}/test.dart',
        'old_string': 'print("hi")',
        'new_string': 'print("hello")',
        'replace_all': false,
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });
  });

  group('write tool', () {
    test('succeeds with formatService: null (backward compat)', () async {
      final tool = createWriteTool();
      final r = await tool.execute({
        'file_path': '${_tempDir()}/test.dart',
        'content': 'void main(){print("hi");}',
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });

    test('calls applyFix without crashing', () async {
      final tool = createWriteTool(formatService: FormatService());
      final r = await tool.execute({
        'file_path': '${_tempDir()}/test.dart',
        'content': 'void main(){print("hi");}',
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });
  });

  group('apply_patch tool', () {
    test('succeeds with formatService: null (backward compat)', () async {
      _writeFile('test.dart', 'void main(){print("hi");}');
      final tool = createApplyPatchTool();
      final r = await tool.execute({
        'file_path': '${_tempDir()}/test.dart',
        'patch':
            '@@ -1 +1 @@\n-void main(){print("hi");}\n+void main(){print("hello");}',
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });

    test('calls applyFix without crashing (single-file)', () async {
      _writeFile('test.dart', 'void main(){print("hi");}');
      final tool = createApplyPatchTool(formatService: FormatService());
      final r = await tool.execute({
        'file_path': '${_tempDir()}/test.dart',
        'patch':
            '@@ -1 +1 @@\n-void main(){print("hi");}\n+void main(){print("hello");}',
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });

    test('calls applyFix without crashing (multi-file envelope)', () async {
      _writeFile('file_a.dart', 'void main(){print("a");}');
      _writeFile('file_b.dart', 'void main(){print("b");}');
      final ws = _tempDir();
      final tool = createApplyPatchTool(formatService: FormatService());
      final r = await tool.execute({
        'patch':
            '''*** Begin Patch
*** Update File: $ws/file_a.dart
--- a/file_a.dart
+++ b/file_a.dart
@@ -1 +1 @@
-void main(){print("a");}
+void main(){print("A");}
*** Update File: $ws/file_b.dart
--- a/file_b.dart
+++ b/file_b.dart
@@ -1 +1 @@
-void main(){print("b");}
+void main(){print("B");}
*** End Patch''',
      }, makeCtx());
      expect(r.metadata?['error'], isNot(true));
    });
  });
}

String _writeFile(String name, String content) {
  final f = File('${_tempDir()}/$name');
  f.createSync(recursive: true);
  f.writeAsStringSync(content);
  return f.path;
}
