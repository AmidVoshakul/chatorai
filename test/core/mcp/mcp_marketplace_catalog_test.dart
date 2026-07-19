import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/core/mcp/mcp_config.dart';
import 'package:chatorai/core/mcp/mcp_marketplace_catalog.dart';

void main() {
  group('mcpMarketplaceCatalog', () {
    test('contains all 15 entries', () {
      expect(mcpMarketplaceCatalog, hasLength(15));
    });

    test('all ids are unique', () {
      final ids = mcpMarketplaceCatalog.map((e) => e.id).toList();
      expect(Set<String>.from(ids), hasLength(ids.length));
    });

    test('every entry has a non-empty description key', () {
      for (final e in mcpMarketplaceCatalog) {
        expect(e.descriptionKey, startsWith('mcpMarketDesc'));
        expect(e.descriptionKey.length, greaterThan('mcpMarketDesc'.length));
      }
    });

    test('toConfig produces an enabled remote server with the catalog url', () {
      for (final e in mcpMarketplaceCatalog) {
        final config = e.toConfig();
        expect(config.isRemote, isTrue);
        expect(config.url, e.url);
        expect(config.enabled, isTrue);
      }
    });

    test('known servers resolve their brand asset when provided', () {
      final withAsset = mcpMarketplaceCatalog.where((e) => e.iconAsset != null);
      expect(withAsset, isNotEmpty);
      for (final e in withAsset) {
        expect(e.iconAsset, startsWith('assets/provider/'));
      }
    });

    test('every entry has a brand color', () {
      for (final e in mcpMarketplaceCatalog) {
        expect(e.brandColor, isNotEmpty);
      }
    });

    test('marketplaceCategories returns only present categories', () {
      final cats = marketplaceCategories();
      expect(cats, isNotEmpty);
      for (final e in mcpMarketplaceCatalog) {
        expect(cats, contains(e.category));
      }
    });
  });
}
