// Widget tests for GenUI Chat AI
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gen_ui_chat_ai/main.dart';
import 'package:gen_ui_chat_ai/screens/chat_screen.dart';
import 'package:gen_ui_chat_ai/screens/settings_screen.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('should display main app structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Test that the main app loads without errors
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should navigate to chat screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify chat screen is loaded
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('should navigate to settings screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify settings screen is accessible
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('Chat Screen Tests', () {
    testWidgets('should display chat interface elements', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChatScreen()));
      
      // Test chat interface components
      expect(find.byKey(const ValueKey('chat_messages')), findsOneWidget);
      expect(find.byKey(const ValueKey('chat_input')), findsOneWidget);
    });

    testWidgets('should display message input field', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChatScreen()));
      
      // Test message input
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Settings Screen Tests', () {
    testWidgets('should display settings interface', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      
      // Test settings components
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
