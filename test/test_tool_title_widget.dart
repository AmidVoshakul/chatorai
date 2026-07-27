import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/tool_title.dart';

void main() {
  group('toolTitle (TaskPart header)', () {
    test('shell shows full command, not just the tool name', () {
      final title = toolTitle('shell', {
        'command': 'flutter test test/foo_test.dart --coverage',
      });
      // _breakablePath inserts a zero-width space after '/' for wrapping.
      expect(
        title,
        equals('shell flutter test test/\u200Bfoo_test.dart --coverage'),
      );
    });

    test('shell falls back to description when command is absent', () {
      expect(
        toolTitle('shell', {'description': 'Run tests'}),
        equals('Run tests'),
      );
    });

    test('shell falls back to tool name when nothing is provided', () {
      expect(toolTitle('shell', {}), equals('shell'));
    });

    test('read still shows path with args', () {
      expect(
        toolTitle('read', {'path': 'lib/main.dart', 'offset': '10'}),
        equals('Read lib/\u200Bmain.dart [offset=10]'),
      );
    });
  });
}
