import 'package:chatorai/core/skills/models/skill_info.dart';
import 'package:chatorai/core/skills/skill_error.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Parses a SKILL.md file into a [SkillInfo].
///
/// Expects YAML frontmatter between `---` delimiters, followed by markdown body.
/// Required fields in frontmatter: `name` (string), `description` (string).
class SkillParser {
  /// Parses the given file content.
  ///
  /// [filePath] absolute path to SKILL.md.
  /// [content] full text of the file.
  /// Returns parsed [SkillInfo] with body content (without frontmatter).
  /// Throws [ParseError] on any failure.
  static SkillInfo parse(String filePath, String content) {
    final directory = p.dirname(filePath);
    final defaultName = p.basename(directory);

    final lines = content.split('\n');

    // Find frontmatter boundaries
    int? fmStart, fmEnd;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        if (fmStart == null) {
          fmStart = i;
        } else {
          fmEnd = i;
          break;
        }
      }
    }

    if (fmStart == null || fmEnd == null) {
      throw ParseError(
        'Missing frontmatter delimiters (---)',
        filePath: filePath,
      );
    }

    final frontMatterLines = lines.sublist(fmStart + 1, fmEnd);
    final bodyLines = lines.sublist(fmEnd + 1);
    final body = bodyLines.join('\n').trimLeft();

    // Parse YAML frontmatter
    final frontMatterStr = frontMatterLines.join('\n');
    YamlMap? yaml;
    try {
      yaml = loadYaml(frontMatterStr) as YamlMap?;
    } catch (e) {
      throw ParseError('YAML parse error: $e', filePath: filePath);
    }

    if (yaml == null) {
      throw ParseError('Empty frontmatter', filePath: filePath);
    }

    // Extract required fields
    final name = yaml['name']?.toString() ?? defaultName;
    final description = yaml['description']?.toString();

    if (name.isEmpty) {
      throw ParseError('Missing or empty "name" field', filePath: filePath);
    }
    if (description == null || description.isEmpty) {
      throw ParseError(
        'Missing or empty "description" field',
        filePath: filePath,
      );
    }

    // Optional field: slash (bool)
    // final slash = yaml['slash'] as bool? ?? false;

    return SkillInfo(
      name: name,
      description: description,
      directory: directory,
      content: body,
      // files list will be populated by the discoverer
    );
  }
}
