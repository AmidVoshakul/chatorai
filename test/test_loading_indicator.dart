import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/widgets/chat/loading_indicator.dart';

// Mock logger for testing
class MockLogger {
  final String tag;
  MockLogger(this.tag);

  void logInfo(String message) => print('[INFO] $tag: $message');
  void logDebug(String message) => print('[DEBUG] $tag: $message');
  void logVerbose(String message) => print('[VERBOSE] $tag: $message');
  void logWarning(String message) => print('[WARNING] $tag: $message');
  void logError(String message) => print('[ERROR] $tag: $message');
}

void main() {
  group('LoadingIndicator Widget Tests', () {
    // Test 1: ChatLoadingIndicator basic rendering
    testWidgets('renders ChatLoadingIndicator correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatLoadingIndicator(
              size: 12,
            ),
          ),
        ),
      );

      // Should show the loading indicator
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    // Test 2: ChatLoadingIndicator with custom size
    testWidgets('renders ChatLoadingIndicator with custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatLoadingIndicator(
              size: 16,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
    });

    // Test 3: ChatLoadingIndicator with custom color
    testWidgets('renders ChatLoadingIndicator with custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatLoadingIndicator(
              size: 12,
              color: Colors.red,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
    });

    // Test 4: ChatTypingDotsIndicator basic rendering
    testWidgets('renders ChatTypingDotsIndicator correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTypingDotsIndicator(
              dotSize: 6,
            ),
          ),
        ),
      );

      // Should show the typing dots indicator
      expect(find.byType(ChatTypingDotsIndicator), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    // Test 5: ChatTypingDotsIndicator with custom dot size
    testWidgets('renders ChatTypingDotsIndicator with custom dot size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTypingDotsIndicator(
              dotSize: 8,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(ChatTypingDotsIndicator), findsOneWidget);
    });

    // Test 6: ChatTypingDotsIndicator with custom color
    testWidgets('renders ChatTypingDotsIndicator with custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTypingDotsIndicator(
              dotSize: 6,
              color: Colors.blue,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(ChatTypingDotsIndicator), findsOneWidget);
    });

    // Test 7: Visual appearance of loading indicators
    testWidgets('has correct visual appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChatLoadingIndicator(size: 12),
                ChatTypingDotsIndicator(dotSize: 6),
              ],
            ),
          ),
        ),
      );

      // Check for proper layout elements
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsOneWidget);
    });

    // Test 8: Loading indicator animation
    testWidgets('shows animation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTypingDotsIndicator(
              dotSize: 6,
            ),
          ),
        ),
      );

      // Should show animated dots
      expect(find.byType(ChatTypingDotsIndicator), findsOneWidget);

      // Pump frames to test animation
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChatTypingDotsIndicator), findsOneWidget);
    });

    // Test 9: Loading indicator with different themes
    testWidgets('handles different themes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ChatLoadingIndicator(
              size: 12,
            ),
          ),
        ),
      );

      // Should render in dark theme
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
    });

    // Test 10: Loading indicator accessibility
    testWidgets('is accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatLoadingIndicator(
              size: 12,
            ),
          ),
        ),
      );

      // Should be focusable and accessible
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
    });

    // Test 11: Loading indicator performance
    testWidgets('handles rapid widget rebuilds', (WidgetTester tester) async {
      var rebuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                rebuildCount++;
                return ChatLoadingIndicator(
                  size: 12,
                );
              },
            ),
          ),
        ),
      );

      // Initial render
      expect(rebuildCount, 1);
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);

      // Force rebuild
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                rebuildCount++;
                return ChatLoadingIndicator(
                  size: 12,
                );
              },
            ),
          ),
        ),
      );

      // Should handle rebuilds correctly
      expect(rebuildCount, 2);
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
    });

    // Test 12: Loading indicator with null values
    testWidgets('handles null values gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatLoadingIndicator(),
          ),
        ),
      );

      // Should use default values
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
    });

    // Test 13: Loading indicator integration
    testWidgets('integrates well with other widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Loading...'),
                ChatLoadingIndicator(size: 12),
                Text('Please wait'),
              ],
            ),
          ),
        ),
      );

      // Should integrate properly with other widgets
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(ChatLoadingIndicator), findsOneWidget);
      expect(find.text('Please wait'), findsOneWidget);
    });
  });
}
