import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/services/network_service.dart';
import '../lib/widgets/network_aware_widget.dart';
import '../lib/l10n/app_localizations.dart';

void main() {
  group('Network Integration Tests', () {
    testWidgets('Complete network system works end-to-end', (WidgetTester tester) async {
      final networkService = NetworkService();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        Text('Network Status: ${networkService.status}'),
                        Text('Is Connected: ${networkService.isConnected}'),
                        ElevatedButton(
                          onPressed: () {
                            networkService.dismissSnackbar();
                          },
                          child: Text('Dismiss Snackbar'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Network Status: NetworkStatus.connected'), findsOneWidget);
      expect(find.text('Is Connected: true'), findsOneWidget);
      expect(find.byType(NetworkAwareWidget), findsOneWidget);
      
      // Test dismiss functionality
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      expect(networkService.userDismissed, isTrue);
    });

    testWidgets('NetworkAwareWidget handles localization correctly', (WidgetTester tester) async {
      final networkService = NetworkService();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: NetworkAwareWidget(
                child: Container(),
              ),
            ),
          ),
        ),
      );

      // Widget should build without errors
      expect(find.byType(NetworkAwareWidget), findsOneWidget);
    });

    test('NetworkService singleton behavior in real scenario', () {
      // Create multiple instances - should be the same
      final service1 = NetworkService();
      final service2 = NetworkService();
      final service3 = NetworkService();
      
      expect(identical(service1, service2), isTrue);
      expect(identical(service2, service3), isTrue);
      expect(identical(service1, service3), isTrue);
      
      // All should have same state
      expect(service1.status, service2.status);
      expect(service2.status, service3.status);
      expect(service1.isConnected, service2.isConnected);
      expect(service2.isConnected, service3.isConnected);
    });

    test('NetworkService handles state transitions correctly', () {
      final service = NetworkService();
      
      // Test initial state
      expect(service.userDismissed, isFalse);
      expect(service.isSnackbarVisible, isFalse);
      
      // Test dismiss
      service.dismissSnackbar();
      expect(service.userDismissed, isTrue);
      expect(service.isSnackbarVisible, isFalse);
      
      // Test show/hide
      service.hideSnackbar();
      expect(service.isSnackbarVisible, isFalse);
      
      // Test multiple operations
      service.hideSnackbar();
      service.dismissSnackbar();
      service.hideSnackbar();
      
      expect(service.userDismissed, isTrue);
      expect(service.isSnackbarVisible, isFalse);
    });

    test('NetworkService listener management', () {
      final service = NetworkService();
      var notificationCount = 0;
      
      void listener() => notificationCount++;
      
      // Add listener
      service.addListener(listener);
      expect(service.hasListeners, isTrue);
      
      // Notify listeners
      service.notifyListeners();
      expect(notificationCount, equals(1));
      
      // Remove listener
      service.removeListener(listener);
      expect(service.hasListeners, isFalse);
      
      // Notify again - should not call removed listener
      service.notifyListeners();
      expect(notificationCount, equals(1)); // Still 1, not 2
    });

    test('NetworkStatus enum completeness', () {
      // Verify all expected enum values exist
      expect(NetworkStatus.values.length, equals(3));
      
      // Verify specific values
      expect(NetworkStatus.values, contains(NetworkStatus.connected));
      expect(NetworkStatus.values, contains(NetworkStatus.disconnected));
      expect(NetworkStatus.values, contains(NetworkStatus.checking));
      
      // Test enum properties
      expect(NetworkStatus.connected.index, isA<int>());
      expect(NetworkStatus.disconnected.index, isA<int>());
      expect(NetworkStatus.checking.index, isA<int>());
    });
  });

  group('Network Error Handling', () {
    test('NetworkService handles multiple disposals gracefully', () {
      final service = NetworkService();
      
      // Multiple disposals should not throw
      expect(() => service.dispose(), returnsNormally);
      expect(() => service.dispose(), returnsNormally);
      expect(() => service.dispose(), returnsNormally);
    });

    test('NetworkService operations after disposal are handled', () {
      final service = NetworkService();
      service.dispose();
      
      // Operations after disposal should be handled gracefully
      // Note: This depends on implementation - some might throw
      expect(service.userDismissed, isA<bool>());
      expect(service.isSnackbarVisible, isA<bool>());
    });
  });
}
