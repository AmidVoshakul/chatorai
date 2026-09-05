import 'package:chatorai/gui/features/chat/presentation/widgets/markdown_with_headings.dart';
import 'package:chatorai/gui/gui/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'duplicate identical headings bind to distinct anchors (no GlobalKey collision)',
    (tester) async {
      const messageId = 'msg-dup';
      const content = '''
# Title

## Introduction

first

## Introduction

second
''';
      final headings = MarkdownParserWithKeys.parseHeadingsWithKeys(
        content,
        messageId: messageId,
      );
      // 1 h1 + 2 identical h2 headings.
      expect(headings.where((h) => h.level == 2).length, 2);

      // Pumping throws a FlutterError on duplicate GlobalKeys, so a successful
      // pump is itself the regression guard. We also assert the two matching
      // heading anchors carry distinct GlobalKeys.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownWithHeadings(
                data: content,
                headings: headings,
                messageId: messageId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final anchorKeys = tester.allWidgets
          .whereType<Container>()
          .where((c) => c.key is GlobalKey)
          .map((c) => c.key)
          .toSet();

      // At least the 3 heading containers carry a GlobalKey and all are unique.
      expect(anchorKeys.length, greaterThanOrEqualTo(3));
    },
  );

  testWidgets(
    'setext heading rendered but not parsed gets no key (no GlobalKey collision)',
    (tester) async {
      const messageId = 'msg-setext';
      // "Overview" appears twice: once as an ATX h2 (parsed → anchor key)
      // and once as a setext h2 (rendered by markdown, NOT parsed). Before
      // the fix the second occurrence clamped onto the first anchor's key.
      const content = '''
## Overview

parsed

Overview
--------

tail
''';
      final headings = MarkdownParserWithKeys.parseHeadingsWithKeys(
        content,
        messageId: messageId,
      );
      // The parser only recognizes the ATX heading.
      expect(headings.where((h) => h.text == 'Overview').length, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarkdownWithHeadings(
                data: content,
                headings: headings,
                messageId: messageId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The regression was a "Duplicate GlobalKey" exception on pump.
      expect(tester.takeException(), isNull);

      final overviewKeys = tester.allWidgets
          .whereType<Container>()
          .where((c) => c.key is GlobalKey)
          .length;
      // Only the parsed ATX occurrence carries a key.
      expect(overviewKeys, 1);
    },
  );
}
