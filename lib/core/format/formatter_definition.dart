/// Context passed to a formatter's [enabled] check.
class FormatContext {
  final String filePath;
  final String projectRoot;
  final Map<String, dynamic> config;

  const FormatContext({
    required this.filePath,
    required this.projectRoot,
    this.config = const {},
  });
}

class FormatterDefinition {
  final String name;
  final List<String> extensions;
  final Map<String, String>? environment;
  final Future<List<String>?> Function(FormatContext context) enabled;

  const FormatterDefinition({
    required this.name,
    required this.extensions,
    this.environment,
    required this.enabled,
  });
}

/// User-provided config override for a single formatter.
class FormatterEntry {
  final bool? disabled;
  final List<String>? command;
  final Map<String, String>? environment;
  final List<String>? extensions;

  const FormatterEntry({
    this.disabled,
    this.command,
    this.environment,
    this.extensions,
  });

  factory FormatterEntry.fromJson(Map<String, dynamic> json) {
    return FormatterEntry(
      disabled: json['disabled'] as bool?,
      command: (json['command'] as List<dynamic>?)?.cast<String>(),
      environment: (json['environment'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      extensions: (json['extensions'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (disabled != null) 'disabled': disabled,
    if (command != null) 'command': command,
    if (environment != null) 'environment': environment,
    if (extensions != null) 'extensions': extensions,
  };
}
