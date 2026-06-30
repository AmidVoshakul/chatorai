import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatorai/core/llm/models/model_config.dart';
import 'package:chatorai/core/llm/models/provider_config.dart';
import 'package:chatorai/core/llm/provider_catalog_service.dart';
import 'package:chatorai/features/settings/widgets/model_selection_dialog.dart';
import 'package:chatorai/shared/utils/secure_storage_service.dart';

class MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}

void main() {
  group('ModelSelectionDialog', () {
    testWidgets('initialSelectedIds are checked by canonical model.id', (
      tester,
    ) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'openrouter/free',
          displayName: 'OpenRouter Free',
          contextLength: 4096,
        ),
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: ['openrouter/openrouter/free'],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final freeTile = find.widgetWithText(CheckboxListTile, 'OpenRouter Free');
      expect(
        freeTile,
        findsOneWidget,
        reason: 'Dialog should render models after fetch',
      );

      final checkbox = tester.widget<CheckboxListTile>(freeTile);
      expect(checkbox.value, isTrue);
    });

    testWidgets('save returns canonical model.id list', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      List<String>? savedIds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: [],
              onSave: (ids) => savedIds = ids,
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Tap the model's checkbox to select it
      final owlTile = find.widgetWithText(CheckboxListTile, 'Owl Alpha');
      expect(owlTile, findsOneWidget);
      await tester.tap(owlTile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedIds, isNotNull);
      expect(savedIds, ['openrouter/owl-alpha']);
    });

    testWidgets('select all uses model.id', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'openrouter/free',
          displayName: 'OpenRouter Free',
          contextLength: 4096,
        ),
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      List<String>? savedIds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: [],
              onSave: (ids) => savedIds = ids,
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        savedIds,
        containsAll(['openrouter/openrouter/free', 'openrouter/owl-alpha']),
      );
    });

    testWidgets('search filters models by displayName', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'openrouter/free',
          displayName: 'OpenRouter Free',
          contextLength: 4096,
        ),
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: [],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Both models visible initially
      expect(
        find.widgetWithText(CheckboxListTile, 'OpenRouter Free'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'Owl Alpha'),
        findsOneWidget,
      );

      // Type search query
      await tester.enterText(find.byType(TextField), 'owl');
      await tester.pumpAndSettle();

      // Only Owl Alpha visible
      expect(
        find.widgetWithText(CheckboxListTile, 'Owl Alpha'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'OpenRouter Free'),
        findsNothing,
      );
    });

    testWidgets('deselect all clears selection', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      List<String>? savedIds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: ['openrouter/owl-alpha'],
              onSave: (ids) => savedIds = ids,
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Pre-selected: checkbox should be checked
      final tile = find.widgetWithText(CheckboxListTile, 'Owl Alpha');
      expect(tile, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(tile).value, isTrue);

      // Tap Deselect All
      await tester.tap(find.text('Deselect All'));
      await tester.pumpAndSettle();

      // Checkbox should be unchecked
      expect(tester.widget<CheckboxListTile>(tile).value, isFalse);

      // Save should return empty list
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedIds, isNotNull);
      expect(savedIds, isEmpty);
    });

    testWidgets('cancel button pops dialog without saving', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      bool onSaveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: [],
              onSave: (_) => onSaveCalled = true,
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // onSave should NOT have been called
      expect(onSaveCalled, isFalse);
    });

    testWidgets('checkbox toggle off deselects model', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: ['openrouter/owl-alpha'],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(CheckboxListTile, 'Owl Alpha');
      expect(tile, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(tile).value, isTrue);

      // Tap to deselect
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.widget<CheckboxListTile>(tile).value, isFalse);
    });

    testWidgets('search shows no-matches message', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: [],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Type non-matching search query
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No models match your search'), findsOneWidget);
    });

    testWidgets('cache hit validates pre-selected IDs against catalog', (
      tester,
    ) async {
      // This test covers lines 85-94: wasCached && _selectedIds.isNotEmpty
      // The dialog should validate that initialSelectedIds still exist in catalog
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      // Use invalid initialSelectedIds — the dialog should fall back to empty
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: ['openrouter/nonexistent-model'],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Model should be rendered
      final tile = find.widgetWithText(CheckboxListTile, 'Owl Alpha');
      expect(tile, findsOneWidget);

      // Checkbox should be unchecked (invalid IDs replaced by empty set)
      expect(tester.widget<CheckboxListTile>(tile).value, isFalse);
    });

    testWidgets('cache hit keeps valid pre-selected IDs', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      // Pre-populate models so wasCached=true
      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      // Use a valid initialSelectedId
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: ['openrouter/owl-alpha'],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      final tile = find.widgetWithText(CheckboxListTile, 'Owl Alpha');
      expect(tile, findsOneWidget);
      // Should remain checked (valid pre-selected ID)
      expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
    });

    testWidgets('shows empty state when no models available', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      // No models added — dialog should show "No models available"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: [],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Should show "No models available" message
      expect(find.text('No models available'), findsOneWidget);
    });

    testWidgets('shows count of selected models', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'catalog_discovered_at_openrouter': now,
        'catalog_cache_version': 4,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockStorage = MockSecureStorageService();

      final catalog = ProviderCatalogService(
        secureStorage: mockStorage,
        prefs: prefs,
        builtInProviders: [
          ProviderConfig.basic(
            id: 'openrouter',
            name: 'OpenRouter',
            baseUrl: 'https://openrouter.ai/api/v1',
          ),
        ],
      );

      await catalog.updateProviderModels('openrouter', [
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'openrouter/free',
          displayName: 'OpenRouter Free',
          contextLength: 4096,
        ),
        ModelConfig.basic(
          providerId: 'openrouter',
          modelName: 'owl-alpha',
          displayName: 'Owl Alpha',
          contextLength: 4096,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelectionDialog(
              providerId: 'openrouter',
              baseUrl: 'https://openrouter.ai/api/v1',
              apiKey: 'sk-test',
              initialSelectedIds: ['openrouter/openrouter/free'],
              onSave: (_) {},
              catalog: catalog,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Count shows "1 of 2 selected"
      expect(find.text('1 of 2 selected'), findsOneWidget);
    });
  });
}
