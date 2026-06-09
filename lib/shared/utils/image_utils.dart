import 'dart:io';
import 'package:chatorai/shared/utils/image_picker_utils.dart';
import 'package:chatorai/shared/utils/image_format_utils.dart';

export 'package:chatorai/shared/utils/web_file.dart';
export 'package:chatorai/shared/utils/image_permissions.dart';
export 'package:chatorai/shared/utils/image_picker_utils.dart';
export 'package:chatorai/shared/utils/image_format_utils.dart';

class ImageUtils {
  static Future<dynamic> pickImageFromGallery() =>
      ImagePickerUtils.pickImageFromGallery();

  static Future<File?> takePhotoWithCamera() =>
      ImagePickerUtils.takePhotoWithCamera();

  static Future<dynamic> pickFile() => ImagePickerUtils.pickFile();

  static Future<String?> fileToBase64(dynamic file) =>
      ImageFormatUtils.fileToBase64(file);

  static String getMimeType(dynamic fileOrPath) =>
      ImageFormatUtils.getMimeType(fileOrPath);

  static bool isImageFile(dynamic fileOrPath) =>
      ImageFormatUtils.isImageFile(fileOrPath);
}
