import 'package:test/test.dart';
import 'package:chatorai/tools/tool_title.dart';

void main() {
  group('Tool title formatters', () {
    test('formatReadTitle with offset and limit', () {
      final input = {'offset': '10', 'limit': '50'};
      expect(
        formatReadTitle('lib/main.dart', input),
        equals('Read lib/main.dart [offset=10, limit=50]'),
      );
    });

    test('formatReadTitle without offset and limit', () {
      expect(
        formatReadTitle('lib/main.dart', {}),
        equals('Read lib/main.dart'),
      );
    });

    test('formatEditTitle', () {
      expect(formatEditTitle('lib/main.dart'), equals('Edit lib/main.dart'));
    });

    test('formatWriteTitle', () {
      expect(formatWriteTitle('lib/main.dart'), equals('Write lib/main.dart'));
    });

    test('formatGlobTitle', () {
      expect(formatGlobTitle('**/*.dart'), equals('Glob "**/*.dart"'));
    });

    test('formatGrepTitle with root and matches', () {
      expect(
        formatGrepTitle('TODO', 'lib', 42),
        equals('Grep "TODO" in lib (42 matches)'),
      );
    });

    test('formatGrepTitle without root and matches', () {
      expect(formatGrepTitle('TODO', null, null), equals('Grep "TODO"'));
    });

    test('formatBashTitle with description', () {
      expect(formatBashTitle('Run tests'), equals('Run tests'));
    });

    test('formatBashTitle without description', () {
      expect(formatBashTitle(null), equals('Shell command'));
    });

    test('formatWebfetchTitle with url', () {
      expect(
        formatWebfetchTitle('https://example.com'),
        equals('WebFetch https://example.com'),
      );
    });

    test('formatWebfetchTitle without url', () {
      expect(formatWebfetchTitle(null), equals('WebFetch'));
    });

    test('formatWebsearchTitle with provider and query', () {
      expect(
        formatWebsearchTitle('exa', 'flutter tutorial'),
        equals('exa "flutter tutorial"'),
      );
    });

    test('formatWebsearchTitle without provider', () {
      expect(
        formatWebsearchTitle(null, 'flutter tutorial'),
        equals('WebSearch "flutter tutorial"'),
      );
    });

    test('formatWebsearchTitle without query', () {
      expect(formatWebsearchTitle('exa', null), equals('exa'));
    });
  });
}
