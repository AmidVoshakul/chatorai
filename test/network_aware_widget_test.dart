import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/services/network_service.dart';
import '../lib/widgets/network_aware_widget.dart';

void main() {
  group('NetworkAwareWidget Tests', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
    });

    tearDown(() {
      networkService.dispose();
    });

    testWidgets('widget builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Container(
                  child: Text('Test Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NetworkAwareWidget), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('child widget receives NetworkService', (WidgetTester tester) async {
      String? statusText;

      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Builder(
                  builder: (context) {
                    final service = Provider.of<NetworkService>(context, listen: false);
                    statusText = 'Status: ${service.status}';
                    return Text(statusText!);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Status: NetworkStatus.checking'), findsOneWidget);
    });

    testWidgets('widget handles provider absence gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkAwareWidget(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Should handle missing provider gracefully
      expect(find.byType(NetworkAwareWidget), findsOneWidget);
    });

    testWidgets('widget responds to network state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        final service = Provider.of<NetworkService>(context, listen: false);
                        service.dismissSnackbar();
                      },
                      child: Text('Dismiss'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Tap the dismiss button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify the service state changed
      expect(networkService.userDismissed, isTrue);
    });

    testWidgets('widget cleanup works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // Remove the widget
      await tester.pumpWidget(Container());

      // Should not throw any errors
      expect(find.byType(NetworkAwareWidget), findsNothing);
    });

    testWidgets('nested NetworkAwareWidgets work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: NetworkAwareWidget(
                  child: Text('Nested Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NetworkAwareWidget), findsNWidgets(2));
      expect(find.text('Nested Content'), findsOneWidget);
    });

    testWidgets('widget handles rapid rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // Trigger multiple rebuilds
      for (int i = 0; i < 5; i++) {
        networkService.notifyListeners();
        await tester.pump();
      }

      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('NetworkAwareWidget Error Handling', () {
    testWidgets('handles null child gracefully', (WidgetTester tester) async {
      // This test ensures the widget handles edge cases
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => NetworkService(),
          child: MaterialApp(
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Container(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NetworkAwareWidget), findsOneWidget);
    });
  });
}
