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
    testDir = Directory('test/temp_doc_extract_docx');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('document_extract_docx', () {
    test('description is non-empty', () {
      final tool = createDocumentExtractDocxTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema requires file_path', () {
      final tool = createDocumentExtractDocxTool();
      final schema = tool.inputSchema;
      expect((schema['properties'] as Map).containsKey('file_path'), isTrue);
      expect((schema['required'] as List).contains('file_path'), isTrue);
    });

    test('execute with missing file_path returns error', () async {
      final tool = createDocumentExtractDocxTool();
      final output = await tool.execute({}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('execute with non-existent file returns error', () async {
      final tool = createDocumentExtractDocxTool();
      final output = await tool.execute({
        'file_path': '${testDir.path}/nonexistent.docx',
      }, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('not found'));
    });

    test('docx extracts text', () async {
      final tool = createDocumentExtractDocxTool();
      final ctx = _mockCtx();

      final docxContent = _createMinimalDocx('Hello from DOCX\nLine 2');
      final testFile = File('${testDir.path}/test.docx');
      await testFile.writeAsBytes(docxContent);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['type'], equals('docx'));
      expect(output.output, contains('Hello from DOCX'));
      expect(output.output, contains('Line 2'));
    });

    test('docx with embedded images includes media section', () async {
      final tool = createDocumentExtractDocxTool();
      final ctx = _mockCtx();

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
            '  <Default Extension="png" ContentType="image/png"/>\n'
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
            '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\n'
            '</Relationships>',
          ),
        ),
      );
      archive.addFile(
        ArchiveFile(
          'word/document.xml',
          0,
          utf8.encode(
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n'
            '  <w:body>\n'
            '    <w:p>\n'
            '      <w:r>\n'
            '        <w:t>Text with image</w:t>\n'
            '      </w:r>\n'
            '    </w:p>\n'
            '  </w:body>\n'
            '</w:document>',
          ),
        ),
      );
      archive.addFile(
        ArchiveFile('word/media/image1.png', 0, [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
      );

      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final testFile = File('${testDir.path}/test_media.docx');
      await testFile.writeAsBytes(bytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Media 1'));
      expect(output.output, contains('base64'));
    });

    test('execute with empty file_path returns error', () async {
      final tool = createDocumentExtractDocxTool();
      final output = await tool.execute({'file_path': ''}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('execute with whitespace-only file_path returns error', () async {
      final tool = createDocumentExtractDocxTool();
      final output = await tool.execute({'file_path': '  '}, _mockCtx());
      expect(output.metadata?['error'], isTrue);
      expect(output.output, contains('file_path is required'));
    });

    test('docx with comma-separated path uses first path', () async {
      final tool = createDocumentExtractDocxTool();
      final ctx = _mockCtx();

      final docxContent = _createMinimalDocx('Comma path');
      final testFile = File('${testDir.path}/first.docx');
      await testFile.writeAsBytes(docxContent);

      final output = await tool.execute({
        'file_path': '${testFile.path},/nonexistent/fake.docx',
      }, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Comma path'));
    });

    test('docx with corrupt bytes does not crash', () async {
      final tool = createDocumentExtractDocxTool();
      final ctx = _mockCtx();

      final testFile = File('${testDir.path}/corrupt.docx');
      await testFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      // Should not throw — tool handles corrupt data gracefully
      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, isA<String>());
    });

    test('docx metadata includes type and file_paths', () async {
      final tool = createDocumentExtractDocxTool();
      final ctx = _mockCtx();

      final docxContent = _createMinimalDocx('Meta check');
      final testFile = File('${testDir.path}/meta.docx');
      await testFile.writeAsBytes(docxContent);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['type'], equals('docx'));
      final paths = output.metadata?['file_paths'] as List?;
      expect(paths, isA<List>());
      expect(paths, isNotEmpty);
      // path is resolved to absolute by the tool
      expect(paths!.first, endsWith('meta.docx'));
    });

    test('output starts with filename header', () async {
      final tool = createDocumentExtractDocxTool();
      final ctx = _mockCtx();

      final docxContent = _createMinimalDocx('Header check');
      final testFile = File('${testDir.path}/header.docx');
      await testFile.writeAsBytes(docxContent);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.output, startsWith('# header.docx'));
    });
  });
}

Uint8List _createMinimalDocx(String text) {
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
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\n'
        '</Relationships>',
      ),
    ),
  );
  archive.addFile(
    ArchiveFile(
      'word/document.xml',
      0,
      utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n'
        '  <w:body>\n'
        '    <w:p>\n'
        '      <w:r>\n'
        '        <w:t>$text</w:t>\n'
        '      </w:r>\n'
        '    </w:p>\n'
        '  </w:body>\n'
        '</w:document>',
      ),
    ),
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
