import 'package:url_launcher/url_launcher.dart';

/// Validates that a raw URL string has an http or https scheme.
bool isHttpHttpsUrl(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}

/// Outcome of an external link launch attempt.
enum LinkLaunchResult {
  /// Link was opened successfully in an external browser.
  opened,

  /// Scheme is not http/https (link was not attempted).
  invalidScheme,

  /// Launch was attempted but failed (platform error or false result).
  failed,
}

/// Attempts to open [href] in an external browser.
///
/// Returns [LinkLaunchResult.opened] on success, [LinkLaunchResult.invalidScheme]
/// if the URL is not http/https, or [LinkLaunchResult.failed] if the platform
/// launcher returns false or throws.
Future<LinkLaunchResult> launchExternalLink(
  String href, {
  Future<bool> Function(Uri uri, {LaunchMode mode})? launcher,
}) async {
  if (!isHttpHttpsUrl(href)) {
    return LinkLaunchResult.invalidScheme;
  }

  final uri = Uri.parse(href);
  final launch = launcher ?? launchUrl;
  try {
    final ok = await launch(uri, mode: LaunchMode.externalApplication);
    return ok ? LinkLaunchResult.opened : LinkLaunchResult.failed;
  } on Exception {
    return LinkLaunchResult.failed;
  }
}
