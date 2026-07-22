import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:chatorai/core/tools/tool.dart';
import 'package:chatorai/core/tools/built_in/document_extract.dart';

ToolContext _mockCtx() {
  return ToolContext(
    toolCallId: 'test-call-id',
    sessionId: 'test-session',
    ask: ({required String permission, required List<String> patterns, Map<String, dynamic>? metadata, List<String>? always}) async {},
    askQuestion: ({required question, options = const [], multiple = false}) async => '',
  );
}

void main() {
  late Directory testDir;

  setUp(() {
    testDir = Directory('test/temp_doc_truncation');
    if (!testDir.existsSync()) testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('document_extract truncation', () {
    test('text file exceeding 5MB limit returns truncated content', () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();

      final bigData = Uint8List.fromList(
        List.filled(5 * 1024 * 1024 + 100, 0x41),
      );
      final testFile = File('${testDir.path}/large.txt');
      await testFile.writeAsBytes(bigData);

      final output = await tool.execute({'file_path': testFile.path}, ctx);

      expect(output.output, contains('(truncated)'));
      expect(output.output, contains('File size:'));
      expect(output.output, contains('limit:'));
      expect(output.output, contains('Full file written to:'));
      expect(output.output, contains('tool-output'));
      expect(output.metadata?['type'], equals('txt'));
    });

    test('text file within 5MB limit returns full content', () async {
      final tool = createDocumentExtractTool();
      final ctx = _mockCtx();

      final content = 'Hello, World!\n' * 1000;
      final testFile = File('${testDir.path}/small.txt');
      await testFile.writeAsString(content);

      final output = await tool.execute({'file_path': testFile.path}, ctx);

      expect(output.output, contains('Hello, World!'));
      expect(output.output, isNot(contains('truncated')));
      expect(output.metadata?['error'], isNull);
    });
  });
}
