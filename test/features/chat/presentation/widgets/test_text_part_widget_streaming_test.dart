import 'package:chatorai/features/chat/data/models/chat/chat_message.dart';
import 'package:chatorai/features/chat/presentation/widgets/parts/text_part_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPart(WidgetTester tester, TextPart part) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextPartWidget(part: part, messageId: 'test'),
        ),
      ),
    );
  }

  group('TextPartWidget streaming', () {
    testWidgets('plain chunks flow inline as a single text stream', (
      tester,
    ) async {
      await pumpPart(tester, TextPart(content: 'chunk1', isStreaming: true));
      await pumpPart(
        tester,
        TextPart(content: 'chunk1chunk2', isStreaming: true),
      );
      await pumpPart(
        tester,
        TextPart(content: 'chunk1chunk2chunk3', isStreaming: true),
      );

      expect(find.text('chunk1chunk2chunk3'), findsOneWidget);
      expect(find.text('chunk1'), findsNothing);
      expect(find.text('chunk2'), findsNothing);
    });

    testWidgets('completed inline markdown renders immediately', (
      tester,
    ) async {
      await pumpPart(
        tester,
        TextPart(content: 'plain **bold** more', isStreaming: true),
      );

      expect(find.text('plain bold more'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
    });

    testWidgets('inline markdown construct renders as soon as it closes', (
      tester,
    ) async {
      await pumpPart(
        tester,
        TextPart(content: 'plain **bold', isStreaming: true),
      );
      expect(find.textContaining('**'), findsOneWidget);

      await pumpPart(
        tester,
        TextPart(content: 'plain **bold** more', isStreaming: true),
      );

      expect(find.text('plain bold more'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
    });

    testWidgets('newline chunks join into markdown paragraphs', (tester) async {
      await pumpPart(
        tester,
        TextPart(content: 'line1\nline2', isStreaming: true),
      );

      expect(find.text('line1 line2'), findsOneWidget);
    });

    testWidgets(
      'non-append content change re-renders instead of reusing cache',
      (tester) async {
        await pumpPart(
          tester,
          TextPart(content: 'first answer', isStreaming: true),
        );
        expect(find.text('first answer'), findsOneWidget);

        await pumpPart(
          tester,
          TextPart(content: 'second answer', isStreaming: true),
        );

        expect(find.text('second answer'), findsOneWidget);
        expect(find.text('first answer'), findsNothing);
      },
    );

    testWidgets('identical content does not break the rendered tree', (
      tester,
    ) async {
      await pumpPart(
        tester,
        TextPart(content: 'same content', isStreaming: true),
      );
      await pumpPart(
        tester,
        TextPart(content: 'same content', isStreaming: true),
      );

      expect(find.text('same content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty streaming content shows the cursor', (tester) async {
      await pumpPart(tester, TextPart(content: '', isStreaming: true));

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.margin == const EdgeInsets.only(right: 2) &&
              w.constraints ==
                  const BoxConstraints.tightFor(width: 8, height: 16),
        ),
        findsOneWidget,
      );
    });

    testWidgets('completed message renders markdown the same way', (
      tester,
    ) async {
      await pumpPart(
        tester,
        TextPart(content: 'done **bold** text', isStreaming: false),
      );

      expect(find.text('done bold text'), findsOneWidget);
    });
  });
}
