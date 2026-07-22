import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/tool_error.dart';
import 'package:chatorai/core/tools/built_in/document_extract.dart';

ToolContext _mockCtx() {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask: ({
      required String permission,
      required List<String> patterns,
      Map<String, dynamic>? metadata,
      List<String>? always,
    }) async {},
    askQuestion:
        ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  late Directory testDir;

  setUp(() {
    testDir = Directory('test/temp_doc_extract');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('document_extract tool', () {
    test('description is non-empty', () {
      final tool = createDocumentExtractTool();
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has required file_path field', () {
      final tool = createDocumentExtractTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('file_path'), isTrue);
      expect((schema['required'] as List).contains('file_path'), isTrue);
    });

    test('inputSchema has pdf_page_timeout field', () {
      final tool = createDocumentExtractTool();
      final schema = tool.inputSchema;
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('pdf_page_timeout'), isTrue);
      expect(properties['pdf_page_timeout']['minimum'], equals(5));
      expect(properties['pdf_page_timeout']['default'], equals(15));
    });

    test('execute with missing file_path throws ToolExecutionError', () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();
      expect(
        () async => tool.execute({}, ctx),
        throwsA(isA<ToolExecutionError>()),
      );
    });

    test('execute with non-existent file throws ToolExecutionError', () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();
      expect(
        () async => tool.execute({
          'file_path': '${testDir.path}/nonexistent.pdf',
        }, ctx),
        throwsA(
          predicate<ToolExecutionError>(
            (e) => e.message.contains('not found'),
          ),
        ),
      );
    });

    test('execute with unsupported extension throws ToolExecutionError',
        () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test.xyz');
      await testFile.writeAsString('test');
      expect(
        () async => tool.execute({'file_path': testFile.path}, ctx),
        throwsA(
          predicate<ToolExecutionError>(
            (e) => e.message.contains('unsupported'),
          ),
        ),
      );
    });

    test('execute with txt file returns content', () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test.txt');
      await testFile.writeAsString('Hello, World!\nLine 2');
      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['type'], equals('txt'));
      expect(output.output, contains('Hello, World!'));
      expect(output.output, contains('Line 2'));
      expect(output.metadata?['content_length'], greaterThan(0));
    });

    test('execute with md file returns content', () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();
      final testFile = File('${testDir.path}/test.md');
      await testFile.writeAsString('# Title\n\nSome markdown content.');
      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.metadata?['type'], equals('md'));
      expect(output.output, contains('# Title'));
      expect(output.output, contains('Some markdown content.'));
    });

    test('execute with docx file extracts text', () async {
      final tool = createDocumentExtractTool();
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
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();

      final archive = Archive();
      archive.addFile(ArchiveFile(
        '[Content_Types].xml',
        0,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
</Types>'''),
      ));
      archive.addFile(ArchiveFile(
        '_rels/.rels',
        0,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''),
      ));
      archive.addFile(ArchiveFile(
        'word/document.xml',
        0,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>Text with image</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>'''),
      ));
      archive.addFile(ArchiveFile(
        'word/media/image1.png',
        0,
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      ));

      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final testFile = File('${testDir.path}/test_media.docx');
      await testFile.writeAsBytes(bytes);

      final output = await tool.execute({'file_path': testFile.path}, ctx);
      expect(output.metadata?['error'], isNull);
      expect(output.output, contains('Media 1'));
      expect(output.output, contains('base64'));
    });
  });
}

Uint8List _createMinimalDocx(String text) {
  final archive = Archive();
  archive.addFile(ArchiveFile(
    '[Content_Types].xml',
    0,
    utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
</Types>'''),
  ));
  archive.addFile(ArchiveFile(
    '_rels/.rels',
    0,
    utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''),
  ));
  archive.addFile(ArchiveFile(
    'word/document.xml',
    0,
    utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>$text</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>'''),
  ));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
