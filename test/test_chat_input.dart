import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_input.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

void main() {
  group('ChatInput Widget Tests', () {
    late MessageData? lastSentMessage;

    setUp(() {
      lastSentMessage = null;
    });

    // Helper to create test widget with localizations
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
        ],
        home: Scaffold(
          body: child,
        ),
      );
    }

    // Test 1: Basic widget rendering
    testWidgets('renders chat input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Should show the input field
      expect(find.byType(TextField), findsOneWidget);

      // Should show the dynamic button (Container with InkWell)
      expect(find.byType(InkWell), findsOneWidget);
    });

    // Test 2: Message sending functionality
    testWidgets('sends message when send button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Enter text in the input field
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.pump();

      // Tap send button
      final sendButton = find.byType(InkWell);
      await tester.tap(sendButton);
      await tester.pump();

      // Verify message was sent
      expect(lastSentMessage?.text, 'Test message');
    });

    // Test 3: Empty message handling
    testWidgets('does not send empty messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Leave input field empty
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pump();

      // Tap send button
      final sendButton = find.byType(InkWell);
      await tester.tap(sendButton);
      await tester.pump();

      // Verify no message was sent
      expect(lastSentMessage, isNull);
    });

    // Test 4: Input field placeholder text
    testWidgets('shows correct placeholder text', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Should show placeholder text
      final textField = find.byType(TextField);
      expect(tester.widget<TextField>(textField).decoration?.hintText, 'Type your message...');
    });

    // Test 5: Input field focus
    testWidgets('focuses input field when focusNode is provided', (WidgetTester tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: focusNode,
          ),
        ),
      );

      // Focus should be set when focusNode is provided
      expect(focusNode.hasFocus, true);
    });

    // Test 6: Visual appearance
    testWidgets('has correct visual appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Check for proper layout elements
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
    });

    // Test 7: Error handling
    testWidgets('handles callbacks gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {},
            onToggleStreaming: (isStreaming) {},
            focusNode: FocusNode(),
          ),
        ),
      );

      // Should not crash
      expect(find.byType(ChatInput), findsOneWidget);
    });

    // Test 8: Keyboard input handling
    testWidgets('handles keyboard input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Enter text using keyboard simulation
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Keyboard input test');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Keyboard input test'), findsOneWidget);
    });

    // Test 9: Widget rebuild handling
    testWidgets('handles widget rebuilds correctly', (WidgetTester tester) async {
      var key = GlobalKey();

      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            key: key,
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Enter text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.pump();

      // Rebuild widget
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            key: key,
            onSendMessage: (message) {
              lastSentMessage = message;
            },
            onToggleStreaming: (isStreaming) {
            },
            focusNode: FocusNode(),
          ),
        ),
      );

      // Text should be preserved
      expect(find.text('Test message'), findsOneWidget);
    });
  });
}
