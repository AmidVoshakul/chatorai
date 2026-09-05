import 'dart:io';
import 'package:path/path.dart' as p;

/// Result of detecting whether the first CLI argument is a project directory
/// that should become the application's working directory.
class CwdOverride {
  const CwdOverride._(this.path, this.remainingArgs);

  /// The resolved absolute directory path, or `null` when no override applies.
  final String? path;

  /// Args with the leading directory path removed, safe to forward to
  /// [runCliIfRequested] or any other CLI dispatcher.
  final List<String> remainingArgs;

  /// `true` when a directory override was detected and should be applied.
  bool get hasOverride => path != null;
}

/// Detects whether the first element of [args] is an existing directory path.
///
/// Detection rules (all must match for an override to apply):
/// - [args] is not empty
/// - The first element does not start with `-` (not a flag)
/// - The path resolves to an existing directory on disk
///
/// When an override is detected, the path is stripped from the returned
/// [remainingArgs] and the resolved absolute path is exposed via [CwdOverride.path].
/// When no override applies, [remainingArgs] is always equal to [args] so the
/// caller can forward the original arguments without branching.
CwdOverride detectCwdOverride(List<String> args) {
  if (args.isEmpty) return CwdOverride._(null, args);
  final first = args.first;
  if (first.startsWith('-')) return CwdOverride._(null, args);
  final resolved = p.normalize(p.absolute(first));
  try {
    final dir = Directory(resolved);
    if (dir.existsSync()) {
      return CwdOverride._(resolved, args.skip(1).toList());
    }
  } catch (_) {}
  return CwdOverride._(null, args);
}
