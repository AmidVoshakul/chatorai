import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/gui/shared/utils/markdown_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeadingAnchorRegistry.prune', () {
    test('removes only anchors whose id is not in keepIds', () {
      final registry = HeadingAnchorRegistry();
      final keep = HeadingAnchor(
        id: 'keep-1',
        text: 'Keep',
        level: 1,
        lineIndex: 0,
        rawLine: '# Keep',
        messageId: 'm1',
      );
      final drop = HeadingAnchor(
        id: 'drop-1',
        text: 'Drop',
        level: 2,
        lineIndex: 1,
        rawLine: '## Drop',
        messageId: 'm1',
      );
      registry.registerAnchor(keep);
      registry.registerAnchor(drop);

      registry.prune({'keep-1'});

      expect(registry.getAnchor('keep-1'), isNotNull);
      expect(registry.getAnchor('drop-1'), isNull);
      expect(registry.allAnchors.length, 1);
    });

    test('prune with empty keepIds clears everything', () {
      final registry = HeadingAnchorRegistry();
      registry.registerAnchor(
        HeadingAnchor(
          id: 'a',
          text: 'A',
          level: 1,
          lineIndex: 0,
          rawLine: '# A',
          messageId: 'm',
        ),
      );
      registry.prune({});
      expect(registry.allAnchors, isEmpty);
    });
  });

  group('HeadingAnchor id uniqueness with lineIndex', () {
    test(
      'two identical headings at different line indices get distinct ids',
      () {
        const content = '## Introduction\n\nbody\n\n## Introduction';
        final headings = MarkdownParserWithKeys.parseHeadingsWithKeys(
          content,
          messageId: 'msg',
        );

        final introHeadings = headings
            .where((h) => h.text == 'Introduction')
            .toList();
        expect(introHeadings.length, 2);

        final introIds = introHeadings.map((h) => h.anchor.id).toSet();
        expect(introIds.length, 2, reason: 'ids must differ by lineIndex');

        final introUnique = introHeadings.map((h) => h.uniqueKey).toSet();
        expect(introUnique.length, 2);
      },
    );

    test('id encodes messageId, level, lineIndex and text', () {
      const content = '# Title';
      final headings = MarkdownParserWithKeys.parseHeadingsWithKeys(
        content,
        messageId: 'abc',
      );
      expect(headings.single.anchor.id, 'abc_1_0_Title');
      expect(headings.single.uniqueKey, 'abc_1_0_Title');
    });
  });

  group('MarkdownParserWithKeys.parseAllMessagesHeadings', () {
    test('reuses an existing anchor from the registry by id', () {
      final registry = HeadingAnchorRegistry();
      final existing = HeadingAnchor(
        id: 'm_2_0_Introduction',
        text: 'Introduction',
        level: 2,
        lineIndex: 0,
        rawLine: '## Introduction',
        messageId: 'm',
      );
      registry.registerAnchor(existing);

      final message = Message(
        id: 'm',
        role: MessageRole.assistant,
        content: '## Introduction\n\nbody',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final headings = MarkdownParserWithKeys.parseAllMessagesHeadings([
        message,
      ], registry: registry);

      expect(headings.length, 1);
      // Must reuse the pre-registered anchor instance, not allocate a new one.
      expect(headings.single.anchor, same(existing));
      expect(registry.getAnchor('m_2_0_Introduction'), same(existing));
    });

    test('registers a fresh anchor for a new heading', () {
      final registry = HeadingAnchorRegistry();
      final message = Message(
        id: 'm2',
        role: MessageRole.assistant,
        content: '## Fresh',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final headings = MarkdownParserWithKeys.parseAllMessagesHeadings([
        message,
      ], registry: registry);

      expect(headings.length, 1);
      expect(registry.getAnchor('m2_2_0_Fresh'), isNotNull);
    });

    test('ignores non-assistant messages and empty content', () {
      final registry = HeadingAnchorRegistry();
      final userMsg = Message(
        id: 'u',
        role: MessageRole.user,
        content: '## ShouldBeIgnored',
        timestamp: DateTime.now(),
        isComplete: true,
      );
      final emptyAssistant = Message(
        id: 'a',
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isComplete: true,
      );

      final headings = MarkdownParserWithKeys.parseAllMessagesHeadings([
        userMsg,
        emptyAssistant,
      ], registry: registry);

      expect(headings, isEmpty);
    });
  });
}
