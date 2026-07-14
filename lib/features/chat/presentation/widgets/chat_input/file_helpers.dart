import 'dart:io' show Platform, File;

String getFileName(dynamic file) {
  String path;

  if (file is File) {
    path = file.path;
  } else {
    return 'unknown';
  }

  return path.split(Platform.pathSeparator).last;
}

String getFilePath(dynamic file) {
  if (file is File) {
    return file.path;
  }
  return 'unknown';
}
