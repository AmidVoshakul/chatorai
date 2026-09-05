import 'package:chatorai/core/llm/catalog_providers.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the catalog provider refactor: the synchronous [catalogServiceProvider]
/// (and its alias [providerCatalogServiceProvider]) must be usable from the first
/// frame WITHOUT throwing, so [ChatScreen]/Welcome can mount before the heavy
/// `preloadApiKeys` (run by [catalogInitializationProvider]) finishes.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Mirror the bootstrap: load SharedPreferences (async) then hand it to the
    // synchronous provider via PreferencesHolder.
    PreferencesHolder.prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      secureStorageServiceProvider.overrideWithValue(SecureStorageService()),
    ],
  );

  test('catalogServiceProvider returns a usable instance without throwing', () {
    final container = makeContainer();

    final service = container.read(catalogServiceProvider);
    expect(service, isA<ProviderCatalogService>());

    // The service is callable synchronously before preloadApiKeys runs:
    // getModel must not throw for a missing id (returns null).
    expect(service.getModel('does/not/exist'), isNull);
  });

  test('providerCatalogServiceProvider alias does not throw StateError', () {
    final container = makeContainer();

    // Was: threw StateError('Catalog not yet initialized'). Now returns instance.
    expect(
      () => container.read(providerCatalogServiceProvider),
      isNot(throwsStateError),
    );
    expect(
      container.read(providerCatalogServiceProvider),
      isA<ProviderCatalogService>(),
    );
  });

  test('same instance is shared across providers (preload warms it)', () {
    final container = makeContainer();

    final a = container.read(catalogServiceProvider);
    final b = container.read(providerCatalogServiceProvider);
    expect(identical(a, b), isTrue);
  });
}
