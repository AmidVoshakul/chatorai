import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';

final _logger = LogTags.ui;

/// Утилита для работы с изображениями и камерой
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

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

  /// Сделать фото камерой
  static Future<File?> takePhotoWithCamera() async {
    try {
      _logger.logInfo('[ImageUtils] Taking photo with camera...');
      
      // Получаем список камер
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _logger.logError('[ImageUtils] No cameras available');
        return null;
      }

      // Запускаем камеру
      final firstCamera = cameras.first;
      final CameraController controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      await controller.initialize();
      if (!controller.value.isInitialized) {
        _logger.logError('[ImageUtils] Camera controller not initialized');
        return null;
      }

      // Делаем снимок
      final XFile picture = await controller.takePicture();
      await controller.dispose();
      
      _logger.logInfo('[ImageUtils] Photo taken: ${picture.path}');
      return File(picture.path);
    } catch (e) {
      _logger.logError('[ImageUtils] Error taking photo: $e');
      return null;
    }
  }

  /// Выбрать файл (изображение или другой файл)
  static Future<File?> pickFile() async {
    try {
      _logger.logInfo('[ImageUtils] Picking file...');
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        _logger.logInfo('[ImageUtils] File picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }
      
      _logger.logInfo('[ImageUtils] No file selected');
      return null;
    } catch (e) {
      _logger.logError('[ImageUtils] Error picking file: $e');
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
