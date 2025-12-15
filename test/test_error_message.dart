import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gen_ui_chat_ai/widgets/chat/error_message.dart';
import 'package:gen_ui_chat_ai/services/chat_storage_service.dart';

void main() {
  late ChatStorageService chatStorageService;

  setUp(() {
    chatStorageService = ChatStorageService();
  });

  testWidgets('Error message displays correctly with JSON error', (WidgetTester tester) async {
    final jsonError = '{"error":{"message":"User not found.","code":401}}';

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorMessage(
          errorMessage: jsonError,
          chatId: 'test-chat-id',
          messageId: 'test-message-id',
          chatStorageService: chatStorageService,
          onMessageDeleted: () {},
        ),
      ),
    );

    // Verify error header is displayed
    expect(find.text('Error Error (Code: 401)'), findsOneWidget);

    // Verify error message content is displayed
    expect(find.text('User not found.'), findsOneWidget);

    // Verify error code is displayed
    expect(find.text('Error Code: 401'), findsOneWidget);

    // Verify action buttons are present (using tooltips)
    expect(find.byTooltip('Copy'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('Error message displays correctly with plain text error', (WidgetTester tester) async {
    final plainError = 'Connection timeout error';

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorMessage(
          errorMessage: plainError,
          chatId: 'test-chat-id',
          messageId: 'test-message-id',
          chatStorageService: chatStorageService,
          onMessageDeleted: () {},
        ),
      ),
    );

    // Verify error header is displayed
    expect(find.text('Error message'), findsOneWidget);

    // Verify error message content is displayed
    expect(find.text('Connection timeout error'), findsOneWidget);

    // Verify action buttons are present (using tooltips)
    expect(find.byTooltip('Copy'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
  });

  testWidgets('Error message shows full content without truncation', (WidgetTester tester) async {
    final longError = '{"error":{"message":"This is a very long error message that should be displayed in full without any truncation.","code":500}}';

    await tester.pumpWidget(
      MaterialApp(
        home: ErrorMessage(
          errorMessage: longError,
          chatId: 'test-chat-id',
          messageId: 'test-message-id',
          chatStorageService: chatStorageService,
          onMessageDeleted: () {},
        ),
      ),
    );

    // Should show full content (no truncation since expand/collapse was removed)
    expect(find.text('This is a very long error message that should be displayed in full without any truncation.'), findsOneWidget);

    // Verify error code is displayed
    expect(find.text('Error Code: 500'), findsOneWidget);
  });

  testWidgets('Error message shows loading indicator when showLoadingFirst is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorMessage(
          errorMessage: 'Test error',
          chatId: 'test-chat-id',
          messageId: 'test-message-id',
          chatStorageService: chatStorageService,
          onMessageDeleted: () {},
          showLoadingFirst: true,
        ),
      ),
    );

    // Initially should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for transition to complete
    await tester.pump(const Duration(milliseconds: 300));

    // Now should show error message
    expect(find.text('Test error'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
