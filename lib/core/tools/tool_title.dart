String formatReadTitle(String path, Map<String, dynamic> input) {
  final offset = input['offset']?.toString() ?? '';
  final limit = input['limit']?.toString() ?? '';
  final parts = ['Read $path'];
  if (offset.isNotEmpty || limit.isNotEmpty) {
    parts.add('[offset=$offset, limit=$limit]');
  }
  return parts.join(' ');
}

String formatEditTitle(String path) => 'Edit $path';

String formatWriteTitle(String path) => 'Write $path';

String formatGlobTitle(String pattern) => 'Glob "$pattern"';

String formatGrepTitle(String pattern, String? root, int? matches) {
  final s = 'Grep "$pattern"';
  final parts = [
    if (root != null && root.isNotEmpty) 'in $root',
    if (matches != null) '($matches matches)',
  ];
  return '$s ${parts.join(' ')}'.trim();
}

String formatShellTitle(String? description) =>
    description?.isNotEmpty == true ? description! : 'Shell command';

String formatWebfetchTitle(String? url) =>
    url?.isNotEmpty == true ? 'WebFetch $url' : 'WebFetch';

String formatWebsearchTitle(String? provider, String? query) {
  if (query == null || query.isEmpty) return provider ?? 'WebSearch';
  return '${provider ?? "WebSearch"} "$query"';
}
