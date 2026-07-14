import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatorai/shared/utils/logger.dart';

final _logger = LogTags.ui;

Future<bool> requestCameraPermission() async {
  try {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.logInfo('[ImageUtils] Desktop platform, camera not available');
      return false;
    }

    _logger.logInfo('[ImageUtils] Requesting camera permission...');
    final status = await Permission.camera.request();

    if (status.isGranted) {
      _logger.logInfo('[ImageUtils] Camera permission: granted');
      return true;
    }

    if (status.isPermanentlyDenied) {
      _logger.logError('[ImageUtils] Camera permanently denied');
      await openAppSettings();
      return false;
    }

    _logger.logInfo('[ImageUtils] Camera permission: denied');
    return false;
  } catch (e) {
    _logger.logError('[ImageUtils] Error requesting camera permission: $e');
    return false;
  }
}

Future<bool> requestFilesPermission() async {
  try {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.logInfo('[ImageUtils] Desktop platform, no permission needed');
      return true;
    }

    if (Platform.isAndroid) {
      final sdkInt = await getAndroidSdkInt();
      if (sdkInt >= 30) {
        _logger.logInfo(
          '[ImageUtils] Android 11+, no permission needed for file picker',
        );
        return true;
      }

      _logger.logInfo(
        '[ImageUtils] Requesting storage permission (Android < 11)...',
      );
      final status = await Permission.storage.request();

      if (status.isGranted) {
        _logger.logInfo('[ImageUtils] Storage permission: granted');
        return true;
      }

      _logger.logInfo('[ImageUtils] Storage permission: denied');
      return false;
    }

    if (Platform.isIOS) {
      _logger.logInfo('[ImageUtils] Requesting photos permission (iOS)...');
      final status = await Permission.photos.request();

      if (status.isGranted) {
        _logger.logInfo('[ImageUtils] Photos permission: granted');
        return true;
      }

      _logger.logInfo('[ImageUtils] Photos permission: denied');
      return false;
    }

    return true;
  } catch (e) {
    _logger.logError('[ImageUtils] Error requesting file permission: $e');
    return false;
  }
}

Future<int> getAndroidSdkInt() async {
  try {
    if (!Platform.isAndroid) return 0;
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'SDK (\d+)').firstMatch(version);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    final versionMatch = RegExp(r'Android (\d+)').firstMatch(version);
    if (versionMatch != null) {
      final androidVersion = int.tryParse(versionMatch.group(1)!) ?? 0;
      return androidVersion + 19;
    }
    return 0;
  } catch (e) {
    return 0;
  }
}
