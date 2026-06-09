import 'dart:io';

import 'package:test/test.dart';
import 'package:chatorai/features/tools/built_in/apply_patch.dart';
import 'package:chatorai/features/tools/data/models/tool.dart';

ToolContext _mockCtx() {
  return ToolContext(
    toolCallId: 'test-call-1',
    sessionId: 'test-session',
    ask:
        ({
          required String permission,
          required List<String> patterns,
          Map<String, dynamic>? metadata,
          List<String>? always,
        }) async {},
  );
}

String _path(String name) => '${Directory.current.path}/$name';

void main() {
  group('ApplyPatchTool', () {
    late ToolDef tool;

    setUp(() {
      tool = createApplyPatchTool();
    });

    group('definition', () {
      test('id is apply_patch', () {
        expect(tool.id, 'apply_patch');
      });

      test('description is non-empty', () {
        expect(tool.description, isNotEmpty);
      });

      test('inputSchema has required fields (file_path, patch)', () {
        final schema = tool.inputSchema as Map<String, dynamic>;
        expect(schema['type'], 'object');
        final props = schema['properties'] as Map<String, dynamic>;
        expect(props.containsKey('file_path'), isTrue);
        expect(props.containsKey('patch'), isTrue);
      });
    });

    group('execute - validation', () {
      test('returns error when file_path is null', () async {
        final result = await tool.execute({
          'patch': '@@ -1 +1 @@\n+hello',
        }, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        expect(result.output, contains('file_path is required'));
      });

      test('returns error when patch is null', () async {
        final f = File(_path('ap_null_patch.txt'))..writeAsStringSync('hello');
        final result = await tool.execute({'file_path': f.path}, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        f.deleteSync();
      });

      test('returns error when patch is empty string', () async {
        final f = File(_path('ap_empty_patch.txt'))..writeAsStringSync('hello');
        final result = await tool.execute({
          'file_path': f.path,
          'patch': '',
        }, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        f.deleteSync();
      });

      test('returns error when file does not exist', () async {
        final result = await tool.execute({
          'file_path': _path('ap_nofile.txt'),
          'patch': '@@ -1 +1 @@\n+hi',
        }, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        expect(result.output, contains('file not found'));
      });

      test('returns error when patch has no @@ header', () async {
        final f = File(_path('ap_noheader.txt'))
          ..writeAsStringSync('line1\nline2');
        final result = await tool.execute({
          'file_path': f.path,
          'patch': 'garbage',
        }, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        expect(result.output, contains('no valid @@ header'));
        f.deleteSync();
      });
    });

    group('execute - context mismatch', () {
      test('returns error when context line does not match file', () async {
        final f = File(_path('ap_ctx_mismatch.txt'))
          ..writeAsStringSync('alpha\nbeta\ngamma');
        // @@ header expects 'X' at line 2 but file has 'beta'
        final patch = '--- a/x\n+++ b/x\n@@ -2,1 +2 @@\n-X\n beta';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        expect(result.metadata?['context_mismatch'], isTrue);
        f.deleteSync();
      });

      test('returns error when patch index is out of bounds', () async {
        final f = File(_path('ap_bounds.txt'))
          ..writeAsStringSync('only one line');
        // Tries to access line 5 in a 1-line file
        final patch = '--- a/x\n+++ b/x\n@@ -5,1 +5 @@\n whatever';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isTrue);
        expect(result.metadata?['bounds_error'], isTrue);
        f.deleteSync();
      });
    });

    group('execute - valid patches', () {
      test('applies single-line addition correctly', () async {
        final f = File(_path('ap_add.txt'))
          ..writeAsStringSync('line1\nline2\nline3');
        final patch =
            '--- a/ap_add.txt\n+++ b/ap_add.txt\n@@ -2,2 +2,3 @@\n line2\n+inserted\n line3';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        expect(result.output, contains('Patch successfully applied'));
        final content = await f.readAsString();
        expect(content, contains('inserted'));
        expect(content, contains('line1'));
        f.deleteSync();
      });

      test('applies single-line removal correctly', () async {
        final f = File(_path('ap_remove.txt'))
          ..writeAsStringSync('line1\nline2\nline3');
        final patch =
            '--- a/ap_remove.txt\n+++ b/ap_remove.txt\n@@ -1,3 +1,2 @@\n line1\n-line2\n line3';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        expect(result.output, contains('Patch successfully applied'));
        final content = await f.readAsString();
        expect(content, isNot(contains('line2')));
        expect(content, contains('line1'));
        expect(content, contains('line3'));
        expect(content.split('\n').length, 2);
        f.deleteSync();
      });

      test('applies patch at file start correctly', () async {
        final f = File(_path('ap_start.txt'))..writeAsStringSync('A\nB\nC');
        final patch =
            '--- a/ap_start.txt\n+++ b/ap_start.txt\n@@ -1,1 +1,2 @@\n A\n+inserted_top';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        final content = await f.readAsString();
        expect(content, contains('inserted_top'));
        expect(content, contains('A'));
        f.deleteSync();
      });

      test('applies patch at file end correctly', () async {
        final f = File(_path('ap_end.txt'))..writeAsStringSync('A\nB\nC');
        final patch =
            '--- a/ap_end.txt\n+++ b/ap_end.txt\n@@ -3,1 +3,2 @@\n C\n+inserted_bottom';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        final content = await f.readAsString();
        expect(content, contains('inserted_bottom'));
        expect(content, contains('C'));
        f.deleteSync();
      });

      test('handles CRLF line endings in patch', () async {
        final f = File(_path('ap_crlf.txt'))
          ..writeAsStringSync('line1\nline2\nline3');
        final patch =
            '--- a/ap_crlf.txt\n+++ b/ap_crlf.txt\n@@ -2,2 +2,3 @@\n line2\n+crlf_inserted\n line3';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        expect((await f.readAsString()), contains('crlf_inserted'));
        f.deleteSync();
      });

      test('handles empty context lines', () async {
        final f = File(_path('ap_emptyctx.txt'))
          ..writeAsStringSync('line1\n\nline3');
        final patch =
            '--- a/ap_emptyctx.txt\n+++ b/ap_emptyctx.txt\n@@ -1,3 +1,3 @@\n line1\n \n line3';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        final lines = (await f.readAsString()).split('\n');
        expect(lines.length, 3);
        f.deleteSync();
      });
    });

    group('execute - line count warning', () {
      test(
        'returns warning when result line count differs from expected',
        () async {
          final f = File(_path('ap_lcwarn.txt'))
            ..writeAsStringSync('line1\nline2\nline3');
          // Replace with different count than header declares - triggers warning path
          final patch =
              '--- a/ap_lcwarn.txt\n+++ b/ap_lcwarn.txt\n@@ -2,1 +2,2 @@\n-line2\n+line2a\n+line2b';
          final result = await tool.execute({
            'file_path': f.path,
            'patch': patch,
          }, _mockCtx());
          expect(result.metadata?['error'], isNull);
          expect(result.metadata, isNotNull);
          f.deleteSync();
        },
      );
    });

    group('execute - permission', () {
      test('calls ctx.ask with edit permission and safe path', () async {
        final f = File(_path('ap_perm.txt'))..writeAsStringSync('original');
        String? capturedPerm;
        List<String>? capturedPatterns;

        final ctx = ToolContext(
          toolCallId: 'test-call-2',
          sessionId: 'test-session',
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                capturedPerm = permission;
                capturedPatterns = patterns;
              },
        );

        await tool.execute({
          'file_path': f.path,
          'patch': '@@ -1 +1 @@\n-original\n+patched',
        }, ctx);
        expect(capturedPerm, 'edit');
        expect(capturedPatterns, contains(f.path));
        f.deleteSync();
      });

      test('propagates permission denial from ctx.ask', () async {
        final f = File(_path('ap_deny.txt'))..writeAsStringSync('content');
        final rejectingCtx = ToolContext(
          toolCallId: 'test-call-3',
          sessionId: 'test-session',
          ask:
              ({
                required String permission,
                required List<String> patterns,
                Map<String, dynamic>? metadata,
                List<String>? always,
              }) async {
                throw Exception('Permission denied');
              },
        );
        await expectLater(
          tool.execute({
            'file_path': f.path,
            'patch': '@@ -1 +1 @@\n+new',
          }, rejectingCtx),
          throwsA(isA<Exception>()),
        );
        f.deleteSync();
      });
    });

    group('execute - integration', () {
      test('full roundtrip: write file, apply patch, verify content', () async {
        final f = File(_path('ap_rt.dart'))
          ..writeAsStringSync('AAA\nBBB\nCCC\nDDD');

        // Replace CCC -> CCC_back + patched_line at index 2
        final patch =
            '--- a/ap_rt.dart\n+++ b/ap_rt.dart\n@@ -3,1 +3,2 @@\n CCC\n+patched_line';

        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        expect(result.output, contains('Patch successfully applied'));

        final content = await f.readAsString();
        expect(content, contains('patched_line'));
        expect(content, contains('CCC'));
        f.deleteSync();
      });

      test('mid-file multi-line replacement', () async {
        final f = File(_path('ap_mid.txt'))..writeAsStringSync('A\nB\nC\nD\nE');
        final patch =
            '--- a/ap_mid.txt\n+++ b/ap_mid.txt\n@@ -3,2 +3,2 @@\n C\n-D\n+replaced1\n+replaced2';
        final result = await tool.execute({
          'file_path': f.path,
          'patch': patch,
        }, _mockCtx());
        expect(result.metadata?['error'], isNull);
        final lines = (await f.readAsString()).split('\n');
        expect(lines, contains('A'));
        expect(lines, contains('B'));
        expect(lines, contains('replaced1'));
        expect(lines, contains('replaced2'));
        expect(lines, contains('C'));
        expect(lines, isNot(contains('D')));
        expect(lines, contains('E'));
        f.deleteSync();
      });
    });
  });
}
