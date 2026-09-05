import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/gui/features/chat/services/network_service.dart';

void main() {
  group('NetworkState', () {
    test('isConnected returns true when status is connected', () {
      const state = NetworkState(status: NetworkStatus.connected);
      expect(state.isConnected, true);
    });

    test('isConnected returns false when status is disconnected', () {
      const state = NetworkState(status: NetworkStatus.disconnected);
      expect(state.isConnected, false);
    });

    test('isConnected returns false when status is checking', () {
      const state = NetworkState(status: NetworkStatus.checking);
      expect(state.isConnected, false);
    });

    test('copyWith creates new instance with updated values', () {
      const state = NetworkState();
      final newState = state.copyWith(
        status: NetworkStatus.connected,
        isSnackbarVisible: true,
      );

      expect(newState.status, NetworkStatus.connected);
      expect(newState.isSnackbarVisible, true);
    });

    test('copyWith preserves original values when not specified', () {
      const state = NetworkState(
        status: NetworkStatus.connected,
        isSnackbarVisible: true,
        userDismissed: true,
      );
      final newState = state.copyWith(status: NetworkStatus.disconnected);

      expect(newState.status, NetworkStatus.disconnected);
      expect(newState.isSnackbarVisible, true);
      expect(newState.userDismissed, true);
    });
  });

  group('NetworkStatus', () {
    test('enum has expected values', () {
      expect(NetworkStatus.values.length, 3);
      expect(NetworkStatus.values, contains(NetworkStatus.connected));
      expect(NetworkStatus.values, contains(NetworkStatus.disconnected));
      expect(NetworkStatus.values, contains(NetworkStatus.checking));
    });
  });
}
