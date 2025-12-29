import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatorai/utils/logger.dart';

final _logger = LogTags.ui;

/// Wrapper class for web files that don't have a path
class WebFile {
  final Uint8List bytes;
  final String name;
  
  WebFile(this.bytes, this.name);
  
  String get path => name;
}

/// Утилита для работы с изображениями и камерой
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Запрос разрешения на камеру
  static Future<bool> _requestCameraPermission() async {
    try {
      // Camera permission is not needed on web
      if (kIsWeb) {
        _logger.logInfo('[ImageUtils] Camera permission not needed on web');
        return true;
      }
      
      // Desktop platforms don't use camera through this app
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

  /// Запрос разрешения на чтение файлов
  /// - Web: No permissions needed
  /// - Desktop (Linux/Windows/macOS): No permissions needed
  /// - Android 11+ (API 30+): Uses SAF, no permissions needed
  /// - Android 10 and below: Needs storage permission
  /// - iOS: Needs photos permission for gallery
  static Future<bool> _requestFilesPermission() async {
    try {
      // Web and Desktop don't need permissions
      if (kIsWeb) {
        _logger.logInfo('[ImageUtils] File permission not needed on web');
        return true;
      }
      
      if (!Platform.isAndroid && !Platform.isIOS) {
        // Desktop platform (Linux, Windows, macOS)
        _logger.logInfo('[ImageUtils] Desktop platform, no permission needed');
        return true;
      }
      
      if (Platform.isAndroid) {
        // Android 11+ (API 30+) uses SAF, no permission needed
        final sdkInt = await _getAndroidSdkInt();
        if (sdkInt >= 30) {
          _logger.logInfo('[ImageUtils] Android 11+, no permission needed for file picker');
          return true;
        }
        
        // Android 10 and below - request storage permission
        _logger.logInfo('[ImageUtils] Requesting storage permission (Android < 11)...');
        final status = await Permission.storage.request();
        
        if (status.isGranted) {
          _logger.logInfo('[ImageUtils] Storage permission: granted');
          return true;
        }
        
        _logger.logInfo('[ImageUtils] Storage permission: denied');
        return false;
      }
      
      if (Platform.isIOS) {
        // iOS - request photos permission for gallery
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

  /// Get Android SDK version
  static Future<int> _getAndroidSdkInt() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return 0;
      final version = Platform.operatingSystemVersion;
      // Extract SDK version from string like "Android 13 (SDK 33)"
      final match = RegExp(r'SDK (\d+)').firstMatch(version);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 0;
      }
      // Fallback: extract Android version and map to SDK
      final versionMatch = RegExp(r'Android (\d+)').firstMatch(version);
      if (versionMatch != null) {
        final androidVersion = int.tryParse(versionMatch.group(1)!) ?? 0;
        // Map Android version to SDK version
        // Android 10 = SDK 29, Android 11 = SDK 30, etc.
        return androidVersion + 19;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Выбрать изображение из галереи
  /// Returns File for native platforms, WebFile for web
  static Future<dynamic> pickImageFromGallery() async {
    try {
      // Request permissions first (not needed on web, desktop, and Android 11+)
      if (!kIsWeb) {
        final hasPermission = await _requestFilesPermission();
        if (!hasPermission) {
          _logger.logWarning('[ImageUtils] No permission to access gallery');
          return null;
        }
      }
      
      _logger.logInfo('[ImageUtils] Picking image from gallery...');
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        // Handle web platform
        if (kIsWeb) {
          try {
            final bytes = await pickedFile.readAsBytes();
            _logger.logInfo('[ImageUtils] Image picked from web: ${pickedFile.name}, size: ${bytes.length}');
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

  /// Сделать фото камерой
  /// Returns File for mobile platforms, null for web and desktop
  static Future<File?> takePhotoWithCamera() async {
    try {
      // Camera not available on web or desktop
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        _logger.logWarning('[ImageUtils] Camera not available on this platform');
        return null;
      }
      
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

  /// Выбрать файл (изображение или любой другой файл)
  /// Returns File for native platforms, WebFile for web
  static Future<dynamic> pickFile() async {
    try {
      // Request permissions first (not needed on web, desktop, and Android 11+)
      if (!kIsWeb) {
        final hasPermission = await _requestFilesPermission();
        if (!hasPermission) {
          _logger.logWarning('[ImageUtils] No permission to access files');
          return null;
        }
      }
      
      _logger.logInfo('[ImageUtils] Picking file...');
      
      // Use file_picker to pick any file type
      // Note: withData: true loads file into memory - be careful with large files
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _logger.logInfo('[ImageUtils] No file selected');
        return null;
      }

      final platformFile = result.files.first;
      
      // On web, always use bytes (path is not available)
      if (kIsWeb) {
        // On web, bytes should always be available with withData: true
        if (platformFile.bytes != null) {
          _logger.logInfo('[ImageUtils] File picked from web (bytes), size: ${platformFile.bytes!.length}, name: ${platformFile.name}');
          return WebFile(platformFile.bytes!, platformFile.name);
        } else {
          _logger.logError('[ImageUtils] Web file has no bytes available');
          return null;
        }
      } else {
        // On native platforms, use path
        if (platformFile.path != null) {
          _logger.logInfo('[ImageUtils] File picked: ${platformFile.path}');
          return File(platformFile.path!);
        } else if (platformFile.bytes != null) {
          // Fallback: if path is null but bytes exist, create WebFile
          _logger.logWarning('[ImageUtils] Native file has no path but has bytes, using WebFile');
          return WebFile(platformFile.bytes!, platformFile.name);
        }
      }
      
      return null;
    } catch (e) {
      _logger.logError('[ImageUtils] Error picking file: $e');
      return null;
    }
  }

  /// Конвертировать файл в base64
  /// Accepts File (native) or WebFile (web)
  static Future<String?> fileToBase64(dynamic file) async {
    try {
      String? path;
      Uint8List bytes;
      
      if (file is WebFile) {
        path = file.path;
        bytes = file.bytes;
      } else if (file is File) {
        path = file.path;
        bytes = await file.readAsBytes();
      } else {
        _logger.logError('[ImageUtils] Unknown file type: ${file.runtimeType}');
        return null;
      }
      
      _logger.logInfo('[ImageUtils] Converting file to base64: $path');
      final base64String = base64Encode(bytes);
      _logger.logInfo('[ImageUtils] Conversion successful, length: ${base64String.length}');
      return base64String;
    } catch (e) {
      _logger.logError('[ImageUtils] Error converting file to base64: $e');
      return null;
    }
  }

  /// Получить MIME тип файла по расширению
  /// Accepts String path, File, or WebFile
  /// 
  /// ⚠️  Note: This is based on file extension, not content
  /// For security, the backend should verify the actual file content
  static String getMimeType(dynamic fileOrPath) {
    String filePath;
    
    if (fileOrPath is String) {
      filePath = fileOrPath;
    } else if (fileOrPath is WebFile) {
      filePath = fileOrPath.path;
    } else if (fileOrPath is File) {
      filePath = fileOrPath.path;
    } else {
      return 'application/octet-stream';
    }
    
    // Extract extension from file path
    final parts = filePath.split('.');
    if (parts.length < 2) {
      // No extension found
      return 'application/octet-stream';
    }
    
    final extension = parts.last.toLowerCase();
    switch (extension) {
      // Images
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
      case 'svg':
        return 'image/svg+xml';
      
      // Text files
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'rtf':
        return 'text/rtf';
      case 'csv':
        return 'text/csv';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'xml':
        return 'text/xml';
      case 'json':
        return 'application/json';
      case 'yaml':
      case 'yml':
        return 'application/yaml';
      
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      
      // Archives
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';
      
      // Code files
      case 'dart':
        return 'text/dart';
      case 'js':
        return 'text/javascript';
      case 'ts':
        return 'text/typescript';
      case 'py':
        return 'text/x-python';
      case 'java':
        return 'text/x-java';
      case 'cpp':
      case 'c':
      case 'h':
        return 'text/x-c';
      case 'cs':
        return 'text/x-csharp';
      case 'go':
        return 'text/x-go';
      case 'rs':
        return 'text/x-rust';
      case 'php':
        return 'text/x-php';
      case 'rb':
        return 'text/x-ruby';
      case 'swift':
        return 'text/x-swift';
      
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';
      
      // Video
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      
      default:
        return 'application/octet-stream';
    }
  }

  /// Проверить, является ли файл изображением
  /// Accepts String path, File, or WebFile
  static bool isImageFile(dynamic fileOrPath) {
    String filePath;
    
    if (fileOrPath is String) {
      filePath = fileOrPath;
    } else if (fileOrPath is WebFile) {
      filePath = fileOrPath.path;
    } else if (fileOrPath is File) {
      filePath = fileOrPath.path;
    } else {
      return false;
    }
    
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'svg'].contains(extension);
  }
}
