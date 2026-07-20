String _breakablePath(String path) {
  // Insert zero-width space after '/' to allow line breaking at slashes
  return path.replaceAll('/', '/\u200B');
}

String _formatArgs(Map<String, dynamic> input, {int maxArgs = 3}) {
  final omit = {
    'path',
    'filePath',
    'file_path',
    'command',
    'url',
    'pattern',
    'query',
    'description',
    'old_string',
    'new_string',
    'patch',
  };
  final args = <String>[];
  for (final entry in input.entries) {
    if (omit.contains(entry.key)) continue;
    if (entry.value is Map || entry.value is List) continue;
    if (args.length >= maxArgs) break;
    final val = entry.value.toString();
    args.add('${entry.key}=$val');
  }
  return args.isEmpty ? '' : ' [${args.join(', ')}]';
}

String _toolTitleForRead(Map<String, dynamic> input) {
  final path =
      input['path'] as String? ??
      input['filePath'] as String? ??
      input['file_path'] as String? ??
      '';
  return 'Read ${_breakablePath(path)}${_formatArgs(input)}';
}

String _toolTitleForEdit(Map<String, dynamic> input) {
  final path =
      input['path'] as String? ??
      input['filePath'] as String? ??
      input['file_path'] as String? ??
      '';
  return 'Edit ${_breakablePath(path)}${_formatArgs(input)}';
}

String _toolTitleForWrite(Map<String, dynamic> input) {
  final path =
      input['path'] as String? ??
      input['filePath'] as String? ??
      input['file_path'] as String? ??
      '';
  return 'Write ${_breakablePath(path)}${_formatArgs(input)}';
}

String _toolTitleForBash(Map<String, dynamic> input) {
  final command = input['command'] as String? ?? '';
  if (command.isNotEmpty) return 'bash ${_breakablePath(command)}';
  final desc = input['description'] as String? ?? '';
  return desc.isNotEmpty ? desc : 'bash';
}

String _toolTitleForGlob(Map<String, dynamic> input) {
  final pattern = input['pattern'] as String? ?? '';
  return 'Glob "${_breakablePath(pattern)}"${_formatArgs(input)}';
}

String _toolTitleForGrep(Map<String, dynamic> input) {
  final pattern = input['pattern'] as String? ?? '';
  return 'Grep "${_breakablePath(pattern)}"${_formatArgs(input)}';
}

String _toolTitleForWebfetch(Map<String, dynamic> input) {
  final url = input['url'] as String? ?? '';
  return 'WebFetch ${_breakablePath(url)}';
}

String _toolTitleForWebsearch(Map<String, dynamic> input) {
  final query = input['query'] as String? ?? '';
  return 'websearch "$query"${_formatArgs(input)}';
}

String _toolTitleForTask(Map<String, dynamic> input) {
  final desc = input['description'] as String? ?? 'task';
  return desc;
}

String _toolTitleForTodowrite(Map<String, dynamic> input) {
  return 'Updating todos...';
}

String _toolTitleForApplyPatch(Map<String, dynamic> input) {
  return 'Patch${_formatArgs(input)}';
}

String _toolTitleForQuestion(Map<String, dynamic> input) {
  return 'Asked questions';
}

String _toolTitleForSkill(Map<String, dynamic> input) {
  final skillName = input['name'] as String? ?? '';
  return 'Skill "$skillName"';
}

const _toolNames = <String, String Function(Map<String, dynamic>)>{
  'read': _toolTitleForRead,
  'edit': _toolTitleForEdit,
  'write': _toolTitleForWrite,
  'bash': _toolTitleForBash,
  'glob': _toolTitleForGlob,
  'grep': _toolTitleForGrep,
  'webfetch': _toolTitleForWebfetch,
  'websearch': _toolTitleForWebsearch,
  'task': _toolTitleForTask,
  'todowrite': _toolTitleForTodowrite,
  'apply_patch': _toolTitleForApplyPatch,
  'question': _toolTitleForQuestion,
  'skill': _toolTitleForSkill,
};

String toolTitle(String toolName, Map<String, dynamic> input) {
  final formatter = _toolNames[toolName.toLowerCase()];
  if (formatter != null) return formatter(input);

  final path =
      input['path'] as String? ??
      input['filePath'] as String? ??
      input['file_path'] as String? ??
      '';
  final args = _formatArgs(input);
  if (path.isNotEmpty) return '$toolName ${_breakablePath(path)}$args';
  return args.isNotEmpty ? '$toolName$args' : toolName;
}
