import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/document_extract.dart';

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
    testDir = Directory('test/temp_doc_extract_xlsx');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('document_extract_xlsx', () {
    test('description is non-empty', () {
      final tool = createDocumentExtractXlsxTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema requires file_path', () {
      final tool = createDocumentExtractXlsxTool();
      final schema = tool.inputSchema;
      expect((schema['properties'] as Map).containsKey('file_path'), isTrue);
      expect((schema['required'] as List).contains('file_path'), isTrue);
    });

    test('inputSchema has optional sheet field', () {
      final tool = createDocumentExtractXlsxTool();
      final properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('sheet'), isTrue);
    });

    test('execute with missing file_path returns error', () async {
      final tool = createDocumentExtractXlsxTool();
      final output = await tool.execute({}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('execute with non-existent file returns error', () async {
      final tool = createDocumentExtractXlsxTool();
      final output = await tool.execute({
        'file_path': '${testDir.path}/nonexistent.xlsx',
      }, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('not found'));
    });

    test('xlsx extracts data', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createMinimalXlsx(
        sheetName: 'Sheet1',
        rows: [
          ['Name', 'Value'],
          ['Item A', '100'],
          ['Item B', '200'],
        ],
      );
      final testFile = File('${testDir.path}/test.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Sheet1'));
      expect(output.output, contains('Item A'));
      expect(output.output, contains('Item B'));
      expect(output.output, contains('100'));
      expect(output.output, contains('200'));
    });

    test('xlsx with sheet parameter selects specific sheet', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createMinimalXlsx(
        sheetName: 'Sales',
        rows: [
          ['Product', 'Revenue'],
          ['Widget', '1000'],
        ],
      );
      final testFile = File('${testDir.path}/multi_sheet.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({
        'file_path': testFile.path,
        'sheet': 'Sales',
      }, ctx);
      expect(output.output, contains('Sales'));
      expect(output.output, contains('Widget'));
      expect(output.output, contains('1000'));
    });

    test('xlsx handles inlineStr cells', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createCustomXlsx(
        entries: [
          ArchiveFile(
            'xl/worksheets/sheet1.xml',
            0,
            utf8.encode(
              '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
              '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
              '  <sheetData>\n'
              '    <row><c t="inlineStr"><is><t>Hello</t></is></c><c t="inlineStr"><is><t>World</t></is></c></row>\n'
              '  </sheetData>\n'
              '</worksheet>',
            ),
          ),
        ],
      );
      final testFile = File('${testDir.path}/inline_str.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, contains('Hello'));
      expect(output.output, contains('World'));
    });

    test('xlsx preserves empty cells as empty strings', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createCustomXlsx(
        entries: [
          ArchiveFile(
            'xl/worksheets/sheet1.xml',
            0,
            utf8.encode(
              '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
              '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
              '  <sheetData>\n'
              '    <row><c><v>A</v></c><c/><c><v>C</v></c></row>\n'
              '  </sheetData>\n'
              '</worksheet>',
            ),
          ),
        ],
      );
      final testFile = File('${testDir.path}/empty_cells.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      final lines = output.output.split('\n');
      final dataLine = lines.firstWhere(
        (l) => l.contains('|'),
        orElse: () => '',
      );
      expect(dataLine, contains('| A '));
      expect(dataLine, contains('|  '));
      expect(dataLine, contains('| C '));
    });

    test('xlsx handles missing sharedstrings.xml gracefully', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createMinimalXlsx(
        sheetName: 'Sheet1',
        rows: [
          ['A', 'B'],
        ],
      );
      final archive = ZipDecoder().decodeBytes(xlsxBytes);
      final filtered = Archive();
      for (final file in archive.files) {
        if (file.name != 'xl/sharedstrings.xml') {
          filtered.addFile(file);
        }
      }
      final testFile = File('${testDir.path}/no_sharedstrings.xlsx');
      await testFile.writeAsBytes(
        Uint8List.fromList(ZipEncoder().encode(filtered)),
      );

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, contains('Sheet1'));
      expect(output.output, contains('A'));
    });

    test('xlsx handles missing workbook.xml gracefully', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createMinimalXlsx(
        sheetName: 'Sheet1',
        rows: [
          ['A'],
        ],
      );
      final archive = ZipDecoder().decodeBytes(xlsxBytes);
      final filtered = Archive();
      for (final file in archive.files) {
        if (file.name != 'xl/workbook.xml' &&
            file.name != 'xl/_rels/workbook.xml.rels') {
          filtered.addFile(file);
        }
      }
      final testFile = File('${testDir.path}/no_workbook.xlsx');
      await testFile.writeAsBytes(
        Uint8List.fromList(ZipEncoder().encode(filtered)),
      );

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, contains('No sheets found'));
    });

    test('xlsx handles case-insensitive zip entry paths', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createCustomXlsx(
        entries: [
          ArchiveFile(
            'XL/WORKSHEETS/SHEET1.XML',
            0,
            utf8.encode(
              '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
              '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
              '  <sheetData>\n'
              '    <row><c><v>Data</v></c></row>\n'
              '  </sheetData>\n'
              '</worksheet>',
            ),
          ),
          ArchiveFile(
            'XL/WORKBOOK.XML',
            0,
            utf8.encode(
              '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
              '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
              '  <sheets>\n'
              '    <sheet name="Sheet1" sheetId="1"/>\n'
              '  </sheets>\n'
              '</workbook>',
            ),
          ),
        ],
      );
      final testFile = File('${testDir.path}/uppercase_paths.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, contains('Sheet1'));
      expect(output.output, contains('Data'));
    });

    test('execute with empty file_path returns error', () async {
      final tool = createDocumentExtractXlsxTool();
      final output = await tool.execute({'file_path': ''}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('execute with whitespace-only file_path returns error', () async {
      final tool = createDocumentExtractXlsxTool();
      final output = await tool.execute({'file_path': '  '}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('xlsx with comma-separated path uses first path', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createMinimalXlsx(
        sheetName: 'Sheet1',
        rows: [
          ['A'],
        ],
      );
      final testFile = File('${testDir.path}/first.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({
        'file_path': '${testFile.path},/nonexistent/fake.xlsx',
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Sheet1'));
    });

    test(
      'xlsx with nonexistent sheet name returns not-found message',
      () async {
        final tool = createDocumentExtractXlsxTool();
        final ctx = _mockCtx();

        final xlsxBytes = _createMinimalXlsx(
          sheetName: 'Sheet1',
          rows: [
            ['A'],
          ],
        );
        final testFile = File('${testDir.path}/sheet_miss.xlsx');
        await testFile.writeAsBytes(xlsxBytes);

        final output = await tool.execute({
          'file_path': testFile.path,
          'sheet': 'NoSuchSheet',
        }, ctx);
        expect(output.output, contains('not found'));
      },
    );

    test('xlsx with corrupt bytes returns error or empty output', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final testFile = File('${testDir.path}/corrupt.xlsx');
      await testFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      // corrupt data either throws (caught → error) or extracts empty content
      final hasError = output.metadata?['error'] == true;
      final hasErrorText = output.output.toLowerCase().contains('error');
      final isEmpty =
          output.output.trim().isEmpty ||
          output.output.contains('No sheets found');
      expect(hasError || hasErrorText || isEmpty, isTrue);
    });

    test('xlsx metadata includes type and file_paths', () async {
      final tool = createDocumentExtractXlsxTool();
      final ctx = _mockCtx();

      final xlsxBytes = _createMinimalXlsx(
        sheetName: 'Sheet1',
        rows: [
          ['A'],
        ],
      );
      final testFile = File('${testDir.path}/meta.xlsx');
      await testFile.writeAsBytes(xlsxBytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['type'], equals('xlsx'));
      final paths = output.metadata?['file_paths'] as List?;
      expect(paths, isA<List>());
      expect(paths, isNotEmpty);
      // path is resolved to absolute by the tool
      expect(paths!.first, endsWith('meta.xlsx'));
    });
  });
}

Uint8List _createMinimalXlsx({
  required String sheetName,
  required List<List<String>> rows,
}) {
  final archive = Archive();

  archive.addFile(
    ArchiveFile(
      '[Content_Types].xml',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '</Types>',
      ),
    ),
  );

  archive.addFile(
    ArchiveFile(
      '_rels/.rels',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\n'
        '</Relationships>',
      ),
    ),
  );

  final sheetRowsXml = rows
      .map((row) {
        final cells = row
            .map((cell) {
              return '<c><v>${_escapeXml(cell)}</v></c>';
            })
            .join('');
        return '<row>$cells</row>';
      })
      .join('');

  archive.addFile(
    ArchiveFile(
      'xl/workbook.xml',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
        '  <sheets>\n'
        '    <sheet name="$sheetName" sheetId="1"/>\n'
        '  </sheets>\n'
        '</workbook>',
      ),
    ),
  );

  archive.addFile(
    ArchiveFile(
      'xl/_rels/workbook.xml.rels',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>\n'
        '</Relationships>',
      ),
    ),
  );

  archive.addFile(
    ArchiveFile(
      'xl/worksheets/sheet1.xml',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
        '  <sheetData>\n'
        '$sheetRowsXml\n'
        '  </sheetData>\n'
        '</worksheet>',
      ),
    ),
  );

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _escapeXml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

Uint8List _createCustomXlsx({required List<ArchiveFile> entries}) {
  final archive = Archive();
  archive.addFile(
    ArchiveFile(
      '[Content_Types].xml',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '</Types>',
      ),
    ),
  );
  archive.addFile(
    ArchiveFile(
      '_rels/.rels',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\n'
        '</Relationships>',
      ),
    ),
  );
  archive.addFile(
    ArchiveFile(
      'xl/workbook.xml',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">\n'
        '  <sheets>\n'
        '    <sheet name="Sheet1" sheetId="1"/>\n'
        '  </sheets>\n'
        '</workbook>',
      ),
    ),
  );
  archive.addFile(
    ArchiveFile(
      'xl/_rels/workbook.xml.rels',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>\n'
        '</Relationships>',
      ),
    ),
  );
  for (final entry in entries) {
    archive.addFile(entry);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
