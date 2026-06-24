import 'package:chatorai/core/tools/tool.dart';

/// Typed accessors for common tool metadata keys.
///
/// All tools return [ToolOutput] with a raw metadata map. These extensions
/// provide typed getters so callers don't need to hardcode string keys.
extension ToolOutputMetadata on ToolOutput {
  // ── Generic ────────────────────────────────────────────────────────────────

  /// True when the tool reported an error.
  bool get isError => metadata?['error'] == true;

  /// True when the tool result was aborted (e.g. user pressed stop).
  bool get isAborted => metadata?['aborted'] == true;

  // ── Bash ───────────────────────────────────────────────────────────────────

  int? get bashExitCode => metadata?['exit_code'] as int?;
  String? get bashBannedCommand => metadata?['banned'] as String?;

  // ── Read ───────────────────────────────────────────────────────────────────

  int? get readTotalLines => metadata?['lines'] as int?;
  int? get readOffset => metadata?['offset'] as int?;
  int? get readLimit => metadata?['limit'] as int?;
  bool get readIsBinary => metadata?['binary'] == true;
  int? get readBinarySizeBytes => metadata?['size'] as int?;
  String? get readFilePath => metadata?['file_path'] as String?;

  // ── Write ──────────────────────────────────────────────────────────────────

  String? get writePath => metadata?['path'] as String?;
  int? get writeBytes => metadata?['bytes'] as int?;

  // ── Edit ───────────────────────────────────────────────────────────────────

  String? get editPath => metadata?['path'] as String?;

  // ── Glob ───────────────────────────────────────────────────────────────────

  int? get globCount => metadata?['count'] as int?;

  // ── Grep ───────────────────────────────────────────────────────────────────

  int? get grepCount => metadata?['count'] as int?;

  // ── WebFetch ───────────────────────────────────────────────────────────────

  int? get fetchMaxChars => metadata?['max_chars'] as int?;
  bool get fetchTimedOut => metadata?['timeout'] == true;

  // ── WebSearch ──────────────────────────────────────────────────────────────

  int? get searchCount => metadata?['count'] as int?;
  String? get searchQuery => metadata?['query'] as String?;
  String? get searchProvider => metadata?['provider'] as String?;
  List<Map<String, dynamic>>? get searchResults =>
      (metadata?['results'] as List?)?.cast<Map<String, dynamic>>();

  // ── ApplyPatch ─────────────────────────────────────────────────────────────

  int? get patchOldCount => metadata?['old_count'] as int?;
  int? get patchNewCount => metadata?['new_count'] as int?;
  bool get patchContextMismatch => metadata?['context_mismatch'] == true;
  bool get patchBoundsError => metadata?['bounds_error'] == true;
  bool get patchWarning => metadata?['warning'] == true;

  // ── TodoWrite ──────────────────────────────────────────────────────────────

  int? get todoCount => metadata?['count'] as int?;
  String? get todoSessionId => metadata?['sessionId'] as String?;
  List<dynamic>? get todoList => metadata?['todos']?['todos'] as List<dynamic>?;

  // ── Question ───────────────────────────────────────────────────────────────

  List<dynamic>? get questionList => metadata?['questions'] as List<dynamic>?;
  bool get questionAwaitingResponse => metadata?['awaiting_response'] == true;

  // ── Task ───────────────────────────────────────────────────────────────────

  String? get taskSessionId => metadata?['session_id'] as String?;
  String? get taskSubagentType => metadata?['subagent_type'] as String?;
  String? get taskAgentName => metadata?['agent_name'] as String?;
  String? get taskDescription => metadata?['description'] as String?;
  String? get taskId => metadata?['task_id'] as String?;

  // ── Skill ──────────────────────────────────────────────────────────────────

  bool get skillLoaded => metadata?['skill'] == true;
  String? get skillName => metadata?['name'] as String?;

  // ── ToolOutputPersistence ──────────────────────────────────────────────────

  String? get persistenceToolCallId => metadata?['toolCallId'] as String?;
  String? get persistenceToolName => metadata?['toolName'] as String?;
  String? get persistenceSessionId => metadata?['sessionId'] as String?;
  int? get persistenceDurationMs => metadata?['durationMs'] as int?;
  String? get persistenceStatus => metadata?['status'] as String?;
}
