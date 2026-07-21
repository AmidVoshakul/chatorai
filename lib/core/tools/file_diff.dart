class FileDiff {
  final String file;
  final String patch;
  final int additions;
  final int deletions;

  const FileDiff({
    required this.file,
    required this.patch,
    required this.additions,
    required this.deletions,
  });
}
