import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.ui;

/// Утилита для работы с изображениями и камерой
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Запрос разрешения на камеру
  static Future<bool> _requestCameraPermission() async {
    try {
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

  /// Выбрать изображение из галереи
  static Future<File?> pickImageFromGallery() async {
    try {
      _logger.logInfo('[ImageUtils] Picking image from gallery...');
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
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

  /// Сделать фото камерой (ИСПРАВЛЕННАЯ ВЕРСИЯ)
  static Future<File?> takePhotoWithCamera() async {
    try {
      _logger.logInfo('[ImageUtils] Taking photo with camera...');
      
      // 1. Запрашиваем разрешение
      if (!await _requestCameraPermission()) {
        _logger.logError('[ImageUtils] Camera permission denied');
        return null;
      }

      // 2. Открываем камеру через image_picker (без camera package!)
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



  /// Конвертировать файл в base64
  static Future<String?> fileToBase64(File file) async {
    try {
      _logger.logInfo('[ImageUtils] Converting file to base64: ${file.path}');
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      _logger.logInfo('[ImageUtils] Conversion successful, length: ${base64String.length}');
      return base64String;
    } catch (e) {
      _logger.logError('[ImageUtils] Error converting file to base64: $e');
      return null;
    }
  }

  /// Получить MIME тип файла по расширению
  static String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  /// Проверить, является ли файл изображением
  static bool isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension);
  }
}
