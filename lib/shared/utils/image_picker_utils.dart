import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/web_file.dart';
import 'package:chatorai/shared/utils/image_permissions.dart';

final _logger = LogTags.ui;

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<dynamic> pickImageFromGallery() async {
    try {
      if (!kIsWeb) {
        final hasPermission = await requestFilesPermission();
        if (!hasPermission) {
          _logger.logWarning('[ImageUtils] No permission to access gallery');
          return null;
        }
      }

      _logger.logInfo('[ImageUtils] Picking image from gallery...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          try {
            final bytes = await pickedFile.readAsBytes();
            _logger.logInfo(
              '[ImageUtils] Image picked from web: ${pickedFile.name}, size: ${bytes.length}',
            );
            return WebFile(bytes, pickedFile.name);
          } catch (e) {
            _logger.logError('[ImageUtils] Error reading web image bytes: $e');
            return null;
          }
        }

        _logger.logInfo('[ImageUtils] Image picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }

      _logger.logInfo('[ImageUtils] No image selected');
      return null;
    } catch (e) {
      _logger.logError('[ImageUtils] Error picking image from gallery: $e');
      return null;
    }
  }

  static Future<File?> takePhotoWithCamera() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        _logger.logWarning(
          '[ImageUtils] Camera not available on this platform',
        );
        return null;
      }

      _logger.logInfo('[ImageUtils] Taking photo with camera...');

      if (!await requestCameraPermission()) {
        _logger.logError('[ImageUtils] Camera permission denied');
        return null;
      }

      _logger.logInfo('[ImageUtils] Opening camera with image_picker...');
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo == null) {
        _logger.logInfo('[ImageUtils] User canceled camera');
        return null;
      }

      _logger.logInfo('[ImageUtils] Photo taken: ${photo.path}');
      return File(photo.path);
    } catch (e) {
      _logger.logError('[ImageUtils] Camera error: $e');
      return null;
    }
  }

  static Future<dynamic> pickFile() async {
    try {
      if (!kIsWeb) {
        final hasPermission = await requestFilesPermission();
        if (!hasPermission) {
          _logger.logWarning('[ImageUtils] No permission to access files');
          return null;
        }
      }

      _logger.logInfo('[ImageUtils] Picking file...');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _logger.logInfo('[ImageUtils] No file selected');
        return null;
      }

      final platformFile = result.files.first;

      if (kIsWeb) {
        if (platformFile.bytes != null) {
          _logger.logInfo(
            '[ImageUtils] File picked from web (bytes), size: ${platformFile.bytes!.length}, name: ${platformFile.name}',
          );
          return WebFile(platformFile.bytes!, platformFile.name);
        } else {
          _logger.logError('[ImageUtils] Web file has no bytes available');
          return null;
        }
      } else {
        if (platformFile.path != null) {
          _logger.logInfo('[ImageUtils] File picked: ${platformFile.path}');
          return File(platformFile.path!);
        } else if (platformFile.bytes != null) {
          _logger.logWarning(
            '[ImageUtils] Native file has no path but has bytes, using WebFile',
          );
          return WebFile(platformFile.bytes!, platformFile.name);
        }
      }

      return null;
    } catch (e) {
      _logger.logError('[ImageUtils] Error picking file: $e');
      return null;
    }
  }
}
