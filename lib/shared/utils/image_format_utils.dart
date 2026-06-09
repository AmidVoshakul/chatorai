import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/utils/web_file.dart';

final _logger = LogTags.ui;

class ImageFormatUtils {
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
      _logger.logInfo(
        '[ImageUtils] Conversion successful, length: ${base64String.length}',
      );
      return base64String;
    } catch (e) {
      _logger.logError('[ImageUtils] Error converting file to base64: $e');
      return null;
    }
  }

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

    final parts = filePath.split('.');
    if (parts.length < 2) {
      return 'application/octet-stream';
    }

    final extension = parts.last.toLowerCase();
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
      case 'svg':
        return 'image/svg+xml';
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
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';
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
    return [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'svg',
    ].contains(extension);
  }
}
