String formatTokenCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

String tokenDisplay(int cumulativeTokens, int? contextLength) {
  final count = formatTokenCount(cumulativeTokens);
  if (contextLength != null && contextLength > 0) {
    final pct = (cumulativeTokens / contextLength * 100).toStringAsFixed(0);
    return '$count ($pct%)';
  }
  return count;
}

String formatDurationMs(int? ms) {
  if (ms == null || ms <= 0) return '0s';
  final totalSeconds = ms ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  return '${seconds}s';
}

String formatDuration(Duration d) {
  final total = d.inSeconds;
  if (total < 60) return '${total}s';
  final minutes = total ~/ 60;
  final seconds = total % 60;
  if (seconds == 0) return '${minutes}m';
  return '${minutes}m ${seconds}s';
}

String bashPreview(String text) {
  const maxLines = 10;
  const maxChars = 500;
  if (text.isEmpty) return text;
  final lines = text.split('\n');
  if (lines.length <= maxLines && text.length <= maxChars) return text;
  String truncated;
  if (lines.length > maxLines) {
    truncated = lines.take(maxLines).join('\n');
  } else {
    truncated = text;
  }
  if (truncated.length > maxChars) {
    truncated = truncated.substring(0, maxChars);
  }
  return truncated;
}
