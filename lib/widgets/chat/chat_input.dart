import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';
import 'package:gen_ui_chat_ai/utils/image_utils.dart';
import 'package:gen_ui_chat_ai/services/speech_to_text_service.dart';
import 'package:gen_ui_chat_ai/utils/snackbar_utils.dart';

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

class ChatInput extends StatefulWidget {
  final Function(MessageData) onSendMessage;
  final Function(bool) onToggleStreaming;
  final VoidCallback? onStopStreaming;
  final bool isStreaming;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onToggleStreaming,
    this.onStopStreaming,
    this.isStreaming = false,
    this.focusNode,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  SpeechToTextService? _speechService;
  bool _isListening = false;
  bool _isSending = false;
  bool _plusActive = false;
  Timer? _plusTimer;

  // State for attached file
  String? _attachedFilePath;
  String? _attachedFileName;
  String? _attachedImageType;
  String? _attachedBase64Data;

  final GlobalKey _plusKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Restore text from controller if it was preserved
    updateKeepAlive();
    _initSpeechService();
  }

  void _initSpeechService() {
    _speechService = SpeechToTextService(
      onResult: (text) {
        setState(() {
          _textController.text = text;
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        // Show error via Snackbar
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: error,
            icon: Icons.mic_off,
            duration: Duration(seconds: 4),
          );
        }
      },
      onListeningChanged: (isListening) {
        setState(() {
          _isListening = isListening;
        });
      },
    );
    
    // Проверяем доступность микрофона при инициализации
    _speechService?.checkAvailability().then((available) {
      if (mounted) {
        setState(() {});
      }
    });
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
    if (_isListening) {
      await _speechService?.stopListening();
      return;
    }

    // Проверяем доступность микрофона
    final available = await _speechService?.checkAvailability() ?? false;
    
    if (!available) {
      // Показываем уведомление о необходимости разрешения
      if (mounted && context.mounted) {
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Микрофон недоступен. Проверьте разрешения в настройках системы.',
          icon: Icons.mic_off,
          duration: Duration(seconds: 4),
        );
      }
      return;
    }

    final started = await _speechService?.startListening(
      timeout: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    ) ?? false;

    if (!started && mounted && context.mounted) {
      SnackbarUtils.showErrorSnackBar(
        context: context,
        message: 'Не удалось запустить микрофон',
        icon: Icons.mic_off,
      );
    }
  }

  void _handleStopStreaming() {
    if (widget.onStopStreaming != null) {
      widget.onStopStreaming!();
    }
  }

  Future<void> _handleCamera() async {
    try {
      final file = await ImageUtils.takePhotoWithCamera();
      if (file == null) return;

      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;

      final imageType = ImageUtils.getMimeType(file.path);

      setState(() {
        _attachedFilePath = file.path;
        _attachedFileName = file.path.split('/').last;
        _attachedImageType = imageType;
        _attachedBase64Data = base64Data;
      });
    } catch (e) {
      // Camera error handled
    }
  }

  Future<void> _handleImage() async {
    try {
      final file = await ImageUtils.pickImageFromGallery();
      if (file == null) return;

      final base64Data = await ImageUtils.fileToBase64(file);
      if (base64Data == null) return;

      final imageType = ImageUtils.getMimeType(file.path);

      setState(() {
        _attachedFilePath = file.path;
        _attachedFileName = file.path.split('/').last;
        _attachedImageType = imageType;
        _attachedBase64Data = base64Data;
      });
    } catch (e) {
      // Image picker error handled
    }
  }

  Future<void> _handleFile() async {
    try {
      final file = await ImageUtils.pickFile();
      if (file == null) return;

      if (ImageUtils.isImageFile(file.path)) {
        // Handle as image
        final base64Data = await ImageUtils.fileToBase64(file);
        if (base64Data == null) return;

        final imageType = ImageUtils.getMimeType(file.path);

        setState(() {
          _attachedFilePath = file.path;
          _attachedFileName = file.path.split('/').last;
          _attachedImageType = imageType;
          _attachedBase64Data = base64Data;
        });
      } else {
        // Handle as regular file (for future implementation)
        // For now, just show the file name
        setState(() {
          _attachedFilePath = file.path;
          _attachedFileName = file.path.split('/').last;
          _attachedImageType = null;
          _attachedBase64Data = null;
        });
      }
    } catch (e) {
      // File picker error handled
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty && _attachedFilePath == null) return;

    setState(() => _isSending = true);

    // Останавливаем микрофон, если он активен
    if (_isListening) {
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
    final isMobile = Platform.isAndroid || Platform.isIOS;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
            constraints: BoxConstraints(
              maxWidth: isMobile ? 120 : 150,
            ),
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
              color: Colors.red
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
    if (_textController.text.trim().isNotEmpty || _attachedFilePath != null) return Icons.send;
    if (_speechService?.isAvailable ?? false) {
      return _isListening ? Icons.stop : Icons.mic;
    }
    return Icons.mic_off;
  }

  Color _getActionColor(ThemeData theme) {
    if (_isSending) return Colors.white;
    if (_textController.text.trim().isNotEmpty || _attachedFilePath != null) return Colors.white;
    if (_speechService?.isAvailable ?? false) {
      return _isListening ? Colors.red : theme.iconTheme.color ?? Colors.black;
    }
    return Colors.red;
  }

  Future<void> _handleMicrophoneAction() async {
    // If microphone is available, start/stop listening
    if (_speechService?.isAvailable ?? false) {
      await _startSpeechToText();
      return;
    }

    // If microphone is not available, try to initialize and request permission
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    // Show loading state
    setState(() {
      _isSending = true;
    });

    try {
      final available = await _speechService?.checkAvailability() ?? false;
      
      if (available && mounted && context.mounted) {
        // Permission granted, start listening
        setState(() {
          _isSending = false;
        });
        await _startSpeechToText();
      } else if (mounted && context.mounted) {
        // Permission denied
        setState(() {
          _isSending = false;
        });
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: localizations.micUnavailable,
          icon: Icons.mic_off,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        setState(() {
          _isSending = false;
        });
        SnackbarUtils.showErrorSnackBar(
          context: context,
          message: 'Ошибка доступа к микрофону',
          icon: Icons.mic_off,
          duration: const Duration(seconds: 3),
        );
      }
    }
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
                color: theme.textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.6),
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
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.2,
      ),
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

    return Container(
      padding: isMobile
          ? const EdgeInsets.only(top: 16)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMobile
            ? (theme.brightness == Brightness.dark
                ? UbuntuColors.inputContainerDark
                : UbuntuColors.inputContainerLight)
            : Colors.transparent,
        border: isMobile
            ? Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? UbuntuColors.inputContainerBorderDark
                      : UbuntuColors.inputContainerBorderLight,
                  width: 1,
                ),
                bottom: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? UbuntuColors.navBarBorderDark
                      : UbuntuColors.navBarBorderLight,
                  width: 1,
                ),
              )
            : null,
        boxShadow: isMobile
            ? [
                // Shadow on top to make it float
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                  spreadRadius: 0,
                ),
                // Subtle shadow on sides
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
                          ? UbuntuColors.inputContainerDark
                          : UbuntuColors.inputContainerLight,
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
                      sidePadding, 0, sidePadding, bottomPadding),
                  child: Row(
                    children: [
                      buildActionButton(
                        key: _plusKey,
                        gradient: _plusActive
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        bgColor: _plusActive
                            ? null
                            : (theme.brightness == Brightness.dark
                                ? UbuntuColors.inputContainerDark
                                : UbuntuColors.inputContainerLight),
                        onTap: () => _showPlusMenu(context),
                        child: Icon(
                          Icons.add,
                          size: iconSize,
                          color: _plusActive
                              ? Colors.white
                              : theme.iconTheme.color,
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
                          gradient: _textController.text.trim().isEmpty && _attachedFilePath == null
                              ? null
                              : LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                          bgColor: _textController.text.trim().isEmpty && _attachedFilePath == null
                              ? (theme.brightness == Brightness.dark
                                  ? UbuntuColors.inputContainerDark
                                  : UbuntuColors.inputContainerLight)
                              : null,
                          onTap: _textController.text.trim().isEmpty && _attachedFilePath == null
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
                      ? UbuntuColors.inputContainerDark
                      : UbuntuColors.inputContainerLight,
                  onTap: () => _showPlusMenu(context),
                  child: Icon(
                    Icons.add,
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: _buildAttachedFilePreview(),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? UbuntuColors.inputContainerDark
                                : UbuntuColors.inputContainerLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
                                  ? UbuntuColors.inputContainerBorderDark
                                  : UbuntuColors.inputContainerBorderLight,
                              width: 1,
                            ),
                          ),
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.enter &&
                                  !HardwareKeyboard.instance.isShiftPressed) {
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
                    child: Icon(
                      Icons.stop,
                      color: Colors.white,
                    ),
                  )
                else
                  buildActionButton(
                    gradient: _textController.text.trim().isEmpty && _attachedFilePath == null
                        ? null
                        : LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                    bgColor: _textController.text.trim().isEmpty && _attachedFilePath == null
                        ? (theme.brightness == Brightness.dark
                            ? UbuntuColors.inputContainerDark
                            : UbuntuColors.inputContainerLight)
                        : null,
                    onTap: _textController.text.trim().isEmpty && _attachedFilePath == null
                        ? _handleMicrophoneAction
                        : _sendMessage,
                    child: Icon(
                      _getActionIcon(),
                      color: _getActionColor(theme),
                    ),
                  ),
              ],
            ),
    );
  }
}
