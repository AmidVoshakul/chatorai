import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/document_extract.dart';
import 'package:chatorai/core/tools/document_extractor_service.dart';

ToolContext _mockCtx() {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
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
          List<dynamic>? options,
          bool multiple = false,
        }) async => '',
  );
}

void main() {
  late Directory testDir;

  setUp(() {
    testDir = Directory('test/temp_doc_extract_pdf');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('document_extract_pdf', () {
    test('description is non-empty', () {
      final tool = createDocumentExtractPdfTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema requires file_path', () {
      final tool = createDocumentExtractPdfTool();
      final schema = tool.inputSchema;
      expect((schema['properties'] as Map).containsKey('file_path'), isTrue);
      expect((schema['required'] as List).contains('file_path'), isTrue);
    });

    test('inputSchema has pages field', () {
      final tool = createDocumentExtractPdfTool();
      final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('pages'), isTrue);
      expect(properties['pages']['type'], equals('array'));
      expect(properties['pages']['items']['minimum'], equals(1));
    });

    test('inputSchema has render_scale default 1.5', () {
      final tool = createDocumentExtractPdfTool();
      final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(properties['render_scale']['default'], equals(1.5));
    });

    test('execute with missing file_path returns error', () async {
      final tool = createDocumentExtractPdfTool();
      final output = await tool.execute({}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('execute with non-existent file returns error', () async {
      final tool = createDocumentExtractPdfTool();
      final output = await tool.execute({
        'file_path': '${testDir.path}/nonexistent.pdf',
      }, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('not found'));
    });

    test('pdf returns text', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMinimalPdf('Hello from PDF');
      final testFile = File('${testDir.path}/test.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Hello from PDF'));
      expect(output.output, contains('Page 1'));
    });

    test('pdf with pages range returns only that range', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMultiPagePdf([
        'Page One',
        'Page Two',
        'Page Three',
      ]);
      final testFile = File('${testDir.path}/multi.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({
        'file_path': testFile.path,
        'pages': [2, 3],
      }, ctx);
      expect(output.output, contains('Page 2'));
      expect(output.output, contains('Page Three'));
      expect(output.output, isNot(contains('Page One')));
    });

    test('pdf returns base64 png when pdfrx available', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMinimalPdf('PDF with render');
      final testFile = File('${testDir.path}/render.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, contains('PDF with render'));
      if (DocumentExtractorService.pdfrxAvailable) {
        expect(output.output, contains('data:image/png;base64'));
      }
    });

    test('execute with empty file_path returns error', () async {
      final tool = createDocumentExtractPdfTool();
      final output = await tool.execute({'file_path': ''}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('execute with whitespace-only file_path returns error', () async {
      final tool = createDocumentExtractPdfTool();
      final output = await tool.execute({'file_path': '   '}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('pdf with comma-separated path uses first path', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMinimalPdf('First path');
      final testFile = File('${testDir.path}/first.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({
        'file_path': '${testFile.path},/nonexistent/fake.pdf',
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('First path'));
    });

    test('pdf with glob pattern resolves to first match', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMinimalPdf('Glob match');
      final testFile = File('${testDir.path}/glob_target.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({
        'file_path': '${testDir.path}/glob_*.pdf',
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Glob match'));
    });

    test('pdf with glob pattern returns error when no match', () async {
      final tool = createDocumentExtractPdfTool();
      final output = await tool.execute({
        'file_path': '${testDir.path}/zzz_no_match_*.pdf',
      }, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('not found'));
    });

    test('pdf with corrupt bytes returns error or empty output', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final testFile = File('${testDir.path}/corrupt.pdf');
      await testFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      // corrupt data either throws (caught → error) or extracts empty content
      final hasError = output.metadata?['error'] == true;
      final hasErrorText = output.output.toLowerCase().contains('error');
      final isEmpty = output.output.trim().isEmpty;
      expect(hasError || hasErrorText || isEmpty, isTrue);
    });

    test('pdf metadata includes type and file_paths', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMinimalPdf('Meta check');
      final testFile = File('${testDir.path}/meta.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['type'], equals('pdf'));
      final paths = output.metadata?['file_paths'] as List?;
      expect(paths, isA<List>());
      expect(paths, isNotEmpty);
      // path is resolved to absolute by the tool
      expect(paths!.first, endsWith('meta.pdf'));
    });

    test('output starts with filename header', () async {
      final tool = createDocumentExtractPdfTool();
      final ctx = _mockCtx();

      final pdfBytes = _createMinimalPdf('Header check');
      final testFile = File('${testDir.path}/header.pdf');
      await testFile.writeAsBytes(pdfBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, startsWith('# header.pdf'));
    });
  });
}

Uint8List _createMinimalPdf(String text) {
  final content =
      '''BT
/F1 12 Tf
100 700 Td
($text) Tj
ET
''';

  final body = StringBuffer();
  final objOffsets = <int>[];

  void writeObj(int objNum, String content) {
    objOffsets.add(body.length);
    body.write(content);
  }

  writeObj(1, '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
  writeObj(2, '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
  writeObj(
    3,
    '3 0 obj\n'
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
    '/Contents 4 0 R '
    '/Resources << /Font << /F1 5 0 R >> >> >>\n'
    'endobj\n',
  );
  writeObj(
    4,
    '4 0 obj\n'
    '<< /Length ${content.length} >>\n'
    'stream\n$content'
    'endstream\n'
    'endobj\n',
  );
  writeObj(
    5,
    '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
  );

  final bodyStr = body.toString();
  final xrefOffset = '%PDF-1.4\n'.length + bodyStr.length;

  final xrefEntries = StringBuffer();
  xrefEntries.writeln('xref');
  xrefEntries.writeln('0 ${objOffsets.length + 1}');
  xrefEntries.writeln('0000000000 65535 f ');
  for (final offset in objOffsets) {
    xrefEntries.writeln('${offset.toString().padLeft(10)} 00000 n ');
  }

  final buffer = StringBuffer();
  buffer.writeln('%PDF-1.4');
  buffer.write(bodyStr);
  buffer.write(xrefEntries.toString());
  buffer.writeln('trailer');
  buffer.writeln('<< /Size ${objOffsets.length + 1} /Root 1 0 R >>');
  buffer.writeln('startxref');
  buffer.writeln('$xrefOffset');
  buffer.writeln('%%EOF');

  return Uint8List.fromList(buffer.toString().codeUnits);
}

Uint8List _createMultiPagePdf(List<String> pageTexts) {
  final numPages = pageTexts.length;
  final fontObj = 4 + numPages * 2;

  final body = StringBuffer();
  final objOffsets = <int, int>{};
  var maxObjNum = 0;

  void writeObj(int objNum, String content) {
    maxObjNum = objNum > maxObjNum ? objNum : maxObjNum;
    objOffsets[objNum] = body.length;
    body.write(content);
  }

  final pagesKids = List.generate(
    numPages,
    (i) => '${3 + i * 2} 0 R',
  ).join(' ');

  writeObj(1, '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
  writeObj(
    2,
    '2 0 obj\n<< /Type /Pages /Kids [$pagesKids] /Count $numPages >>\nendobj\n',
  );

  for (var i = 0; i < numPages; i++) {
    final pageObj = 3 + i * 2;
    final contentObj = 4 + i * 2;
    final text = pageTexts[i];
    final escaped = text
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)');
    final stream = 'BT\n/F1 12 Tf\n100 700 Td\n($escaped) Tj\nET\n';

    writeObj(
      pageObj,
      '$pageObj 0 obj\n'
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents $contentObj 0 R '
      '/Resources << /Font << /F1 $fontObj 0 R >> >> >>\n'
      'endobj\n',
    );
    writeObj(
      contentObj,
      '$contentObj 0 obj\n'
      '<< /Length ${stream.length} >>\n'
      'stream\n$stream'
      'endstream\n'
      'endobj\n',
    );
  }

  writeObj(
    fontObj,
    '$fontObj 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
  );

  final bodyStr = body.toString();
  final xrefOffset = '%PDF-1.4\n'.length + bodyStr.length;

  final xrefEntries = StringBuffer();
  xrefEntries.writeln('xref');
  xrefEntries.writeln('0 ${maxObjNum + 1}');
  xrefEntries.writeln('0000000000 65535 f ');
  for (var i = 1; i <= maxObjNum; i++) {
    final offset = objOffsets[i];
    if (offset != null) {
      xrefEntries.writeln('${offset.toString().padLeft(10)} 00000 n ');
    } else {
      xrefEntries.writeln('0000000000 65535 f ');
    }
  }

  final buffer = StringBuffer();
  buffer.writeln('%PDF-1.4');
  buffer.write(bodyStr);
  buffer.write(xrefEntries.toString());
  buffer.writeln('trailer');
  buffer.writeln('<< /Size ${maxObjNum + 1} /Root 1 0 R >>');
  buffer.writeln('startxref');
  buffer.writeln('$xrefOffset');
  buffer.writeln('%%EOF');

  return Uint8List.fromList(buffer.toString().codeUnits);
}
