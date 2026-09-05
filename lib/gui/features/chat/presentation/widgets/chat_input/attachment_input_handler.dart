import 'dart:async';
import 'dart:io';

import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/file_helpers.dart';
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/utils/image_utils.dart';
import 'package:chatorai/shared/utils/xdg_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

mixin AttachmentInputHandler<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool Function(String)? get checkModelSupportsImages;

  Future<void> handleCamera() async {
    final localizations = AppLocalizations.of(context)!;
    if (checkModelSupportsImages != null) {
      final modelId = ref.read(modelProvider).selectedModelId;
      final supportsImages = checkModelSupportsImages!(modelId);
      if (!supportsImages) {
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.modelDoesNotSupportImages(modelId),
            icon: Icons.image_not_supported,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
    try {
      final file = await ImageUtils.takePhotoWithCamera();
      if (file == null) return;
      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;
      final imageType = ImageUtils.getMimeType(file);
      final fileName = getFileName(file);
      final filePath = getFilePath(file);
      ref
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: filePath,
            name: fileName,
            imageType: imageType,
            base64Data: base64Data,
          );
    } catch (e) {
      // handled by ImageUtils
    }
  }

  Future<void> handleImage() async {
    final localizations = AppLocalizations.of(context)!;
    if (checkModelSupportsImages != null) {
      final modelId = ref.read(modelProvider).selectedModelId;
      final supportsImages = checkModelSupportsImages!(modelId);
      if (!supportsImages) {
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.modelDoesNotSupportImages(modelId),
            icon: Icons.image_not_supported,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
    try {
      final file = await ImageUtils.pickImageFromGallery();
      if (file == null) return;
      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;
      final imageType = ImageUtils.getMimeType(file);
      final fileName = getFileName(file);
      final filePath = getFilePath(file);
      ref
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: filePath,
            name: fileName,
            imageType: imageType,
            base64Data: base64Data,
          );
    } catch (e) {
      // handled
    }
  }

  Future<void> handleFile() async {
    try {
      final file = await ImageUtils.pickFile();
      if (file == null) return;
      final fileName = getFileName(file);

      if (ImageUtils.isImageFile(file)) {
        // Image file: base64 encode and store as image attachment
        final base64Data = await ImageUtils.fileToBase64(file);
        if (base64Data == null) return;
        final imageType = ImageUtils.getMimeType(file);
        ref
            .read(chatInputProvider.notifier)
            .setAttachedFile(
              path: getFilePath(file),
              name: fileName,
              imageType: imageType,
              base64Data: base64Data,
            );
      } else {
        // Document file: copy to temp directory, store path only
        final tempPath = await _saveDocumentToTempDir(file);
        ref
            .read(chatInputProvider.notifier)
            .setAttachedFile(path: tempPath, name: fileName);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Failed to attach file: $e',
          icon: Icons.error,
        );
      }
    }
  }

  Future<String> _saveDocumentToTempDir(File file) async {
    final dir = await XdgPaths.dataSubdirAsync('attachments');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(dir.path, '${timestamp}_${p.basename(file.path)}');
    await file.copy(destPath);
    return destPath;
  }

  void clearAttachedFile() {
    if (!mounted) return;
    final notifier = ref.read(chatInputProvider.notifier);
    notifier.clearAttachedFile();
  }
}

class AttachmentCleanup {
  Timer? _timer;
  static const _maxAge = Duration(hours: 24);
  static const _interval = Duration(hours: 1);
  static final _instance = AttachmentCleanup._();

  factory AttachmentCleanup() => _instance;
  AttachmentCleanup._();

  Future<Directory> _dir() async => XdgPaths.dataSubdirAsync('attachments');

  void initialize() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => unawaited(_cleanup()));
    unawaited(_cleanup());
  }

  Future<void> _cleanup() async {
    try {
      final dir = await _dir();
      final cutoff = DateTime.now().subtract(_maxAge);
      await for (final entity in dir.list()) {
        if (entity is File && entity.lastModifiedSync().isBefore(cutoff)) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
