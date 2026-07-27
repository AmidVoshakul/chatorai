import 'dart:io';

import 'package:test/test.dart';
import 'package:chatorai/core/tools/built_in/apply_patch.dart';
import 'package:chatorai/core/tools/tool.dart';

void _safeDelete(String path) {
  try {
    File(path).deleteSync(recursive: true);
  } catch (_) {}
}

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
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

String _path(String name) => '${Directory.current.path}/$name';

void main() {
  late ToolDef tool;

  setUp(() {
    tool = createApplyPatchTool();
  });

  group('backward compat (single file)', () {
    test('id is apply_patch', () {
      expect(tool.id, 'apply_patch');
    });

    test('single file patch still works', () async {
      final f = File(_path('ap_single_mf.txt'))
        ..writeAsStringSync('line1\nline2\nline3');
      final patch = '--- a/x\n+++ b/x\n@@ -2,1 +2,1 @@\n-line2\n+modified';
      final result = await tool.execute({
        'patch': patch,
        'file_path': f.path,
      }, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(result.output, contains('Patch successfully applied'));
      final content = await f.readAsString();
      expect(content, contains('modified'));
      f.deleteSync();
    });

    test('backward compat file_path/path alias for old format', () async {
      final f = File(_path('ap_path_alias.txt'))..writeAsStringSync('hello');
      final patch = '@@ -1 +1 @@\n-hello\n+world';
      final result = await tool.execute({
        'patch': patch,
        'path': f.path,
      }, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(await f.readAsString(), 'world');
      f.deleteSync();
    });
  });

  group('envelope format', () {
    test('accepts Begin/End Patch envelope', () async {
      final f = File(_path('ap_env.txt'))..writeAsStringSync('old content');
      final patch = [
        '*** Begin Patch',
        '*** Update File: ${_path('ap_env.txt')}',
        '@@ -1 +1 @@',
        '-old content',
        '+new content',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(await f.readAsString(), 'new content');
      f.deleteSync();
    });

    test('Add File creates new file with content', () async {
      final path = _path('ap_add_new.txt');
      _safeDelete(path);
      final patch = [
        '*** Begin Patch',
        '*** Add File: $path',
        '+line1',
        '+line2',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(result.output, contains('Patch successfully applied'));
      final content = await File(path).readAsString();
      expect(content, contains('line1'));
      expect(content, contains('line2'));
      _safeDelete(path);
    });

    test('Add File with no + lines creates empty file', () async {
      final path = _path('ap_add_empty.txt');
      _safeDelete(path);
      final patch = [
        '*** Begin Patch',
        '*** Add File: $path',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(await File(path).readAsString(), isEmpty);
      _safeDelete(path);
    });

    test('Add File rejects existing file', () async {
      final path = _path('ap_add_existing.txt');
      File(path)..writeAsStringSync('existing');
      final patch = [
        '*** Begin Patch',
        '*** Add File: $path',
        '+new content',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('already exists'));
      _safeDelete(path);
    });

    test('Delete File removes existing file', () async {
      final path = _path('ap_del.txt');
      File(path)..writeAsStringSync('to be deleted');
      final patch = [
        '*** Begin Patch',
        '*** Delete File: $path',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(File(path).existsSync(), isFalse);
    });

    test('Delete File returns error if file does not exist', () async {
      final path = _path('ap_del_missing.txt');
      _safeDelete(path);
      final patch = [
        '*** Begin Patch',
        '*** Delete File: $path',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('not found'));
    });

    test('Update File with Move to renames file', () async {
      final oldPath = _path('ap_move_src.txt');
      final newPath = _path('ap_move_dst.txt');
      File(oldPath)..writeAsStringSync('content');
      _safeDelete(newPath);
      final patch = [
        '*** Begin Patch',
        '*** Update File: $oldPath',
        '*** Move to: $newPath',
        '@@ -1 +1 @@',
        '-content',
        '+modified',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(File(oldPath).existsSync(), isFalse);
      expect(await File(newPath).readAsString(), 'modified');
      _safeDelete(newPath);
    });

    test('Update File without Move to keeps filename', () async {
      final path = _path('ap_update_stays.txt');
      File(path)..writeAsStringSync('old');
      final patch = [
        '*** Begin Patch',
        '*** Update File: $path',
        '@@ -1 +1 @@',
        '-old',
        '+new',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(File(path).existsSync(), isTrue);
      expect(await File(path).readAsString(), 'new');
      _safeDelete(path);
    });

    test('mixed operations in one patch', () async {
      final pathA = _path('ap_mix_a.txt');
      final pathB = _path('ap_mix_b.txt');
      final pathC = _path('ap_mix_c.txt');
      File(pathA)..writeAsStringSync('A');
      File(pathB)..writeAsStringSync('B');
      _safeDelete(pathC);
      final patch = [
        '*** Begin Patch',
        '*** Update File: $pathA',
        '@@ -1 +1 @@',
        '-A',
        '+A_updated',
        '*** Delete File: $pathB',
        '*** Add File: $pathC',
        '+C_created',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isNull);
      expect(await File(pathA).readAsString(), 'A_updated');
      expect(File(pathB).existsSync(), isFalse);
      expect(await File(pathC).readAsString(), 'C_created');
      _safeDelete(pathA);
      _safeDelete(pathC);
    });

    test('rollback on partial failure (delete not found)', () async {
      final pathA = _path('ap_rollback_a.txt');
      final pathB = _path('ap_rollback_b.txt');
      File(pathA)..writeAsStringSync('A');
      File(pathB)..writeAsStringSync('B');
      final patch = [
        '*** Begin Patch',
        '*** Update File: $pathA',
        '@@ -1 +1 @@',
        '-A',
        '+A_updated',
        '*** Delete File: nonexistent_file.txt',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('rolled back'));
      expect(await File(pathA).readAsString(), 'A');
      expect(await File(pathA).readAsString(), isNot('A_updated'));
      _safeDelete(pathA);
      _safeDelete(pathB);
    });

    test('rollback on partial failure (add existing)', () async {
      final pathA = _path('ap_rollback2_a.txt');
      final pathB = _path('ap_rollback2_b.txt');
      File(pathA)..writeAsStringSync('A');
      File(pathB)..writeAsStringSync('B');
      final patch = [
        '*** Begin Patch',
        '*** Update File: $pathA',
        '@@ -1 +1 @@',
        '-A',
        '+A_updated',
        '*** Add File: $pathB',
        '+overwrite_attempt',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('rolled back'));
      expect(await File(pathA).readAsString(), 'A');
      _safeDelete(pathA);
      _safeDelete(pathB);
    });
  });

  group('error handling', () {
    test('returns error when patch is empty', () async {
      final result = await tool.execute({}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('patch is required'));
    });

    test('returns error on unknown operation', () async {
      final patch = [
        '*** Begin Patch',
        '*** Unknown: some_file.txt',
        '+content',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('Unknown operation'));
    });

    test('returns error on missing End Patch', () async {
      final patch = [
        '*** Begin Patch',
        '*** Add File: some_file.txt',
        '+content',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('missing'));
    });

    test('Update File reports patch context mismatch', () async {
      final path = _path('ap_ctx_err.txt');
      File(path)..writeAsStringSync('alpha');
      final patch = [
        '*** Begin Patch',
        '*** Update File: $path',
        '@@ -1 +1 @@',
        '-wrong_context',
        '+replacement',
        '*** End Patch',
      ].join('\n');
      final result = await tool.execute({'patch': patch}, _mockCtx());
      expect(result.metadata?['error'], isTrue);
      expect(result.output, contains('patch context mismatch'));
      _safeDelete(path);
    });
  });
}
