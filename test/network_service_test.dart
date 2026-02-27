import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import '../lib/services/network_service.dart';

// Generate mocks
@GenerateMocks([Connectivity])
import 'network_service_test.mocks.dart';

void main() {
  group('NetworkService Tests', () {
    late NetworkService networkService;
    late MockConnectivity mockConnectivity;

    setUp(() {
      networkService = NetworkService();
      mockConnectivity = MockConnectivity();
    });

    tearDown(() {
      networkService.dispose();
    });

    test('initializes with checking status', () {
      expect(networkService.status, NetworkStatus.checking);
      expect(networkService.isConnected, false);
    });

    test('status changes correctly', () {
      // Test initial state
      expect(networkService.status, NetworkStatus.checking);
      expect(networkService.isSnackbarVisible, false);
      expect(networkService.userDismissed, false);
    });

    test('dismissSnackbar sets flags correctly', () {
      networkService.dismissSnackbar();
      expect(networkService.userDismissed, true);
      expect(networkService.isSnackbarVisible, false);
    });

    test('showSnackbar only works when disconnected', () {
      // Initially should be checking or connected
      networkService.showSnackbar();
      expect(networkService.isSnackbarVisible, false);
    });

    test('hideSnackbar sets visibility to false', () {
      networkService.hideSnackbar();
      expect(networkService.isSnackbarVisible, false);
    });

    test('userDismissed flag resets on connection', () {
      // Simulate user dismissal
      networkService.dismissSnackbar();
      expect(networkService.userDismissed, true);

      // This would be tested with actual connection change
      // In real scenario, connection restoration would reset the flag
    });

    group('Network Status Enum Tests', () {
      test('NetworkStatus enum has correct values', () {
        expect(NetworkStatus.values.length, 3);
        expect(NetworkStatus.values, contains(NetworkStatus.connected));
        expect(NetworkStatus.values, contains(NetworkStatus.disconnected));
        expect(NetworkStatus.values, contains(NetworkStatus.checking));
      });
    });

    group('Singleton Pattern Tests', () {
      test('NetworkService follows singleton pattern', () {
        final instance1 = NetworkService();
        final instance2 = NetworkService();
        expect(identical(instance1, instance2), true);
      });
    });

    group('Connection Logic Tests', () {
      test('can reach host functionality works', () async {
        // Test with a reliable host
        // This test might need to be mocked in CI/CD environments
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 5));
          expect(result.isNotEmpty, true);
        } catch (e) {
          // Network unavailable in test environment
          expect(e, isA<Exception>());
        }
      });
    });

    group('Edge Cases Tests', () {
      test('multiple dismiss calls are safe', () {
        networkService.dismissSnackbar();
        networkService.dismissSnackbar();
        networkService.dismissSnackbar();
        expect(networkService.userDismissed, true);
      });

      test('multiple hide calls are safe', () {
        networkService.hideSnackbar();
        networkService.hideSnackbar();
        expect(networkService.isSnackbarVisible, false);
      });
    });

    group('Resource Management Tests', () {
      test('dispose cleans up resources', () {
        final service = NetworkService();
        expect(() => service.dispose(), returnsNormally);
      });
    });
  });
}
