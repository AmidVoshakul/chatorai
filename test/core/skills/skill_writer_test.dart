import 'dart:io';

import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_parser.dart';
import 'package:chatorai/core/skills/skill_source.dart';
import 'package:chatorai/core/skills/skill_writer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// In-memory source that returns skills already materialized on disk (mimics
/// the download cache a [UrlSource] populates before install).
class _FakeSource implements SkillSource {
  _FakeSource(this.skills);
  final List<SkillInfo> skills;

  @override
  String get key => 'fake';

  @override
  Future<List<SkillInfo>> discover() async => skills;
}

void main() {
  late Directory tmp;
  late SkillWriter writer;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('skill_writer_test');
    writer = SkillWriter(globalConfigDir: () async => p.join(tmp.path, 'cfg'));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('roots', () {
    test('globalSkillsRoot uses <configDir>/skills', () async {
      final root = await writer.globalSkillsRoot();
      expect(root, p.join(tmp.path, 'cfg', 'skills'));
    });

    test('projectSkillsRoot uses <root>/.chatorai/skills', () {
      final root = writer.projectSkillsRoot(Directory('/proj'));
      expect(root, p.join('/proj', '.chatorai', 'skills'));
    });
  });

  group('createSkill', () {
    test('writes a parseable SKILL.md with frontmatter', () async {
      final scope = p.join(tmp.path, 'skills');
      final dir = await writer.createSkill(
        scopeRoot: scope,
        name: 'My Cool Skill',
        description: 'Does cool things',
        content: '# Heading\nbody text',
      );

      expect(p.basename(dir), 'my-cool-skill');
      final md = File(p.join(dir, kSkillFileName)).readAsStringSync();
      final parsed = SkillParser.parse(p.join(dir, kSkillFileName), md);
      expect(parsed.name, 'My Cool Skill');
      expect(parsed.description, 'Does cool things');
      expect(parsed.content, contains('body text'));
    });

    test('falls back to a placeholder body when content empty', () async {
      final scope = p.join(tmp.path, 'skills');
      final dir = await writer.createSkill(
        scopeRoot: scope,
        name: 'Empty',
        description: 'no body',
      );
      final md = File(p.join(dir, kSkillFileName)).readAsStringSync();
      final parsed = SkillParser.parse(p.join(dir, kSkillFileName), md);
      expect(parsed.name, 'Empty');
      expect(parsed.content, contains('# Empty'));
    });

    test('escapes YAML-special chars so frontmatter stays parseable', () async {
      final scope = p.join(tmp.path, 'skills');
      const trickyName = 'Rev: "the" #reviewer';
      const trickyDesc = 'Line one\nLine two: with colon # and "quotes"';
      final dir = await writer.createSkill(
        scopeRoot: scope,
        name: trickyName,
        description: trickyDesc,
        content: 'body',
      );
      final md = File(p.join(dir, kSkillFileName)).readAsStringSync();
      final parsed = SkillParser.parse(p.join(dir, kSkillFileName), md);
      expect(parsed.name, trickyName);
      expect(parsed.description, trickyDesc);
    });

    test('rejects creating a skill whose slug already exists', () async {
      final scope = p.join(tmp.path, 'skills');
      await writer.createSkill(
        scopeRoot: scope,
        name: 'Code Reviewer',
        description: 'first',
      );
      expect(
        () => writer.createSkill(
          scopeRoot: scope,
          name: 'code reviewer',
          description: 'second',
        ),
        throwsArgumentError,
      );
      final md = File(
        p.join(scope, 'code-reviewer', kSkillFileName),
      ).readAsStringSync();
      final parsed = SkillParser.parse('x', md);
      expect(parsed.description, 'first');
    });
  });

  group('deleteSkill', () {
    test('removes a managed skill directory', () async {
      final scope = p.join(tmp.path, 'skills');
      final dir = await writer.createSkill(
        scopeRoot: scope,
        name: 'Temp',
        description: 'to delete',
      );
      expect(Directory(dir).existsSync(), isTrue);

      await writer.deleteSkill(scopeRoot: scope, skillDirectory: dir);
      expect(Directory(dir).existsSync(), isFalse);
    });

    test('rejects a directory outside the scope root', () async {
      final scope = p.join(tmp.path, 'skills');
      final outside = p.join(tmp.path, 'evil');
      await Directory(outside).create(recursive: true);

      expect(
        () => writer.deleteSkill(scopeRoot: scope, skillDirectory: outside),
        throwsArgumentError,
      );
      expect(Directory(outside).existsSync(), isTrue);
    });

    test('rejects path traversal escaping the scope root', () async {
      final scope = p.join(tmp.path, 'skills');
      final traversal = p.join(scope, '..', 'escape');
      expect(
        () => writer.deleteSkill(scopeRoot: scope, skillDirectory: traversal),
        throwsArgumentError,
      );
    });
  });

  group('installFromSource', () {
    test('copies discovered skill dirs into destRoot', () async {
      // Simulate a downloaded skill living in a cache dir.
      final cache = p.join(tmp.path, 'cache', 'awesome');
      await Directory(cache).create(recursive: true);
      File(
        p.join(cache, kSkillFileName),
      ).writeAsStringSync('---\nname: Awesome\ndescription: d\n---\nbody');
      File(p.join(cache, 'helper.txt')).writeAsStringSync('extra');

      final source = _FakeSource([
        SkillInfo(
          name: 'Awesome',
          description: 'd',
          directory: cache,
          content: 'body',
        ),
      ]);

      final dest = p.join(tmp.path, 'skills');
      final names = await writer.installFromSource(
        source: source,
        destRoot: dest,
      );

      expect(names, ['Awesome']);
      final installedMd = File(p.join(dest, 'awesome', kSkillFileName));
      final installedExtra = File(p.join(dest, 'awesome', 'helper.txt'));
      expect(installedMd.existsSync(), isTrue);
      expect(installedExtra.existsSync(), isTrue);
    });

    test('skips skills with an empty or missing source directory', () async {
      final source = _FakeSource([
        const SkillInfo(
          name: 'NoDir',
          description: 'd',
          directory: '',
          content: 'body',
        ),
        SkillInfo(
          name: 'Missing',
          description: 'd',
          directory: p.join(tmp.path, 'does', 'not', 'exist'),
          content: 'body',
        ),
      ]);

      final dest = p.join(tmp.path, 'skills');
      final names = await writer.installFromSource(
        source: source,
        destRoot: dest,
      );

      expect(names, isEmpty);
      expect(Directory(dest).existsSync(), isFalse);
    });
  });

  group('installBundledSkill', () {
    test('writes SKILL.md verbatim under <scopeRoot>/<slug>', () async {
      final root = p.join(tmp.path, 'skills');
      const md = '---\nname: "Code Reviewer"\ndescription: "d"\n---\n\nbody\n';

      final dir = await writer.installBundledSkill(
        scopeRoot: root,
        slug: 'code-reviewer',
        content: md,
      );

      expect(dir, p.join(root, 'code-reviewer'));
      final written = File(p.join(dir, kSkillFileName)).readAsStringSync();
      expect(written, md);
      final parsed = SkillParser.parse(p.join(dir, kSkillFileName), written);
      expect(parsed.name, 'Code Reviewer');
    });

    test('rejects installing over an existing slug', () async {
      final root = p.join(tmp.path, 'skills');
      await writer.installBundledSkill(
        scopeRoot: root,
        slug: 'dry',
        content: '---\nname: "DRY"\ndescription: "d"\n---\n\nx\n',
      );

      expect(
        () => writer.installBundledSkill(
          scopeRoot: root,
          slug: 'dry',
          content: 'other',
        ),
        throwsArgumentError,
      );
    });
  });
}
