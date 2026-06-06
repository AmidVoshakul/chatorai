String toolTitle(String toolName, Map<String, dynamic> input) {
  final path = input['path'] as String? ?? input['filePath'] as String? ?? '';
  switch (toolName.toLowerCase()) {
    case 'read':
      return 'Read $path';
    case 'edit':
      return 'Edit $path';
    case 'write':
      return 'Write $path';
    case 'bash':
      final cmd = input['command'] as String? ?? '';
      return cmd.length > 50 ? '${cmd.substring(0, 47)}...' : cmd;
    case 'glob':
      final pattern = input['pattern'] as String? ?? '';
      return 'Glob "$pattern"';
    case 'grep':
      final pattern = input['pattern'] as String? ?? '';
      return 'Grep "$pattern"';
    case 'webfetch':
      final url = input['url'] as String? ?? '';
      return 'WebFetch $url';
    case 'websearch':
      final query = input['query'] as String? ?? '';
      return query.length > 50
          ? 'Search "${query.substring(0, 47)}..."'
          : 'Search "$query"';
    default:
      return toolName;
  }
}
