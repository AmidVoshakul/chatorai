import 'package:chatorai/core/commands/skill_template_renderer.dart';
import 'package:chatorai/core/skills/skill_info.dart';

/// Resolves a skill invocation to the content that should be inserted into
/// the conversation. Shared by GUI and TUI so both render identically.
class SkillCommandResolver {
  const SkillCommandResolver._();

  /// Returns rendered skill content for [skill] with [arguments].
  ///
  /// When [arguments] is empty, returns a header plus raw skill content
  /// (inserted without AI). Otherwise renders the template with arguments.
  static String resolve(SkillInfo skill, String arguments) {
    final trimmed = arguments.trim();
    if (trimmed.isEmpty) {
      return '**Loaded skill: ${skill.name}**\n\n${skill.content}';
    }
    return SkillTemplateRenderer.render(skill.content, trimmed);
  }

  /// Convenience wrapper around [SkillTemplateRenderer.render] for callers
  /// that already have raw content and arguments.
  static String render(String content, String arguments) =>
      SkillTemplateRenderer.render(content, arguments);
}
