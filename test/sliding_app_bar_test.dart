import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/widgets/chat/sliding_app_bar.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';

// Helper to create test model
OpenRouterModel _createTestModel() {
  return OpenRouterModel(
    id: 'test-model',
    name: 'Test Model',
    description: 'A test model',
    contextLength: 8000,
    capabilities: ModelCapabilities(
      reasoning: false,
      multimodal: false,
      vision: false,
      tools: false,
    ),
  );
}

void main() {
  group('SlidingAppBar', () {
    testWidgets('should be created with required parameters', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Verify the app bar is built
      expect(find.byType(SlidingAppBar), findsOneWidget);
      // Verify it's visible (has Row with children)
      expect(find.byType(Row), findsOneWidget);
      // Verify it's not hidden (should not be SizedBox.shrink)
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should show model name on mobile', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Verify model name is shown
      expect(find.text('Test Model'), findsOneWidget);
    });

    testWidgets('should show model name on desktop', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: false,
            ),
            body: Container(),
          ),
        ),
      );

      // Verify model name is shown
      expect(find.text('Test Model'), findsOneWidget);
    });

    testWidgets('should show navigator button when headings exist', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => true,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Verify navigator button is shown
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
    });

    testWidgets('should hide navigator button when no headings', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Verify navigator button is NOT shown
      expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
    });

    testWidgets('should call menu callback when menu button is tapped', (WidgetTester tester) async {
      final model = _createTestModel();

      bool menuPressed = false;
      void onMenuPressed() {
        menuPressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: onMenuPressed,
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Tap menu button
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      // Verify callback was called
      expect(menuPressed, isTrue);
    });

    testWidgets('should call model selection callback when model button is tapped', (WidgetTester tester) async {
      final model = _createTestModel();

      bool modelSelected = false;
      void onModelSelected() {
        modelSelected = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: onModelSelected,
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Tap model selection button
      await tester.tap(find.byIcon(Icons.smart_toy));
      await tester.pump();

      // Verify callback was called
      expect(modelSelected, isTrue);
    });

    testWidgets('should call navigator callback when navigator button is tapped', (WidgetTester tester) async {
      final model = _createTestModel();

      bool navigatorPressed = false;
      void onNavigatorPressed() {
        navigatorPressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => true,
              onNavigatorPressed: onNavigatorPressed,
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Tap navigator button
      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pump();

      // Verify callback was called
      expect(navigatorPressed, isTrue);
    });

    testWidgets('should call handleScroll without error', (WidgetTester tester) async {
      final model = _createTestModel();
      final key = GlobalKey<SlidingAppBarState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              key: key,
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Call handleScroll - should not throw
      expect(() => key.currentState!.handleScroll(150), returnsNormally);
      await tester.pump();
      
      // Call show - should not throw
      expect(() => key.currentState!.show(), returnsNormally);
      await tester.pump();
    });

    testWidgets('should have orange icons in light theme', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => true,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Find all IconButtons
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      // Verify each icon has orange color
      for (int i = 0; i < 3; i++) {
        final iconButton = tester.widget<IconButton>(iconButtons.at(i));
        expect(iconButton.color, equals(const Color(0xFFFF7F00))); // UbuntuColors.orange
      }
    });

    testWidgets('should have orange icons in dark theme', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => true,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Find all IconButtons
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      // Verify each icon has orange color
      for (int i = 0; i < 3; i++) {
        final iconButton = tester.widget<IconButton>(iconButtons.at(i));
        expect(iconButton.color, equals(const Color(0xFFFF7F00))); // UbuntuColors.orange
      }
    });

    testWidgets('should have reduced height (55.0)', (WidgetTester tester) async {
      final model = _createTestModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: SlidingAppBar(
              selectedModel: 'test-model',
              selectedModelObject: model,
              onMenuPressed: () {},
              onModelSelected: () {},
              hasHeadings: () => false,
              onNavigatorPressed: () {},
              isMobile: true,
            ),
            body: Container(),
          ),
        ),
      );

      // Find the SlidingAppBar
      final slidingAppBar = find.byType(SlidingAppBar);
      expect(slidingAppBar, findsOneWidget);

      // Verify preferredSize height (55.0 includes SafeArea top padding)
      final appBar = tester.widget<SlidingAppBar>(slidingAppBar);
      expect(appBar.preferredSize.height, equals(55.0));
    });
  });
}
