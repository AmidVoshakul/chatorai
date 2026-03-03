import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../lib/services/network_service.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  group('NetworkService Simple Tests', () {
    // setUpAll(() {
    //   // Initialize the singleton once for all tests
    //   NetworkService();
    // });

    // test('service follows singleton pattern', () {
    //   final service1 = NetworkService();
    //   final service2 = NetworkService();
    //
    //   expect(identical(service1, service2), isTrue);
    //   expect(service1.status, service2.status);
    // });

    test('initial state is checking', () {
      final networkService = NetworkService();
      expect(networkService.status, NetworkStatus.checking);
      expect(networkService.isConnected, isFalse);
      expect(networkService.isSnackbarVisible, isFalse);
      expect(networkService.userDismissed, isFalse);
    });

    test('dismissSnackbar updates state correctly', () {
      final networkService = NetworkService();
      networkService.dismissSnackbar();

      expect(networkService.userDismissed, isTrue);
      expect(networkService.isSnackbarVisible, isFalse);
    });

    test('hideSnackbar updates visibility', () {
      final networkService = NetworkService();
      networkService.hideSnackbar();

      expect(networkService.isSnackbarVisible, isFalse);
    });

    test('multiple dismiss calls are safe', () {
      final networkService = NetworkService();
      networkService.dismissSnackbar();
      networkService.dismissSnackbar();
      networkService.dismissSnackbar();

      expect(networkService.userDismissed, isTrue);
    });

    test('listener management works', () {
      final networkService = NetworkService();
      var callCount = 0;
      void listener() => callCount++;

      networkService.addListener(listener);
      networkService.notifyListeners();

      expect(callCount, equals(1));

      networkService.removeListener(listener);
      networkService.notifyListeners();

      expect(callCount, equals(1)); // Should not increase
    });

    test('NetworkStatus enum has correct values', () {
      expect(NetworkStatus.values.length, equals(3));
      expect(NetworkStatus.values, contains(NetworkStatus.connected));
      expect(NetworkStatus.values, contains(NetworkStatus.disconnected));
      expect(NetworkStatus.values, contains(NetworkStatus.checking));
    });

    test('state consistency after multiple operations', () {
      final networkService = NetworkService();

      // Perform multiple operations
      networkService.hideSnackbar();
      networkService.showSnackbar();
      networkService.dismissSnackbar();
      networkService.hideSnackbar();

      // Final state should be consistent
      expect(networkService.userDismissed, isTrue);
      expect(networkService.isSnackbarVisible, isFalse);
    });

    test('connection status getter works correctly', () {
      final networkService = NetworkService();

      // Initially checking, so not connected
      expect(networkService.isConnected, isFalse);

      // This would change based on actual network conditions
      // In real scenarios, the status would update based on network events
    });
  });

  group('NetworkService Edge Cases', () {
    test('handles rapid state changes', () async {
      final service = NetworkService();

      // Rapid state changes
      for (int i = 0; i < 10; i++) {
        service.hideSnackbar();
        service.showSnackbar();
        service.dismissSnackbar();
      }

      expect(service.isSnackbarVisible, isFalse);
      expect(service.userDismissed, isTrue);
    });

    test('listener cleanup works correctly', () {
      final service = NetworkService();
      final listeners = <void Function()>[];

      // Add many listeners
      for (int i = 0; i < 5; i++) {
        final listener = () {};
        listeners.add(listener);
        service.addListener(listener);
      }

      expect(service.hasListeners, isTrue);

      // Remove all listeners
      for (final listener in listeners) {
        service.removeListener(listener);
      }

      expect(service.hasListeners, isFalse);
    });
  });
}
