import 'dart:io';

import 'package:chatorai/core/skills/skill_marketplace_catalog.dart';
import 'package:chatorai/core/skills/skill_parser.dart';
import 'package:chatorai/core/skills/skill_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog ids are unique', () {
    final ids = skillMarketplaceCatalog.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate entry id');
  });

  test('descriptionKey is either absent or non-empty', () {
    for (final e in skillMarketplaceCatalog) {
      expect(
        e.descriptionKey == null || e.descriptionKey!.isNotEmpty,
        isTrue,
        reason: 'descriptionKey must be null or non-empty for "${e.id}"',
      );
    }
  });

  test('bundled entries point to an existing, parseable SKILL.md asset', () {
    for (final e in skillMarketplaceCatalog.where((e) => e.isBundled)) {
      final file = File(e.assetPath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'missing asset ${e.assetPath} for "${e.id}"',
      );
      final parsed = SkillParser.parse(e.assetPath, file.readAsStringSync());
      expect(
        parsed.name,
        isNotEmpty,
        reason: 'unparseable frontmatter in ${e.assetPath}',
      );
    }
  });

  test('bundled id equals assetSlug so install slug matches lookup key', () {
    for (final e in skillMarketplaceCatalog.where((e) => e.isBundled)) {
      expect(e.id, e.assetSlug, reason: 'id/assetSlug mismatch for "${e.id}"');
    }
  });

  test('every id is slug-safe so installed-dir name matches the lookup key', () {
    for (final e in skillMarketplaceCatalog) {
      expect(
        SkillWriter.slugify(e.id),
        e.id,
        reason:
            'id "${e.id}" is not slug-safe: installBundledSkill writes to '
            '"${SkillWriter.slugify(e.id)}" but isInstalled looks up "${e.id}"',
      );
    }
  });

  test('categories() returns distinct categories in enum order', () {
    final cats = skillMarketplaceCategories();
    expect(cats, cats.toSet().toList());
    for (final e in skillMarketplaceCatalog) {
      expect(cats, contains(e.category));
    }
  });
}
