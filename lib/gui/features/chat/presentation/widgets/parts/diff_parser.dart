import 'dart:math';

import 'package:dartdiff/dartdiff.dart';

enum DiffLineType { context, addition, removal, modified }

class DiffRow {
  final DiffLineType type;
  final int? oldLineNumber;
  final int? newLineNumber;
  final String left;
  final String right;

  const DiffRow({
    required this.type,
    this.oldLineNumber,
    this.newLineNumber,
    required this.left,
    required this.right,
  });

  factory DiffRow.context(int oldLine, int newLine, String text) => DiffRow(
    type: DiffLineType.context,
    oldLineNumber: oldLine,
    newLineNumber: newLine,
    left: text,
    right: text,
  );

  factory DiffRow.addition(int newLine, String text) => DiffRow(
    type: DiffLineType.addition,
    newLineNumber: newLine,
    left: '',
    right: text,
  );

  factory DiffRow.removal(int oldLine, String text) => DiffRow(
    type: DiffLineType.removal,
    oldLineNumber: oldLine,
    left: text,
    right: '',
  );

  factory DiffRow.modified(
    int oldLine,
    int newLine,
    String left,
    String right,
  ) => DiffRow(
    type: DiffLineType.modified,
    oldLineNumber: oldLine,
    newLineNumber: newLine,
    left: left,
    right: right,
  );
}

class DiffHunk {
  final List<DiffRow> rows;

  const DiffHunk({required this.rows});
}

List<DiffHunk> parseUnifiedDiff({
  String? patch,
  String? oldSource,
  String? newSource,
  int contextLines = 4,
  int? fileStartLine,
}) {
  if (patch != null && patch.isNotEmpty) return _parsePatchString(patch);
  if (oldSource != null && newSource != null) {
    return _parseOldNew(
      oldSource,
      newSource,
      contextLines,
      fileStartLine: fileStartLine,
    );
  }
  return [];
}

String trimDiff(String diff) {
  final lines = diff.split('\n');
  String? commonPrefix;

  for (final line in lines) {
    if (line.startsWith('---') || line.startsWith('+++')) continue;
    if (line.trim().isEmpty) continue;
    final match = RegExp(r'^[+ \-](\s*)').firstMatch(line);
    if (match == null) continue;
    final ws = match.group(1)!;
    if (commonPrefix == null) {
      commonPrefix = ws;
    } else {
      var i = 0;
      while (i < commonPrefix.length &&
          i < ws.length &&
          commonPrefix[i] == ws[i]) {
        i++;
      }
      commonPrefix = commonPrefix.substring(0, i);
    }
  }

  if (commonPrefix == null || commonPrefix.isEmpty) return diff;

  return lines
      .map((line) {
        if (line.startsWith('---') || line.startsWith('+++')) return line;
        if (line.trim().isEmpty) return line;
        if (line.isNotEmpty &&
            (line[0] == ' ' || line[0] == '+' || line[0] == '-')) {
          return line[0] + line.substring(1).substring(commonPrefix!.length);
        }
        return line;
      })
      .join('\n');
}

List<DiffHunk> _parseOldNew(
  String oldSource,
  String newSource,
  int contextLines, {
  int? fileStartLine,
}) {
  if (oldSource == newSource) return [];
  String normEndings(String s) => (s.isEmpty || s.endsWith('\n')) ? s : '$s\n';
  final patch = createPatch(
    '',
    normEndings(oldSource),
    normEndings(newSource),
    context: contextLines,
    headerOptions: omitHeaders,
  );
  if (patch == null || patch.isEmpty) return [];
  final lineOffset = fileStartLine != null && fileStartLine > 1
      ? fileStartLine - 1
      : 0;
  return _parsePatchString(patch, lineOffset: lineOffset);
}

List<DiffHunk> _parsePatchString(String patch, {int lineOffset = 0}) {
  List<StructuredPatch> patches;
  try {
    patches = parsePatch(patch);
  } catch (_) {
    return [];
  }
  if (patches.isEmpty) return [];

  final hunks = <DiffHunk>[];
  for (final sp in patches) {
    for (final hunk in sp.hunks) {
      final rows = _hunkLinesToRows(hunk, lineOffset: lineOffset);
      if (rows.isEmpty) continue;
      hunks.add(DiffHunk(rows: rows));
    }
  }
  return hunks;
}

List<DiffRow> _hunkLinesToRows(StructuredPatchHunk hunk, {int lineOffset = 0}) {
  final rows = <DiffRow>[];
  var oldLineNum = hunk.oldStart + lineOffset;
  var newLineNum = hunk.newStart + lineOffset;

  var i = 0;
  while (i < hunk.lines.length) {
    final line = hunk.lines[i];
    if (line.startsWith('\\')) {
      i++;
      continue;
    }

    final op = line.isNotEmpty ? line[0] : ' ';
    final content = line.isNotEmpty ? line.substring(1) : line;

    if (op == ' ') {
      rows.add(DiffRow.context(oldLineNum, newLineNum, content));
      oldLineNum++;
      newLineNum++;
      i++;
    } else if (op == '-') {
      final removals = <String>[];
      final oldStart = oldLineNum;
      while (i < hunk.lines.length && hunk.lines[i].startsWith('-')) {
        removals.add(hunk.lines[i].substring(1));
        oldLineNum++;
        i++;
      }

      final additions = <String>[];
      final newStart = newLineNum;
      while (i < hunk.lines.length && hunk.lines[i].startsWith('+')) {
        additions.add(hunk.lines[i].substring(1));
        newLineNum++;
        i++;
      }

      final maxLen = max(removals.length, additions.length);
      for (var k = 0; k < maxLen; k++) {
        final hasOld = k < removals.length;
        final hasNew = k < additions.length;
        if (hasOld && hasNew) {
          rows.add(
            DiffRow.modified(
              oldStart + k,
              newStart + k,
              removals[k],
              additions[k],
            ),
          );
        } else if (hasOld) {
          rows.add(DiffRow.removal(oldStart + k, removals[k]));
        } else {
          rows.add(DiffRow.addition(newStart + k, additions[k]));
        }
      }
    } else if (op == '+') {
      rows.add(DiffRow.addition(newLineNum, content));
      newLineNum++;
      i++;
    } else {
      i++;
    }
  }

  return rows;
}
