import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/image_utils.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/file_helpers.dart';

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
    final localizations = AppLocalizations.of(context)!;
    if (checkModelSupportsImages != null) {
      final modelId = ref.read(modelProvider).selectedModelId;
      final supportsImages = checkModelSupportsImages!(modelId);
      if (!supportsImages) {
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.modelDoesNotSupportFiles(modelId),
            icon: Icons.attach_file,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
    try {
      final file = await ImageUtils.pickFile();
      if (file == null) return;
      final fileName = getFileName(file);
      final fileType = ImageUtils.getMimeType(file);
      final filePath = getFilePath(file);
      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;
      ref
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: filePath,
            name: fileName,
            imageType: fileType,
            base64Data: base64Data,
          );
    } catch (e) {
      // handled
    }
  }

  void clearAttachedFile() {
    final notifier = ref.read(chatInputProvider.notifier);
    notifier.clearAttachedFile();
    ref.read(chatInputProvider);
  }
}
