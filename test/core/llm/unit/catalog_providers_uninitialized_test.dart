import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the pre-bootstrap failure path of [catalogServiceProvider].
///
/// Lives in its own file so it runs in a fresh isolate where the module-level
/// `_catalogServiceInstance` singleton and `PreferencesHolder.prefs` are still
/// null — the exact state a consumer would hit before `appBootstrapFastProvider`
/// completes. The provider must fail with a descriptive [StateError] (surfaced
/// through Riverpod's [ProviderException]) instead of a bare `!` null-dereference.
void main() {
  test(
    'catalogServiceProvider throws descriptive StateError pre-bootstrap',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(catalogServiceProvider),
        throwsA(
          predicate(
            (Object e) =>
                e.toString().contains('SharedPreferences not initialized'),
            'a descriptive StateError about missing SharedPreferences',
          ),
        ),
      );
    },
  );
}
