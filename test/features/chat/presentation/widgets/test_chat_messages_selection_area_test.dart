import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal reproduction of the [ChatMessages] layout: a single [SelectionArea]
/// wrapping a [ListView.builder] whose `itemCount` can change (exactly what
/// happens while a chat is streaming). It is used to guard against the Flutter
/// framework assertion `currentSelectionStartIndex < selectables.length` in
/// `selectable_region.dart`, which fires when an in-progress text selection
/// references selectable indices that no longer exist after the list mutates.
Widget _buildHarness(int itemCount) {
  return MaterialApp(
    home: Scaffold(
      body: SelectionArea(
        // Mirrors the fix in `chat_messages.dart`: keying the SelectionArea on
        // the list length forces a clean rebuild (dropping any active
        // selection) whenever the number of items changes.
        key: ValueKey(itemCount),
        child: ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              'Selectable message number $index with enough text content to '
              'allow a drag selection across the line',
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ChatMessages SelectionArea list-length safety', () {
    testWidgets('SelectionArea is rebuilt when itemCount changes', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(3));
      final keyBefore = tester
          .widget<SelectionArea>(find.byType(SelectionArea))
          .key;
      await tester.pumpWidget(_buildHarness(4));
      final keyAfter = tester
          .widget<SelectionArea>(find.byType(SelectionArea))
          .key;

      // The key MUST change with itemCount so any active selection is dropped
      // and selectable indices are recomputed from scratch — this is what
      // prevents the `selectable_region.dart` assertion during streaming.
      expect(keyBefore, isNot(equals(keyAfter)));
    });

    testWidgets(
      'SelectionArea keeps the same instance when itemCount is unchanged',
      (tester) async {
        await tester.pumpWidget(_buildHarness(3));
        final keyBefore = tester
            .widget<SelectionArea>(find.byType(SelectionArea))
            .key;
        // A normal rebuild (e.g. a streaming token updating the current bubble)
        // must NOT reset the user's selection.
        await tester.pumpWidget(_buildHarness(3));
        final keyAfter = tester
            .widget<SelectionArea>(find.byType(SelectionArea))
            .key;
        expect(keyBefore, equals(keyAfter));
      },
    );

    testWidgets('selectable content is preserved after itemCount change', (
      tester,
    ) async {
      await tester.pumpWidget(_buildHarness(2));
      // Each list item exposes selectable text, so the user can still
      // select/copy message content after the list mutates.
      expect(find.byType(SelectableText), findsNWidgets(2));

      // Simulate a new message arriving during streaming.
      await tester.pumpWidget(_buildHarness(3));
      await tester.pumpAndSettle();

      // The rebuilt SelectionArea still wraps selectable content.
      expect(find.byType(SelectableText), findsNWidgets(3));
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets(
      'no assertion when itemCount changes during an active drag selection',
      (tester) async {
        await tester.pumpWidget(_buildHarness(5));

        // Begin an active text selection (pointer down + drag) on the last item.
        final lastFinder = find.text(
          'Selectable message number 4 with enough text content to allow a drag '
          'selection across the line',
        );
        final rect = tester.getRect(lastFinder);
        final gesture = await tester.startGesture(rect.center);
        await tester.pump();
        await gesture.moveTo(rect.center + Offset(rect.width / 2, 0));
        await tester.pump();

        // While the selection drag is still active (pointer down), shrink the
        // list. The SelectionArea is rebuilt (new key) and the stale selection
        // indices are discarded instead of triggering the framework assertion.
        await tester.pumpWidget(_buildHarness(2));
        await gesture.moveTo(const Offset(20, 20));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
