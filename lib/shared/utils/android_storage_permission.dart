import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Returns true when direct access to shared storage paths is available.
///
/// On Android this requires the "All files access" special permission
/// (MANAGE_EXTERNAL_STORAGE); on all other platforms access is unrestricted.
Future<bool> isAllFilesAccessGranted() async {
  if (!Platform.isAndroid) return true;
  try {
    return await Permission.manageExternalStorage.isGranted;
  } catch (_) {
    return false;
  }
}

/// Requests the "All files access" special permission on Android.
///
/// Returns true when access is granted or not needed. Never throws.
Future<bool> ensureAllFilesAccess() async {
  if (!Platform.isAndroid) return true;
  try {
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  } catch (_) {
    return false;
  }
}

/// Human-readable hint shown when a shared-storage path is not accessible.
String allFilesAccessHint() {
  return 'On Android, shared storage requires "All files access" permission. '
      'Enable it in system settings: Settings → Apps → ChatORAI → All files '
      'access, or accept the app prompt when shown.';
}
