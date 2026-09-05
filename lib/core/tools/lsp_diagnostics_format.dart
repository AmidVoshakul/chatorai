import 'package:chatorai/core/lsp/lsp_types.dart';

const _lspBlockHeader = '\nLSP errors detected in this file, please fix:\n';

/// Format LSP diagnostics for inclusion in tool output.
///
/// Returns a human-readable string describing any diagnostics found,
/// followed by an XML block with the same data for LLM consumption.
/// When [diagnostics] is empty, returns a message indicating no errors.
String formatLspDiagnostics(List<LspDiagnosticLine> diagnostics) {
  if (diagnostics.isEmpty) return 'No LSP errors detected.';
  final buf = StringBuffer(_lspBlockHeader);
  for (final d in diagnostics) {
    buf.writeln(d.toString());
  }
  buf.writeln();
  buf.write(formatLspDiagnosticsXml(diagnostics));
  return buf.toString().trimRight();
}

/// Format LSP diagnostics as an XML snippet for machine consumption.
///
/// Format:
/// ```
/// <diagnostics file="path/to/file">
/// <error line="5" column="10" message="some error"/>
/// <warning line="8" column="3" message="some warning"/>
/// </diagnostics>
/// ```
String formatLspDiagnosticsXml(
  List<LspDiagnosticLine> diagnostics, {
  String? filePath,
}) {
  final buf = StringBuffer();
  if (filePath != null) {
    buf.writeln('<diagnostics file="$filePath">');
  } else {
    buf.writeln('<diagnostics>');
  }
  for (final d in diagnostics) {
    final escapedMsg = d.message
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll('\r', '&#13;')
        .replaceAll('\n', '&#10;');
    final tag = switch (d.severity.toLowerCase()) {
      'error' => 'error',
      'warning' => 'warning',
      'info' => 'info',
      'hint' => 'hint',
      _ => 'diagnostic',
    };
    buf.writeln(
      '<$tag line="${d.line}" column="${d.column}" message="$escapedMsg"/>',
    );
  }
  buf.write('</diagnostics>');
  return buf.toString();
}

/// Parse LSP diagnostics block from tool output text back into a map
/// keyed by 1-based line number.
///
/// The expected input format is the output of [formatLspDiagnostics]:
/// ```
/// LSP errors detected in this file, please fix:
/// [ ERROR ] 5:10 — some message
/// [ Warning ] 8:3 — some warning
/// ```
Map<int, List<LspDiagnostic>> parseLspFromToolOutput(String text) {
  final result = <int, List<LspDiagnostic>>{};
  final lines = text.split('\n').map((l) => l.replaceAll('\r', '')).toList();
  final regex = RegExp(r'^\[ (\w+) \] (\d+):(\d+) — (.+)$');
  for (final line in lines) {
    final match = regex.firstMatch(line);
    if (match == null) continue;
    final severityLabel = match.group(1)!;
    final lineNum = int.parse(match.group(2)!);
    final colNum = int.parse(match.group(3)!);
    final message = match.group(4)!;

    final severity = switch (severityLabel) {
      'Error' || 'ERROR' => 1,
      'Warning' || 'WARN' => 2,
      'Info' || 'INFO' => 3,
      'Hint' || 'HINT' => 4,
      _ => 1,
    };

    final diag = LspDiagnostic(
      range: LspRange(
        start: LspPosition(line: lineNum - 1, character: colNum - 1),
        end: LspPosition(line: lineNum - 1, character: colNum - 1),
      ),
      severity: severity,
      message: message,
    );
    result.putIfAbsent(lineNum, () => []).add(diag);
  }
  return result;
}

/// Remove LSP diagnostics block from tool output text.
/// Strips the header and any trailing whitespace before it.
String stripLspFromToolOutput(String text) {
  final idx = text.indexOf(_lspBlockHeader);
  if (idx == -1) return text;
  return text.substring(0, idx).trimRight();
}
