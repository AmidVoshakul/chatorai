import 'dart:async';

import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test: [chatAiServiceProvider] must be usable from the first frame
/// (while [catalogInitializationProvider] is still loading) without throwing
/// `StateError('Catalog not yet initialized')`. The early-mounted ChatScreen
/// depends on it, so a throw here crashes/loops the UI.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PreferencesHolder.prefs = await SharedPreferences.getInstance();
  });

  test('chatAiServiceProvider returns a service while catalog is loading', () {
    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(SecureStorageService()),
      ],
    );

    // Was: threw StateError('Catalog not yet initialized') during loading.
    expect(
      () => container.read(chatAiServiceProvider),
      isNot(throwsStateError),
    );
    expect(container.read(chatAiServiceProvider), isNotNull);
  });

  test('chatAiServiceProvider instance survives catalog warm completion '
      '(no rebuild/dispose race)', () async {
    final container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(SecureStorageService()),
      ],
    );
    addTearDown(container.dispose);

    final before = container.read(chatAiServiceProvider);

    // Settle the warm future (data or error). The identity assertion below is
    // only meaningful if the future actually settles, so a hang must fail the
    // test loudly rather than silently pass with no coverage.
    try {
      await container
          .read(catalogInitializationProvider.future)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      fail(
        'catalogInitializationProvider must settle in the test environment '
        '(data or error) for this regression test to be meaningful.',
      );
    } catch (_) {
      // Warm fails in a unit-test env (no platform plugins); that still
      // settles the future, which is all the identity check requires.
    }

    final after = container.read(chatAiServiceProvider);
    expect(identical(before, after), isTrue);
  });
}
