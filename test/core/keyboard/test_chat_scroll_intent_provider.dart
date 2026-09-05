import 'package:chatorai/gui/features/chat/data/providers/chat_scroll_intent_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatScrollIntentProvider', () {
    test('initial state has zero generation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final intent = container.read(chatScrollIntentProvider);
      expect(intent.generation, 0);
    });

    test('scrollToStart/scrollToEnd bump generation and set target', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chatScrollIntentProvider.notifier);

      notifier.scrollToStart();
      var intent = container.read(chatScrollIntentProvider);
      expect(intent.generation, 1);
      expect(intent.target, ChatScrollTarget.start);

      notifier.scrollToEnd();
      intent = container.read(chatScrollIntentProvider);
      expect(intent.generation, 2);
      expect(intent.target, ChatScrollTarget.end);
    });

    test('repeated presses always emit a new intent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(chatScrollIntentProvider.notifier);

      notifier.scrollToStart();
      final first = container.read(chatScrollIntentProvider);
      notifier.scrollToStart();
      final second = container.read(chatScrollIntentProvider);

      expect(second.generation, first.generation + 1);
      expect(second.target, ChatScrollTarget.start);
    });
  });

  group('listenChatScrollIntent', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Future<ScrollController> pumpList(WidgetTester tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _ScrollListenerHarness(controller: controller),
        ),
      );
      return controller;
    }

    testWidgets('start intent jumps to top', (tester) async {
      final controller = await pumpList(tester);
      final position = controller.position;
      expect(position.maxScrollExtent, greaterThan(0));

      controller.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(controller.offset, position.maxScrollExtent);

      container.read(chatScrollIntentProvider.notifier).scrollToStart();
      await tester.pump();
      expect(controller.offset, 0);
    });

    testWidgets('end intent jumps to bottom', (tester) async {
      final controller = await pumpList(tester);
      final position = controller.position;
      expect(position.maxScrollExtent, greaterThan(0));

      container.read(chatScrollIntentProvider.notifier).scrollToEnd();
      await tester.pump();
      expect(controller.offset, position.maxScrollExtent);
    });

    testWidgets('unmounting the listener does not throw', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _ScrollListenerHarness(controller: controller),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);

      container.read(chatScrollIntentProvider.notifier).scrollToEnd();
      expect(container.read(chatScrollIntentProvider).generation, 1);
    });
  });
}

class _ScrollListenerHarness extends ConsumerStatefulWidget {
  const _ScrollListenerHarness({required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<_ScrollListenerHarness> createState() =>
      _ScrollListenerHarnessState();
}

class _ScrollListenerHarnessState
    extends ConsumerState<_ScrollListenerHarness> {
  @override
  Widget build(BuildContext context) {
    listenChatScrollIntent(ref, widget.controller);
    return MaterialApp(
      home: ListView.builder(
        controller: widget.controller,
        itemCount: 200,
        itemBuilder: (context, index) =>
            SizedBox(height: 40, child: Text('Item $index')),
      ),
    );
  }
}
