import 'package:path/path.dart' as p;

/// Checks if a path is hard-denied (critical system paths that should never be accessible).
///
/// This is a security-critical function that prevents access to critical system
/// paths like /etc/shadow, SSH keys, Windows system directories, etc.
/// Used by both [PathResolver] and [path_sandbox] for consistent security checks.
bool isHardDeniedPath(String userPath, String workspacePath) {
  final normalized = p.normalize(
    userPath.startsWith('~')
        ? p.join(
            workspacePath,
            userPath.length > 2 ? userPath.substring(2) : '.',
          )
        : userPath,
  );
  final absolute = p.isAbsolute(normalized)
      ? normalized
      : p.join(workspacePath, normalized);
  final normalizedAbsolute = p.normalize(absolute).replaceAll('\\', '/');
  final lower = normalizedAbsolute.toLowerCase();
  final parts = lower.split('/').where((p) => p.isNotEmpty).toList();

  // /etc/shadow (exact, including nested) — critical unix secret.
  if (lower == '/etc/shadow' || lower.startsWith('/etc/shadow/')) return true;

  // Windows system directories (both separators).
  if (lower.contains('/windows/system32')) return true;

  // Common credential/secret stores — readable only if the user explicitly
  // grants external_directory; blocked by default to avoid silent leakage.
  if (lower.contains('/.aws/')) return true;
  if (lower.contains('/.git-credentials')) return true;
  if (lower.contains('/.netrc')) return true;
  if (lower.contains('/.gnupg/')) return true;
  if (lower.contains('/.kube/')) return true;
  if (lower.contains('/.docker/config.json')) return true;
  if (lower.contains('/.config/gcloud/')) return true;

  // SSH private keys — component-based matching avoids false positives like
  // "my_authorized_keys_backup.txt" and false negatives on Windows backslash
  // paths (paths are already normalized to '/' above).
  if (parts.contains('.ssh')) return true;
  if (parts.contains('authorized_keys')) return true;
  if (parts.any(
    (part) =>
        part == 'id_rsa' ||
        part == 'id_ed25519' ||
        part == 'id_ecdsa' ||
        part == 'id_dsa' ||
        part.endsWith('_rsa') ||
        part.endsWith('_ed25519') ||
        part.endsWith('_ecdsa') ||
        part.endsWith('_dsa') ||
        part == 'ssh_key',
  )) {
    return true;
  }

  return false;
}
