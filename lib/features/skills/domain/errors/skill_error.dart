/// Structured errors for the skill subsystem.
///
/// Errors are structured to enable programmatic handling and logging.
sealed class SkillError {}

/// Parsing failed (YAML invalid, missing required fields, etc.).
class ParseError extends SkillError {
  final String message;
  final String? filePath;
  final int? line;

  ParseError(this.message, {this.filePath, this.line});

  @override
  String toString() =>
      'ParseError: $message'
      '${filePath != null ? ' in $filePath' : ''}'
      '${line != null ? ' at line $line' : ''}';
}

/// Skill with given name not found.
class NotFoundError extends SkillError {
  final String name;

  NotFoundError(this.name);

  @override
  String toString() => 'NotFoundError: skill "$name" not found';
}

/// Permission denied for agent accessing skill.
class PermissionDeniedError extends SkillError {
  final String skillName;
  final String agentName;

  PermissionDeniedError(this.skillName, this.agentName);

  @override
  String toString() =>
      'PermissionDenied: agent "$agentName" cannot access skill "$skillName"';
}

/// Source-level error (IO, HTTP, etc.).
class SourceError extends SkillError {
  final String source;
  final Exception exception;

  SourceError(this.source, this.exception);

  @override
  String toString() => 'SourceError ($source): ${exception.toString()}';
}

/// Validation error (schema mismatch).
class ValidationError extends SkillError {
  final String message;
  final Map<String, dynamic>? data;

  ValidationError(this.message, {this.data});

  @override
  String toString() => 'ValidationError: $message';
}
