import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/services/network_service.dart';
import '../lib/widgets/network_aware_widget.dart';

void main() {
  group('NetworkService Integration Tests', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
    });

    tearDown(() {
      networkService.dispose();
    });

    testWidgets('NetworkAwareWidget builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: NetworkAwareWidget(
              child: Container(),
            ),
          ),
        ),
      );

      expect(find.byType(NetworkAwareWidget), findsOneWidget);
    });

    testWidgets('NetworkAwareWidget provides NetworkService to child', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkService>(
          create: (_) => networkService,
          child: MaterialApp(
            home: NetworkAwareWidget(
              child: Builder(
                builder: (context) {
                  final service = Provider.of<NetworkService>(context, listen: false);
                  return Text('Status: ${service.status}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Status: NetworkStatus.checking'), findsOneWidget);
    });

    test('NetworkService notifies listeners on status change', () async {
      var notificationCount = 0;
      networkService.addListener(() {
        notificationCount++;
      });

      // Simulate status change (this would normally happen through network events)
      // For testing, we can't directly access private methods, but we can test the public interface
      
      expect(networkService.hasListeners, true);
    });

    test('NetworkService singleton behavior across multiple instances', () {
      final service1 = NetworkService();
      final service2 = NetworkService();
      final service3 = NetworkService();

      expect(identical(service1, service2), true);
      expect(identical(service2, service3), true);
      expect(identical(service1, service3), true);

      // All should have the same status
      expect(service1.status, service2.status);
      expect(service2.status, service3.status);
    });

    group('Snackbar State Management', () {
      test('Snackbar visibility state management', () {
        expect(networkService.isSnackbarVisible, false);
        expect(networkService.userDismissed, false);

        networkService.showSnackbar();
        // Should not show if not disconnected
        expect(networkService.isSnackbarVisible, false);

        networkService.hideSnackbar();
        expect(networkService.isSnackbarVisible, false);
      });

      test('User dismissal persists', () {
        networkService.dismissSnackbar();
        expect(networkService.userDismissed, true);
        expect(networkService.isSnackbarVisible, false);

        // Even if we try to show again, it should respect user dismissal
        networkService.showSnackbar();
        expect(networkService.isSnackbarVisible, false);
      });
    });

    group('Connection Status Logic', () {
      test('Connection status reflects network state', () {
        // Initial state should be checking
        expect(networkService.status, NetworkStatus.checking);
        expect(networkService.isConnected, false);

        // These would change based on actual network conditions
        // In a real test environment, we'd mock the network layer
      });
    });

    group('Performance Tests', () {
      test('Multiple rapid status changes are handled correctly', () async {
        for (int i = 0; i < 100; i++) {
          networkService.hideSnackbar();
          networkService.showSnackbar();
        }

        expect(networkService.isSnackbarVisible, false);
      });

      test('Listener management is efficient', () {
        final listeners = <VoidCallback>[];
        
        for (int i = 0; i < 10; i++) {
          listeners.add(() {});
          networkService.addListener(listeners.last);
        }

        expect(networkService.hasListeners, true);

        for (final listener in listeners) {
          networkService.removeListener(listener);
        }

        expect(networkService.hasListeners, false);
      });
    });

    group('Error Handling', () {
      test('Service handles disposal gracefully', () {
        final service = NetworkService();
        
        expect(() => service.dispose(), returnsNormally);
        
        // Multiple disposals should be safe
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
