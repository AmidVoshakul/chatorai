String _formatArgs(Map<String, dynamic> input, {int maxArgs = 3}) {
  final omit = {
    'path',
    'filePath',
    'command',
    'url',
    'pattern',
    'query',
    'description',
  };
  final args = <String>[];
  for (final entry in input.entries) {
    if (omit.contains(entry.key)) continue;
    if (entry.value is Map || entry.value is List) continue;
    if (args.length >= maxArgs) break;
    final val = entry.value.toString();
    final display = val.length > 30 ? '${val.substring(0, 27)}...' : val;
    args.add('${entry.key}=$display');
  }
  return args.isEmpty ? '' : ' [${args.join(', ')}]';
}

String toolTitle(String toolName, Map<String, dynamic> input) {
  final path = input['path'] as String? ?? input['filePath'] as String? ?? '';
  final args = _formatArgs(input);
  switch (toolName.toLowerCase()) {
    case 'read':
      return 'Read $path$args';
    case 'edit':
      return 'Edit $path$args';
    case 'write':
      return 'Write $path';
    case 'bash':
      final cmd = input['command'] as String? ?? '';
      return '\$${cmd.length > 60 ? ' ${cmd.substring(0, 57)}...' : ' $cmd'}';
    case 'glob':
      final pattern = input['pattern'] as String? ?? '';
      return 'Glob "$pattern"$args';
    case 'grep':
      final pattern = input['pattern'] as String? ?? '';
      return 'Grep "$pattern"$args';
    case 'webfetch':
      final url = input['url'] as String? ?? '';
      return 'WebFetch $url';
    case 'websearch':
      final query = input['query'] as String? ?? '';
      final display = query.length > 40
          ? '${query.substring(0, 37)}...'
          : query;
      return 'Search "$display"$args';
    case 'task':
      final desc = input['description'] as String? ?? toolName;
      return desc.length > 60 ? '${desc.substring(0, 57)}...' : desc;
    case 'todowrite':
      return 'Updating todos...';
    case 'apply_patch':
      return 'Patch$args';
    case 'question':
      return 'Asked questions';
    case 'skill':
      return 'Skill "$path';
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
