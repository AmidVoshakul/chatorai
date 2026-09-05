import 'package:test/test.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/parts/diff_parser.dart';

void main() {
  group('DiffParser', () {
    group('parseUnifiedDiff with oldSource/newSource', () {
      test('identical texts return no hunks', () {
        final hunks = parseUnifiedDiff(oldSource: 'a\nb', newSource: 'a\nb');
        expect(hunks, isEmpty);
      });

      test('pure addition', () {
        final hunks = parseUnifiedDiff(oldSource: 'a', newSource: 'a\nb');
        expect(hunks, hasLength(1));
        final rows = hunks.first.rows;
        expect(rows.first.type, DiffLineType.context);
        expect(rows.last.type, DiffLineType.addition);
        expect(rows.last.newLineNumber, 2);
        expect(rows.last.oldLineNumber, isNull);
      });

      test('pure removal', () {
        final hunks = parseUnifiedDiff(oldSource: 'a\nb', newSource: 'a');
        final rows = hunks.first.rows;
        expect(rows.first.type, DiffLineType.context);
        expect(rows.last.type, DiffLineType.removal);
        expect(rows.last.oldLineNumber, 2);
        expect(rows.last.newLineNumber, isNull);
      });

      test('replacement pairs as modified', () {
        final hunks = parseUnifiedDiff(oldSource: 'a\nb', newSource: 'a\nc');
        final rows = hunks.first.rows;
        expect(rows.first.type, DiffLineType.context);
        expect(rows[1].type, DiffLineType.modified);
        expect(rows[1].oldLineNumber, 2);
        expect(rows[1].newLineNumber, 2);
        expect(rows[1].left, 'b');
        expect(rows[1].right, 'c');
      });

      test('empty sources return empty', () {
        final hunks = parseUnifiedDiff(oldSource: '', newSource: '');
        expect(hunks, isEmpty);
      });

      test('context prefix and suffix preserved', () {
        final hunks = parseUnifiedDiff(
          oldSource: 'a\nb\nc',
          newSource: 'a\nx\nc',
        );
        final rows = hunks.first.rows;
        expect(rows[0].type, DiffLineType.context);
        expect(rows[0].left, 'a');
        expect(rows.last.type, DiffLineType.context);
        expect(rows.last.left, 'c');
      });

      test('trims context to 4 lines around changes', () {
        final oldLines = List.generate(500, (i) => 'line ${i + 1}');
        final newLines = List<String>.from(oldLines);
        newLines[310] = 'changed 311';
        newLines[314] = 'changed 315';
        newLines[319] = 'changed 320';
        final old = oldLines.join('\n');
        final fresh = newLines.join('\n');
        final hunks = parseUnifiedDiff(oldSource: old, newSource: fresh);
        expect(hunks, hasLength(1));
        final rows = hunks.first.rows;
        expect(rows.length, lessThan(30));
        expect(rows.first.oldLineNumber, 307);
        expect(rows.first.newLineNumber, 307);
        expect(rows.last.oldLineNumber, 324);
        expect(rows.last.newLineNumber, 324);
        expect(rows.any((r) => r.type != DiffLineType.context), isTrue);
        expect(
          rows.where((r) => r.type == DiffLineType.context).length,
          greaterThan(0),
        );
      });

      test('trims single change to 4+1+4=9 rows', () {
        final oldLines = List.generate(100, (i) => 'line ${i + 1}');
        final newLines = List<String>.from(oldLines);
        newLines[49] = 'changed 50';
        final old = oldLines.join('\n');
        final fresh = newLines.join('\n');
        final hunks = parseUnifiedDiff(oldSource: old, newSource: fresh);
        expect(hunks, hasLength(1));
        final rows = hunks.first.rows;
        expect(rows.first.oldLineNumber, 46);
        expect(rows.last.oldLineNumber, 54);
        expect(rows, hasLength(9));
      });

      test('pass contextLines=0 returns only changed rows', () {
        final hunks = parseUnifiedDiff(
          oldSource: 'a\nb\nc',
          newSource: 'a\nx\nc',
          contextLines: 0,
        );
        final rows = hunks.first.rows;
        expect(rows, hasLength(1));
        expect(rows.first.type, DiffLineType.modified);
      });
    });

    group('parseUnifiedDiff with patch string', () {
      test('parses unified diff hunk header', () {
        final patch = '''--- a/foo.txt
+++ b/foo.txt
@@ -1,3 +1,3 @@
 context
-removed
+added
 context
''';
        final hunks = parseUnifiedDiff(patch: patch);
        expect(hunks, hasLength(1));
        expect(hunks.first.rows, hasLength(3));
        expect(hunks.first.rows[0].type, DiffLineType.context);
        expect(hunks.first.rows[1].type, DiffLineType.modified);
        expect(hunks.first.rows[1].left, 'removed');
        expect(hunks.first.rows[1].right, 'added');
        expect(hunks.first.rows[2].type, DiffLineType.context);
      });

      test('skips --- and +++ file headers', () {
        final patch = '''--- a/foo.txt
+++ b/foo.txt
@@ -1 +1 @@
-old
+new
''';
        final hunks = parseUnifiedDiff(patch: patch);
        expect(hunks.first.rows, hasLength(1));
        expect(hunks.first.rows[0].type, DiffLineType.modified);
      });

      test('patch with line numbers uses hunk header', () {
        final patch = '''@@ -100,3 +100,3 @@
 context
-old_line
+new_line
 context
''';
        final hunks = parseUnifiedDiff(patch: patch);
        expect(hunks.first.rows[0].oldLineNumber, 100);
        expect(hunks.first.rows[0].newLineNumber, 100);
        expect(hunks.first.rows[1].oldLineNumber, 101);
        expect(hunks.first.rows[1].newLineNumber, 101);
        expect(hunks.first.rows[2].oldLineNumber, 102);
        expect(hunks.first.rows[2].newLineNumber, 102);
      });

      test('empty patch returns empty', () {
        expect(parseUnifiedDiff(patch: ''), isEmpty);
        expect(parseUnifiedDiff(patch: '   '), isEmpty);
      });
    });

    group('DiffRow factories', () {
      test('context factory sets both line numbers', () {
        final row = DiffRow.context(1, 1, 'hello');
        expect(row.type, DiffLineType.context);
        expect(row.oldLineNumber, 1);
        expect(row.newLineNumber, 1);
        expect(row.left, 'hello');
        expect(row.right, 'hello');
      });

      test('addition factory sets newLineNumber only', () {
        final row = DiffRow.addition(5, 'new line');
        expect(row.type, DiffLineType.addition);
        expect(row.oldLineNumber, isNull);
        expect(row.newLineNumber, 5);
        expect(row.right, 'new line');
      });

      test('removal factory sets oldLineNumber only', () {
        final row = DiffRow.removal(3, 'old line');
        expect(row.type, DiffLineType.removal);
        expect(row.oldLineNumber, 3);
        expect(row.newLineNumber, isNull);
        expect(row.left, 'old line');
      });

      test('modified factory sets both sides', () {
        final row = DiffRow.modified(2, 2, 'old', 'new');
        expect(row.type, DiffLineType.modified);
        expect(row.left, 'old');
        expect(row.right, 'new');
      });
    });
  });
}
