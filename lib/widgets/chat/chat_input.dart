import 'dart:async';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/utils/image_utils.dart';
import 'package:chatorai/services/speech_to_text_service.dart';
import 'package:chatorai/utils/snackbar_utils.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/widgets/chat/model_settings_sheet.dart';

/// Data class for sending messages with optional media
class MessageData {
  final String text;
  final String? imagePath;
  final String? imageType;
  final String? base64Data;

  MessageData({
    required this.text,
    this.imagePath,
    this.imageType,
    this.base64Data,
  });
}

/// Helper function to extract file name from file
/// Works for both File and WebFile
String _getFileName(dynamic file) {
  String path;

  if (file is WebFile) {
    path = file.path;
  } else if (file is File) {
    path = file.path;
  } else {
    return 'unknown';
  }

  if (kIsWeb) {
    // On web, the path is just the file name
    return path;
  }
  // On native platforms, split by path separator
  return path.split(Platform.pathSeparator).last;
}

/// Helper function to get path from File or WebFile
String _getFilePath(dynamic file) {
  if (file is WebFile) {
    return file.path;
  } else if (file is File) {
    return file.path;
  }
  return 'unknown';
}

class ChatInput extends ConsumerStatefulWidget {
  final Function(MessageData) onSendMessage;
  final Function(bool) onToggleStreaming;
  final VoidCallback? onStopStreaming;
  final bool isStreaming;
  final FocusNode? focusNode;
  final Function(SpeechUiState, String)?
  onSpeechStateChanged; // Callback for speech state
  final bool Function(String)?
  checkModelSupportsImages; // Callback to check model support

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onToggleStreaming,
    this.onStopStreaming,
    this.isStreaming = false,
    this.focusNode,
    this.onSpeechStateChanged,
    this.checkModelSupportsImages,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  SpeechToTextService? _speechService;
  SpeechUiState _speechUiState = SpeechUiState.idle;
  String _speechStatusMessage = ''; // Для оверлея
  bool _isSending = false;
  bool _plusActive = false;
  Timer? _plusTimer;

  // State for attached file
  String? _attachedFilePath;
  String? _attachedFileName;
  String? _attachedImageType;
  String? _attachedBase64Data;

