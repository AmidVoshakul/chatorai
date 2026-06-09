import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chatorai/shared/utils/image_utils.dart';

String getFileName(dynamic file) {
  String path;

  if (file is WebFile) {
    path = file.path;
  } else if (file is File) {
    path = file.path;
  } else {
    return 'unknown';
  }

  if (kIsWeb) {
    return path;
  }
  return path.split(Platform.pathSeparator).last;
}

String getFilePath(dynamic file) {
  if (file is WebFile) {
    return file.path;
  } else if (file is File) {
    return file.path;
  }
  return 'unknown';
}
