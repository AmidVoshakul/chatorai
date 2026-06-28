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

String toolTitle(String toolName, Map<String, dynamic> input) {
  final path = input['path'] as String? ?? input['filePath'] as String? ?? '';
  final url = input['url'] as String? ?? '';
  final pattern = input['pattern'] as String? ?? '';
  final args = _formatArgs(input);
  switch (toolName.toLowerCase()) {
    case 'read':
      return 'Read ${_breakablePath(path)}$args';
    case 'edit':
      return 'Edit ${_breakablePath(path)}$args';
    case 'write':
      return 'Write ${_breakablePath(path)}';
    case 'bash':
      final cmd = input['command'] as String? ?? '';
      return '\$ $cmd';
    case 'glob':
      return 'Glob "${_breakablePath(pattern)}"$args';
    case 'grep':
      return 'Grep "${_breakablePath(pattern)}"$args';
    case 'webfetch':
      return 'WebFetch ${_breakablePath(url)}';
    case 'websearch':
      final query = input['query'] as String? ?? '';
      return 'websearch "$query"$args';
    case 'task':
      final desc = input['description'] as String? ?? toolName;
      return desc;
    case 'todowrite':
      return 'Updating todos...';
    case 'apply_patch':
      return 'Patch$args';
    case 'question':
      return 'Asked questions';
    case 'skill':
      return 'Skill "${_breakablePath(path)}"';
    default:
      return toolName;
  }
}

String toolResultSummary(String toolName, String? result) {
  if (result == null || result.isEmpty) return '';
  final lines = result.split('\n').length;
  final truncated = result.length > 2000;
  if (toolName.toLowerCase() == 'bash') {
    return '$lines lines${truncated ? ' (truncated)' : ''}';
  }
  return '${result.length} chars${truncated ? ' (truncated)' : ''}';
}