  final GlobalKey _plusKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Restore text from controller if it was preserved
    updateKeepAlive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize speech service after context is available
    if (_speechService == null) {
      _initSpeechService();
    }
  }

  void _initSpeechService() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    _speechService = SpeechToTextService(
      onResult: (text) {
        if (mounted) {
          setState(() {
            _textController.text = text;
          });
        }
      },
      onPartialResult: (text) {
        if (mounted) {
          setState(() {
            // Плавное обновление текста с debounce
            _textController.text = text;
          });
        }
      },
      onStatusMessage: (message) {
        if (mounted) {
          setState(() {
            _speechStatusMessage = message; // Для оверлея
          });
          // Pass state up to parent
          if (widget.onSpeechStateChanged != null) {
            widget.onSpeechStateChanged!(_speechUiState, message);
          }
        }
      },
      onStateChanged: (state) {
        if (mounted) {
          // Всегда обновляем состояние, даже если значение не изменилось
          // Это гарантирует сброс UI
          setState(() {
            _speechUiState = state;
            if (state == SpeechUiState.idle) {
              _speechStatusMessage = '';
            }
          });
          // Pass state up to parent
          if (widget.onSpeechStateChanged != null) {
            widget.onSpeechStateChanged!(state, _speechStatusMessage);
          }
        }
      },
      msgListening: localizations.speechListening,
      msgPhase2: localizations.speechPhase2,
      msgProcessing: localizations.speechProcessing,
      msgPreparing: localizations.speechPreparing,
      msgNoSpeech: localizations.micNoSpeechDetected,
      msgStartError: localizations.speechStartError,
      msgErrorNoMatch: localizations.speechErrorNoMatch,
      msgErrorTimeout: localizations.speechErrorTimeout,
      msgErrorNetwork: localizations.speechErrorNetwork,
      msgErrorNotAuthorized: localizations.speechErrorNotAuthorized,
      msgErrorServer: localizations.speechErrorServer,
      msgErrorTooManyRequests: localizations.speechErrorTooManyRequests,
      msgErrorUnknown: localizations.speechErrorUnknown,
      msgAutoRestart: localizations.micAutoRestart,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _plusTimer?.cancel();
    _speechService?.dispose();
    super.dispose();
  }

  void _clearAttachedFile() {
    setState(() {
      _attachedFilePath = null;
      _attachedFileName = null;
      _attachedImageType = null;
      _attachedBase64Data = null;
    });
  }

  Future<void> _startSpeechToText() async {
    if (_speechUiState == SpeechUiState.listening ||
        _speechUiState == SpeechUiState.preparing) {
      await _speechService?.stopListening();
      return;
    }

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    // Проверяем доступность микрофона
    final available = await _speechService?.checkAvailability() ?? false;

    if (!available) {
      // Показываем уведомление о необходимости разрешения
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: localizations.micUnavailable,
          icon: Icons.mic_off,
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    await _speechService?.startListening(
      timeout: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      waitForSpeech: const Duration(seconds: 10),
    );
  }

  void _handleStopStreaming() {
    if (widget.onStopStreaming != null) {
      widget.onStopStreaming!();
    }
  }

  Future<void> _handleCamera() async {
    final localizations = AppLocalizations.of(context)!;

    // Check model support BEFORE picking file
    if (widget.checkModelSupportsImages != null) {
      final modelId = ref.read(modelProvider).selectedModelId;
      final supportsImages = widget.checkModelSupportsImages!(modelId);

      if (!supportsImages) {
        // Show error but don't prevent camera use - user might want to type text first
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.modelDoesNotSupportImages(modelId),
            icon: Icons.image_not_supported,
            duration: const Duration(seconds: 4),
          );
        }
        // Still allow picking - user can see what they're trying to do
      }
    }

    try {
      final file = await ImageUtils.takePhotoWithCamera();
      if (file == null) return;

      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;

      final imageType = ImageUtils.getMimeType(file);
      final fileName = _getFileName(file);
      final filePath = _getFilePath(file);

      setState(() {
        _attachedFilePath = filePath;
        _attachedFileName = fileName;
        _attachedImageType = imageType;
        _attachedBase64Data = base64Data;
      });
    } catch (e) {
      // Camera error handled by ImageUtils
    }
  }

  Future<void> _handleImage() async {
    final localizations = AppLocalizations.of(context)!;

    // Check model support BEFORE picking file
    if (widget.checkModelSupportsImages != null) {
      final modelId = ref.read(modelProvider).selectedModelId;
      final supportsImages = widget.checkModelSupportsImages!(modelId);

      if (!supportsImages) {
        // Show error but don't prevent image pick - user might want to type text first
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.modelDoesNotSupportImages(modelId),
            icon: Icons.image_not_supported,
            duration: const Duration(seconds: 4),
          );
        }
        // Still allow picking
      }
    }

    try {
      final file = await ImageUtils.pickImageFromGallery();
      if (file == null) return;

      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;

      final imageType = ImageUtils.getMimeType(file);
      final fileName = _getFileName(file);
      final filePath = _getFilePath(file);

      setState(() {
        _attachedFilePath = filePath;
        _attachedFileName = fileName;
        _attachedImageType = imageType;
        _attachedBase64Data = base64Data;
      });
    } catch (e) {
      // Image picker error handled
    }
  }

  Future<void> _handleFile() async {
    final localizations = AppLocalizations.of(context)!;

    // Check model support BEFORE picking file
    if (widget.checkModelSupportsImages != null) {
      final modelId = ref.read(modelProvider).selectedModelId;
      final supportsImages = widget.checkModelSupportsImages!(modelId);

      if (!supportsImages) {
        // Show error but don't prevent file pick - user might want to type text first
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.modelDoesNotSupportFiles(modelId),
            icon: Icons.attach_file,
            duration: const Duration(seconds: 4),
          );
        }
        // Still allow picking
      }
    }

    try {
      final file = await ImageUtils.pickFile();
      if (file == null) return;

      // Get file name (works for both native and web platforms)
      final fileName = _getFileName(file);
      final fileType = ImageUtils.getMimeType(file);
      final filePath = _getFilePath(file);

      // Convert to base64
      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;

      setState(() {
        _attachedFilePath = filePath;
        _attachedFileName = fileName;
        _attachedImageType = fileType;
        _attachedBase64Data = base64Data;
      });
    } catch (e) {
      // File picker error handled
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty && _attachedFilePath == null) {
      return;
    }

    // Check model support BEFORE sending if there's an attached file
    if (_attachedFilePath != null && _attachedBase64Data != null) {
      if (widget.checkModelSupportsImages != null) {
        final modelId = ref.read(modelProvider).selectedModelId;
        final supportsImages = widget.checkModelSupportsImages!(modelId);

        if (!supportsImages) {
          // Show error but DON'T clear data - user can switch model or remove file
          if (mounted) {
            SnackbarUtils.showErrorSnackBar(
              context: context,
              message:
                  'Модель $modelId не поддерживает файлы. Удалите файл или выберите другую модель.',
              icon: Icons.image_not_supported,
              duration: const Duration(seconds: 5),
            );
          }
          setState(() => _isSending = false);
          return; // Don't send, but keep data
        }
      }
    }

    setState(() => _isSending = true);

    // Останавливаем микрофон, если он активен
    if (_speechUiState == SpeechUiState.listening ||
        _speechUiState == SpeechUiState.preparing) {
      await _speechService?.stopListening();
    }

    final messageData = MessageData(
      text: _textController.text.trim(),
      imagePath: _attachedFilePath,
      imageType: _attachedImageType,
      base64Data: _attachedBase64Data,
    );

    widget.onSendMessage(messageData);
    widget.onToggleStreaming(true);
    _textController.clear();
    _clearAttachedFile();

    setState(() {
      _isSending = false;
    });
  }

  Future<void> _showPlusMenu(BuildContext context) async {
    setState(() => _plusActive = true);

    final RenderBox? box =
        _plusKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localizations = AppLocalizations.of(context)!;

    // Check if running on mobile platform (Android, iOS)
    // Camera is only available on mobile devices
    // Use kIsWeb for web detection, Platform for native platforms
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    // Build menu items based on platform
    final menuItems = <PopupMenuEntry<String>>[
      // Camera only for mobile
      if (isMobile)
        PopupMenuItem(
          value: 'add_camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt, size: 20),
              SizedBox(width: 8),
              Text(localizations.addCamera),
            ],
          ),
        ),
      // Image for all platforms
      PopupMenuItem(
        value: 'add_image',
        child: Row(
          children: [
            Icon(Icons.image, size: 20),
            SizedBox(width: 8),
            Text(localizations.addImage),
          ],
        ),
      ),
      // File for all platforms
      PopupMenuItem(
        value: 'add_file',
        child: Row(
          children: [
            Icon(Icons.attach_file, size: 20),
            SizedBox(width: 8),
            Text(localizations.addFile),
          ],
        ),
      ),
    ];

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 170, // Подняли выше, чтобы меню было над кнопкой
        offset.dx + size.width,
        offset.dy - 40, // Нижняя граница выше кнопки
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: menuItems,
    );

    if (selected == 'add_camera') {
      await _handleCamera();
    } else if (selected == 'add_image') {
      await _handleImage();
    } else if (selected == 'add_file') {
      await _handleFile();
    }

    setState(() => _plusActive = false);
  }

  int _computeMaxLines(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.4;
    return (maxHeight / 24).floor().clamp(1, 12);
  }

  bool _isMobileLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  Widget _buildAttachedFilePreview() {
    if (_attachedFilePath == null) return const SizedBox.shrink();

    final isMobile = _isMobileLayout(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _attachedImageType != null ? Icons.image : Icons.attach_file,
            size: isMobile ? 12 : 12,
            color: Colors.blue,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 120 : 150),
            child: Text(
              _attachedFileName ?? 'file',
              style: TextStyle(
                fontSize: isMobile ? 10 : 10,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.close,
              size: isMobile ? 10 : 10,
              color: Colors.red,
            ),
            onPressed: _clearAttachedFile,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: isMobile ? 14 : 14,
              minHeight: isMobile ? 14 : 14,
            ),
            splashRadius: isMobile ? 8 : 8,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    if (_isSending) return Icons.autorenew;
    if (_textController.text.trim().isNotEmpty || _attachedFilePath != null) {
      return Icons.send;
    }
    if (_speechUiState == SpeechUiState.listening ||
        _speechUiState == SpeechUiState.preparing) {
      return Icons.stop;
    }
    return Icons.mic;
  }

  Color _getActionColor(ThemeData theme) {
    if (_isSending) return Colors.white;
    if (_textController.text.trim().isNotEmpty || _attachedFilePath != null) {
      return Colors.white;
    }
    if (_speechUiState == SpeechUiState.listening ||
        _speechUiState == SpeechUiState.preparing) {
      return Colors.red;
    }
    if (_speechUiState == SpeechUiState.error ||
        _speechUiState == SpeechUiState.noSpeech) {
      return Colors.red;
    }
    return theme.iconTheme.color ?? Colors.black;
  }

  Future<void> _handleMicrophoneAction() async {
    // If currently listening or preparing, stop
    if (_speechUiState == SpeechUiState.listening ||
        _speechUiState == SpeechUiState.preparing) {
      await _speechService?.stopListening();
      return;
    }

    // If in error state, restart
    if (_speechUiState == SpeechUiState.error ||
        _speechUiState == SpeechUiState.noSpeech) {
      await _startSpeechToText();
      return;
    }

    // If microphone is available, start listening
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    // Show loading state
    setState(() {
      _isSending = true;
    });

    try {
      final available = await _speechService?.checkAvailability() ?? false;

      if (available && mounted) {
        // Permission granted, start listening
        setState(() {
          _isSending = false;
        });
        await _startSpeechToText();
      } else if (mounted) {
        // Permission denied
        setState(() {
          _isSending = false;
        });
        // Service will show its own error via onStatusMessage
        // Only show snackbar if service couldn't start
        if (_speechUiState == SpeechUiState.idle) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.micUnavailable,
            icon: Icons.mic_off,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        // Service handles errors via onStatusMessage
        // Only show snackbar for unexpected errors
        if (_speechUiState == SpeechUiState.idle) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: localizations.micStartFailed,
            icon: Icons.mic_off,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  Future<void> _handleModelSettings() async {
    final modelState = ref.read(modelProvider);
    final settingsState = ref.read(modelSettingsProvider);
    final settingsNotifier = ref.read(modelSettingsProvider.notifier);
    final localizations = AppLocalizations.of(context)!;

    // Check if a model is selected
    if (modelState.selectedModelId.isEmpty) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: localizations.noModelSelected,
        icon: Icons.error,
      );
      return;
    }

    // Ensure settings provider has the active model set
    if (settingsState.activeSettings?.modelId != modelState.selectedModelId) {
      await settingsNotifier.setActiveModel(modelState.selectedModelId);
    }

    // Show the settings sheet
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: const ModelSettingsSheet(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile = _isMobileLayout(context);
    final maxLines = _computeMaxLines(context);

    const double buttonSize = 44.0;
    const double iconSize = 20.0;
    const double sidePadding = 20.0;
    const double bottomPadding = 12.0;

    // Create the TextField once to preserve state across layout changes
    final textField = TextField(
      controller: _textController,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.multiline,
      minLines: 1,
      maxLines: maxLines,
      decoration: isMobile
          ? InputDecoration(
              hintText: _attachedFilePath != null
                  ? localizations.typeYourMessage
                  : localizations.typeYourMessage,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            )
          : InputDecoration(
              hintText: localizations.typeYourMessage,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.2),
      textInputAction: isMobile ? TextInputAction.newline : null,
      onChanged: (text) => setState(() {}),
      enabled: !_isSending,
    );

    Widget buildActionButton({
      Key? key,
      required Widget child,
      Gradient? gradient,
      Color? bgColor,
      VoidCallback? onTap,
    }) {
      return Container(
        key: key,
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? bgColor : null,
          borderRadius: BorderRadius.circular(buttonSize / 2),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(buttonSize / 2),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Основной контейнер ввода
        Container(
          padding: isMobile
              ? const EdgeInsets.only(top: 16)
              : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMobile
                ? (theme.brightness == Brightness.dark
                      ? ChatoraiColors.inputContainerDark
                      : ChatoraiColors.inputContainerLight)
                : Colors.transparent,
            border: isMobile
                ? Border(
                    top: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? ChatoraiColors.inputContainerBorderDark
                          : ChatoraiColors.inputContainerBorderLight,
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? ChatoraiColors.navBarBorderDark
                          : ChatoraiColors.navBarBorderLight,
                      width: 1,
                    ),
                  )
                : null,
            boxShadow: isMobile
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
            borderRadius: isMobile
                ? const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  )
                : BorderRadius.circular(0),
          ),
          child: isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // УБРАЛИ inline статус микрофона
                    if (_attachedFilePath != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildAttachedFilePreview(),
                      ),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 48,
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? ChatoraiColors.inputContainerDark
                              : ChatoraiColors.inputContainerLight,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: textField,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        sidePadding,
                        0,
                        sidePadding,
                        bottomPadding,
                      ),
                      child: Row(
                        children: [
                          buildActionButton(
                            key: _plusKey,
                            gradient: _plusActive
                                ? LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  )
                                : null,
                            bgColor: _plusActive
                                ? null
                                : (theme.brightness == Brightness.dark
                                      ? ChatoraiColors.inputContainerDark
                                      : ChatoraiColors.inputContainerLight),
                            onTap: () {
                              _showPlusMenu(context);
                            },
                            child: Icon(
                              Icons.add,
                              size: iconSize,
                              color: _plusActive
                                  ? Colors.white
                                  : theme.iconTheme.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Settings button
                          buildActionButton(
                            key: _settingsKey,
                            bgColor: theme.brightness == Brightness.dark
                                ? ChatoraiColors.inputContainerDark
                                : ChatoraiColors.inputContainerLight,
                            onTap: _handleModelSettings,
                            child: Icon(
                              Icons.settings_input_component_outlined,
                              size: iconSize,
                              color: theme.iconTheme.color,
                            ),
                          ),
                          const Spacer(),
                          // Show stop button when streaming
                          if (widget.isStreaming)
                            buildActionButton(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red,
                                  Colors.red.withValues(alpha: 0.8),
                                ],
                              ),
                              onTap: _handleStopStreaming,
                              child: Icon(
                                Icons.stop,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            )
                          else
                            buildActionButton(
                              gradient:
                                  _textController.text.trim().isEmpty &&
                                      _attachedFilePath == null &&
                                      _speechUiState == SpeechUiState.idle
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                    ),
                              bgColor:
                                  _textController.text.trim().isEmpty &&
                                      _attachedFilePath == null &&
                                      _speechUiState == SpeechUiState.idle
                                  ? (theme.brightness == Brightness.dark
                                        ? ChatoraiColors.inputContainerDark
                                        : ChatoraiColors.inputContainerLight)
                                  : null,
                              onTap:
                                  _textController.text.trim().isEmpty &&
                                      _attachedFilePath == null
                                  ? _handleMicrophoneAction
                                  : _sendMessage,
                              child: Icon(
                                _getActionIcon(),
                                size: iconSize,
                                color: _getActionColor(theme),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    buildActionButton(
                      key: _plusKey,
                      bgColor: theme.brightness == Brightness.dark
                          ? ChatoraiColors.inputContainerDark
                          : ChatoraiColors.inputContainerLight,
                      onTap: () => _showPlusMenu(context),
                      child: Icon(Icons.add, color: theme.iconTheme.color),
                    ),
                    const SizedBox(width: 8),
                    // Settings button
                    buildActionButton(
                      key: _settingsKey,
                      bgColor: theme.brightness == Brightness.dark
                          ? ChatoraiColors.inputContainerDark
                          : ChatoraiColors.inputContainerLight,
                      onTap: _handleModelSettings,
                      child: Icon(
                        Icons.settings_input_component_outlined,
                        color: theme.iconTheme.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_attachedFilePath != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: _buildAttachedFilePreview(),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? ChatoraiColors.inputContainerDark
                                    : ChatoraiColors.inputContainerLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? ChatoraiColors.inputContainerBorderDark
                                      : ChatoraiColors.inputContainerBorderLight,
                                  width: 1,
                                ),
                              ),
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.enter &&
                                      !HardwareKeyboard
                                          .instance
                                          .isShiftPressed) {
                                    _sendMessage();
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: textField,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Show stop button when streaming
                    if (widget.isStreaming)
                      buildActionButton(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red,
                            Colors.red.withValues(alpha: 0.8),
                          ],
                        ),
                        onTap: _handleStopStreaming,
                        child: Icon(Icons.stop, color: Colors.white),
                      )
                    else
                      buildActionButton(
                        gradient:
                            _textController.text.trim().isEmpty &&
                                _attachedFilePath == null &&
                                _speechUiState == SpeechUiState.idle
                            ? null
                            : LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                ],
                              ),
                        bgColor:
                            _textController.text.trim().isEmpty &&
                                _attachedFilePath == null &&
                                _speechUiState == SpeechUiState.idle
                            ? (theme.brightness == Brightness.dark
                                  ? ChatoraiColors.inputContainerDark
                                  : ChatoraiColors.inputContainerLight)
                            : null,
                        onTap:
                            _textController.text.trim().isEmpty &&
                                _attachedFilePath == null
                            ? _handleMicrophoneAction
                            : _sendMessage,
                        child: Icon(
                          _getActionIcon(),
                          color: _getActionColor(theme),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
