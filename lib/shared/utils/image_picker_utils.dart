import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/image_permissions.dart';

final _logger = LogTags.ui;

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImageFromGallery() async {
    try {
      final hasPermission = await requestFilesPermission();
      if (!hasPermission) {
        _logger.logWarning('[ImageUtils] No permission to access gallery');
        return null;
      }

      _logger.logInfo('[ImageUtils] Picking image from gallery...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
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
      if (!Platform.isAndroid && !Platform.isIOS) {
        _logger.logWarning(
          '[ImageUtils] Camera not available on desktop platform',
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

  static Future<File?> pickFile() async {
    try {
      final hasPermission = await requestFilesPermission();
      if (!hasPermission) {
        _logger.logWarning('[ImageUtils] No permission to access files');
        return null;
      }

      _logger.logInfo('[ImageUtils] Picking file...');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        _logger.logInfo('[ImageUtils] No file selected');
        return null;
      }

      final platformFile = result.files.first;

      if (platformFile.path != null) {
        _logger.logInfo('[ImageUtils] File picked: ${platformFile.path}');
        return File(platformFile.path!);
      }

      return null;
    } catch (e) {
      _logger.logError('[ImageUtils] Error picking file: $e');
      return null;
    }
  }
}
