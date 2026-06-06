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
import 'package:chatorai/agents/agent_registry.dart';
import 'package:chatorai/widgets/chat/agent_mention_popup.dart';
import 'package:chatorai/widgets/chat/model_settings_sheet.dart';

// ===========================================================================
// MESSAGE DATA
// ===========================================================================

class MessageData {
  final String text;
  final String? imagePath;
  final String? imageType;
  final String? base64Data;
  final String? delegateAgentId;

  MessageData({
    required this.text,
    this.imagePath,
    this.imageType,
    this.base64Data,
    this.delegateAgentId,
  });
}

// ===========================================================================
// HELPER FUNCTIONS
// ===========================================================================

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

// ===========================================================================
// CHAT INPUT WIDGET
// ===========================================================================

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
  final Function(double)? onSoundLevelChanged; // Callback for sound level

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onToggleStreaming,
    this.onStopStreaming,
    this.isStreaming = false,
    this.focusNode,
    this.onSpeechStateChanged,
    this.checkModelSupportsImages,
    this.onSoundLevelChanged,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

// ===========================================================================
// CHAT INPUT STATE
// ===========================================================================

class _ChatInputState extends ConsumerState<ChatInput>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  SpeechToTextService? _speechService;
  Timer? _plusTimer;

  final GlobalKey _plusKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _agentKey = GlobalKey();

  // @-mention agent popup
  String _agentQuery = '';
  int _selectedAgentIndex = 0;
  OverlayEntry? _agentOverlay;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Restore text from controller if it was preserved
    updateKeepAlive();
    // Listen to text changes to update UI (e.g., icon)
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
    _detectAgentMention();
  }

  void _detectAgentMention() {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;
    if (cursorPos < 0) {
      _hideAgentPopup();
      return;
    }

    // Find '@' before cursor
    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex == -1 ||
        (atIndex > 0 && beforeCursor[atIndex - 1] != ' ' && atIndex != 0)) {
      _hideAgentPopup();
      return;
    }

    final query = beforeCursor.substring(atIndex + 1);
    if (query.contains(' ')) {
      _hideAgentPopup();
      return;
    }

    _agentQuery = query;
    _selectedAgentIndex = 0;
    _showAgentPopup();
  }

  List<AgentDefinition> _filteredAgents() {
    final all = AgentRegistry().getSubagents();
    if (_agentQuery.isEmpty) return all.take(10).toList();
    final q = _agentQuery.toLowerCase();
    return all
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              (a.description?.toLowerCase().contains(q) ?? false),
        )
        .take(10)
        .toList();
  }

  void _showAgentPopup() {
    if (_agentOverlay != null) return;
    if (!mounted) return;

    final overlay = Overlay.of(context);

    final inputBox = context.findRenderObject() as RenderBox?;
    if (inputBox == null) return;

    final inputOffset = inputBox.localToGlobal(Offset.zero);

    _agentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height - inputOffset.dy + 8,
        left: inputOffset.dx + ChatoraiSpacing.lg,
        width: 340,
        child: AgentMentionPopup(
          agents: _filteredAgents(),
          selectedIndex: _selectedAgentIndex,
          onSelected: _insertAgentMention,
        ),
      ),
    );

    overlay.insert(_agentOverlay!);
  }

  void _hideAgentPopup() {
    _agentOverlay?.remove();
    _agentOverlay = null;
  }

  void _insertAgentMention(AgentDefinition agent) {
    final text = _textController.text;
    final cursorPos = _textController.selection.baseOffset;
    if (cursorPos < 0) return;

    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex == -1) return;

    final afterCursor = text.substring(cursorPos);

    final newText = '${text.substring(0, atIndex)}@${agent.id} $afterCursor';
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + agent.id.length + 2),
    );
    _hideAgentPopup();
  }

  void _navigateAgentPopup(bool down) {
    final agents = _filteredAgents();
    if (agents.isEmpty) return;
    if (down) {
      _selectedAgentIndex = (_selectedAgentIndex + 1) % agents.length;
    } else {
      _selectedAgentIndex =
          (_selectedAgentIndex - 1 + agents.length) % agents.length;
    }
    setState(() {});
    _refreshAgentPopup();
  }

  void _refreshAgentPopup() {
    _hideAgentPopup();
    _showAgentPopup();
  }

  void _selectCurrentAgent() {
    final agents = _filteredAgents();
    if (_selectedAgentIndex < agents.length) {
      _insertAgentMention(agents[_selectedAgentIndex]);
    }
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
          _textController.text = text;
        }
      },
      onPartialResult: (text) {
        if (mounted) {
          _textController.text = text;
        }
      },
      onStatusMessage: (message) {
        if (mounted) {
          ref.read(chatInputProvider.notifier).setSpeechStatusMessage(message);
          // Pass state up to parent
          if (widget.onSpeechStateChanged != null) {
            widget.onSpeechStateChanged!(
              ref.read(chatInputProvider).speechUiState,
              message,
            );
          }
        }
      },
      onStateChanged: (state) {
        if (mounted) {
          // Всегда обновляем состояние, даже если значение не изменилось
          // Это гарантирует сброс UI
          ref.read(chatInputProvider.notifier).setSpeechUiState(state);
          if (state == SpeechUiState.idle) {
            ref.read(chatInputProvider.notifier).setSpeechStatusMessage('');
          }
          // Pass state up to parent
          if (widget.onSpeechStateChanged != null) {
            widget.onSpeechStateChanged!(
              state,
              ref.read(chatInputProvider).speechStatusMessage,
            );
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
      onSoundLevelChange: widget.onSoundLevelChanged,
    );
  }

  @override
  void dispose() {
    _hideAgentPopup();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _plusTimer?.cancel();
    _speechService?.dispose();
    super.dispose();
  }

  void _clearAttachedFile() {
    final notifier = ref.read(chatInputProvider.notifier);
    notifier.clearAttachedFile();
    // Force rebuild by reading the provider
    ref.read(chatInputProvider);
  }

  Future<void> _startSpeechToText() async {
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.listening ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.preparing) {
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

      ref
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: filePath,
            name: fileName,
            imageType: imageType,
            base64Data: base64Data,
          );
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

      ref
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: filePath,
            name: fileName,
            imageType: imageType,
            base64Data: base64Data,
          );
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

      ref
          .read(chatInputProvider.notifier)
          .setAttachedFile(
            path: filePath,
            name: fileName,
            imageType: fileType,
            base64Data: base64Data,
          );
    } catch (e) {
      // File picker error handled
    }
  }

  Future<void> _sendMessage() async {
    // Unfocus to close keyboard
    FocusScope.of(context).unfocus();

    if (_textController.text.trim().isEmpty &&
        ref.read(chatInputProvider).attachedFilePath == null) {
      return;
    }

    // Check model support BEFORE sending if there's an attached file
    if (ref.read(chatInputProvider).attachedFilePath != null &&
        ref.read(chatInputProvider).attachedBase64Data != null) {
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
          ref.read(chatInputProvider.notifier).setIsSending(false);
          return; // Don't send, but keep data
        }
      }
    }

    ref.read(chatInputProvider.notifier).setIsSending(true);

    // Останавливаем микрофон, если он активен
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.listening ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.preparing) {
      await _speechService?.stopListening();
    }

    var text = _textController.text.trim();
    String? delegateAgentId;

    // Check for @agent delegation
    final agentMatch = RegExp(r'^@(\S+)\s*').firstMatch(text);
    if (agentMatch != null) {
      final agentId = agentMatch.group(1);
      if (AgentRegistry().get(agentId!) != null) {
        delegateAgentId = agentId;
        text = text.substring(agentMatch.end);
      }
    }

    final messageData = MessageData(
      text: text,
      delegateAgentId: delegateAgentId,
      imagePath: ref.read(chatInputProvider).attachedFilePath,
      imageType: ref.read(chatInputProvider).attachedImageType,
      base64Data: ref.read(chatInputProvider).attachedBase64Data,
    );

    widget.onSendMessage(messageData);
    widget.onToggleStreaming(true);
    _textController.clear();
    _clearAttachedFile();

    ref.read(chatInputProvider.notifier).setIsSending(false);
  }

  Future<void> _showPlusMenu(BuildContext context) async {
    ref.read(chatInputProvider.notifier).setPlusActive(true);

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
              Icon(Icons.camera_alt, size: ChatoraiIconSizes.buttonIcon),
              SizedBox(width: ChatoraiSpacing.sm),
              Text(localizations.addCamera),
            ],
          ),
        ),
      // Image for all platforms
      PopupMenuItem(
        value: 'add_image',
        child: Row(
          children: [
            Icon(Icons.image, size: ChatoraiIconSizes.buttonIcon),
            SizedBox(width: ChatoraiSpacing.sm),
            Text(localizations.addImage),
          ],
        ),
      ),
      // File for all platforms
      PopupMenuItem(
        value: 'add_file',
        child: Row(
          children: [
            Icon(Icons.attach_file, size: ChatoraiIconSizes.buttonIcon),
            SizedBox(width: ChatoraiSpacing.sm),
            Text(localizations.addFile),
          ],
        ),
      ),
    ];

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 170,
        offset.dx + size.width,
        offset.dy - 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
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

    ref.read(chatInputProvider.notifier).setPlusActive(false);
  }

  void _showAgentSwitcher(BuildContext context) {
    final currentAgent = ref.read(currentAgentProvider);
    final primaryAgents = AgentRegistry().getPrimaryAgents();

    final RenderBox? box =
        _agentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 120,
        offset.dx + size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
      ),
      items: primaryAgents.map((agent) {
        final isActive = agent.id == currentAgent.id;
        return PopupMenuItem<String>(
          value: agent.id,
          enabled: !isActive,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : (agent.color != null
                            ? Color(
                                int.parse(
                                  agent.color!.replaceFirst('#', '0xFF'),
                                ),
                              )
                            : Theme.of(context).colorScheme.outline),
                ),
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(
                agent.name,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((agentId) {
      if (agentId != null && mounted) {
        final agent = AgentRegistry().get(agentId);
        if (agent != null) {
          ref.read(currentAgentProvider.notifier).setAgent(agent);
        }
      }
    });
  }

  int _computeMaxLines(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.4;
    return (maxHeight / 24).floor().clamp(1, 12);
  }

  bool _isMobileLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  Widget _buildAttachedFilePreview(ChatInputState state) {
    if (state.attachedFilePath == null) return const SizedBox.shrink();

    final isMobile = _isMobileLayout(context);

    return Container(
      margin: const EdgeInsets.only(bottom: ChatoraiSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.sm,
        vertical: ChatoraiSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ChatoraiColors.link.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        border: Border.all(color: ChatoraiColors.link.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.attachedImageType != null ? Icons.image : Icons.attach_file,
            size: ChatoraiIconSizes.xs,
            color: ChatoraiColors.link,
          ),
          const SizedBox(width: ChatoraiSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 120 : 150),
            child: Text(
              state.attachedFileName ?? 'file',
              style: TextStyle(
                fontSize: ChatoraiFontSizes.sm,
                color: ChatoraiColors.link,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ChatoraiSpacing.xs),
          IconButton(
            icon: Icon(
              Icons.close,
              size: ChatoraiFontSizes.sm,
              color: ChatoraiColors.error,
            ),
            onPressed: _clearAttachedFile,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: ChatoraiSpacing.md,
              minHeight: ChatoraiSpacing.md,
            ),
            splashRadius: ChatoraiSpacing.sm,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(ChatInputState state) {
    if (state.isSending) return Icons.autorenew;
    if (_textController.text.trim().isNotEmpty ||
        state.attachedFilePath != null) {
      return Icons.send;
    }
    if (state.speechUiState == SpeechUiState.listening ||
        state.speechUiState == SpeechUiState.preparing) {
      return Icons.stop;
    }
    return Icons.mic;
  }

  Color _getActionColor(ThemeData theme, ChatInputState state) {
    if (state.isSending) return ChatoraiColors.pureWhite;
    if (_textController.text.trim().isNotEmpty ||
        state.attachedFilePath != null) {
      return ChatoraiColors.pureWhite;
    }
    if (state.speechUiState == SpeechUiState.listening ||
        state.speechUiState == SpeechUiState.preparing) {
      return ChatoraiColors.error;
    }
    if (state.speechUiState == SpeechUiState.error ||
        state.speechUiState == SpeechUiState.noSpeech) {
      return ChatoraiColors.error;
    }
    return theme.iconTheme.color ?? ChatoraiColors.pureBlack;
  }

  Future<void> _handleMicrophoneAction() async {
    // If currently listening or preparing, stop
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.listening ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.preparing) {
      await _speechService?.stopListening();
      return;
    }

    // If in error state, restart
    if (ref.read(chatInputProvider).speechUiState == SpeechUiState.error ||
        ref.read(chatInputProvider).speechUiState == SpeechUiState.noSpeech) {
      await _startSpeechToText();
      return;
    }

    // If microphone is available, start listening
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    // Show loading state
    ref.read(chatInputProvider.notifier).setIsSending(true);

    try {
      final available = await _speechService?.checkAvailability() ?? false;

      if (available && mounted) {
        // Permission granted, start listening
        ref.read(chatInputProvider.notifier).setIsSending(false);
        await _startSpeechToText();
      } else if (mounted) {
        // Permission denied
        ref.read(chatInputProvider.notifier).setIsSending(false);
        // Service will show its own error via onStatusMessage
        // Only show snackbar if service couldn't start
        if (ref.read(chatInputProvider).speechUiState == SpeechUiState.idle) {
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
        ref.read(chatInputProvider.notifier).setIsSending(false);
        // Service handles errors via onStatusMessage
        // Only show snackbar for unexpected errors
        if (ref.read(chatInputProvider).speechUiState == SpeechUiState.idle) {
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

  Widget _buildAgentButton(ThemeData theme) {
    final currentAgent = ref.watch(currentAgentProvider);
    return Container(
      key: _agentKey,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? ChatoraiColors.inputContainerDark
            : ChatoraiColors.inputContainerLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showAgentSwitcher(context),
          child: Center(
            child: Text(
              currentAgent.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile = _isMobileLayout(context);
    final maxLines = _computeMaxLines(context);
    final chatInputState = ref.watch(chatInputProvider);

    const double buttonSize = 44.0;
    const double iconSize = ChatoraiIconSizes.buttonIcon;
    const double sidePadding = ChatoraiSpacing.lg;
    const double bottomPadding = ChatoraiSpacing.md;

    final isSpellCheckSupported =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    Widget buildTextField() {
      return CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.tab): () {
            if (_agentOverlay != null) {
              _navigateAgentPopup(true);
            }
          },
          SingleActivator(LogicalKeyboardKey.tab, shift: true): () {
            if (_agentOverlay != null) {
              _navigateAgentPopup(false);
            }
          },
          SingleActivator(LogicalKeyboardKey.enter): () {
            if (_agentOverlay != null) {
              _selectCurrentAgent();
            } else if (!HardwareKeyboard.instance.isShiftPressed) {
              _sendMessage();
            }
          },
          SingleActivator(LogicalKeyboardKey.escape): () {
            if (_agentOverlay != null) {
              _hideAgentPopup();
            }
          },
          SingleActivator(LogicalKeyboardKey.arrowDown): () {
            if (_agentOverlay != null) {
              _navigateAgentPopup(true);
            }
          },
          SingleActivator(LogicalKeyboardKey.arrowUp): () {
            if (_agentOverlay != null) {
              _navigateAgentPopup(false);
            }
          },
        },
        child: Focus(
          onKeyEvent: (node, event) {
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _textController,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: maxLines,
            spellCheckConfiguration: isSpellCheckSupported
                ? const SpellCheckConfiguration()
                : null,
            decoration: isMobile
                ? InputDecoration(
                    hintText: chatInputState.attachedFilePath != null
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
                      horizontal: ChatoraiSpacing.lg,
                      vertical: ChatoraiSpacing.md,
                    ),
                  )
                : InputDecoration(
                    hintText: localizations.typeYourMessage,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ChatoraiSpacing.lg,
                      vertical: ChatoraiSpacing.md,
                    ),
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: ChatoraiFontSizes.lg,
              height: 1.2,
            ),
            textInputAction: isMobile
                ? TextInputAction.newline
                : TextInputAction.newline,
            enabled: !chatInputState.isSending,
          ),
        ),
      );
    }

    final textField = buildTextField();

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

    Widget buildStopButton(BuildContext context, WidgetRef ref) {
      final retryAsync = ref.watch(retryCountdownProvider);
      final retryProgress = retryAsync.hasValue ? retryAsync.value : null;
      final isRetrying =
          retryProgress != null && retryProgress > 0 && retryProgress <= 1;

      return AnimatedContainer(
        duration: ChatoraiDurations.normal,
        curve: Curves.easeInOut,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isRetrying
              ? null
              : LinearGradient(
                  colors: [
                    ChatoraiColors.error,
                    ChatoraiColors.error.withValues(alpha: 0.8),
                  ],
                ),
          color: isRetrying ? Colors.transparent : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: isRetrying ? ChatoraiColors.error : Colors.transparent,
            width: isRetrying ? ChatoraiBorderWidth.medium : 0.0,
          ),
          boxShadow: isRetrying ? null : ChatoraiShadows.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRetrying)
              CircularProgressIndicator(
                value: retryProgress,
                strokeWidth: ChatoraiBorderWidth.medium,
                backgroundColor: ChatoraiColors.error.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(ChatoraiColors.error),
              ),
            IconButton(
              onPressed: widget.onStopStreaming,
              icon: Icon(
                Icons.stop,
                size: isRetrying ? ChatoraiIconSizes.md : ChatoraiIconSizes.lg,
                color: ChatoraiColors.pureWhite,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: isRetrying ? 'Cancelling retry...' : 'Stop generation',
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          padding: isMobile
              ? const EdgeInsets.only(top: ChatoraiSpacing.lg)
              : const EdgeInsets.all(ChatoraiSpacing.lg),
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
                      width: ChatoraiBorderWidth.thinBold,
                    ),
                    bottom: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? ChatoraiColors.navBarBorderDark
                          : ChatoraiColors.navBarBorderLight,
                      width: ChatoraiBorderWidth.thinBold,
                    ),
                  )
                : null,
            boxShadow: isMobile
                ? [
                    BoxShadow(
                      color: ChatoraiColors.black30,
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: ChatoraiColors.black20,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: ChatoraiColors.black05,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
            borderRadius: isMobile
                ? const BorderRadius.only(
                    topLeft: Radius.circular(ChatoraiBorderRadius.xl),
                    topRight: Radius.circular(ChatoraiBorderRadius.xl),
                  )
                : BorderRadius.zero,
          ),
          child: isMobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (chatInputState.attachedFilePath != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ChatoraiSpacing.lg,
                        ),
                        child: _buildAttachedFilePreview(chatInputState),
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
                            topLeft: Radius.circular(ChatoraiBorderRadius.xl),
                            topRight: Radius.circular(ChatoraiBorderRadius.xl),
                          ),
                        ),
                        child: textField,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        sidePadding,
                        0,
                        sidePadding,
                        bottomPadding,
                      ),
                      child: Row(
                        children: [
                          buildActionButton(
                            key: _plusKey,
                            gradient: chatInputState.plusActive
                                ? LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  )
                                : null,
                            bgColor: chatInputState.plusActive
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
                              color: chatInputState.plusActive
                                  ? ChatoraiColors.pureWhite
                                  : theme.iconTheme.color,
                            ),
                          ),
                          const SizedBox(width: ChatoraiSpacing.sm),
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
                          const SizedBox(width: ChatoraiSpacing.sm),
                          _buildAgentButton(theme),
                          const Spacer(),
                          if (widget.isStreaming)
                            buildStopButton(context, ref)
                          else
                            buildActionButton(
                              gradient:
                                  _textController.text.trim().isEmpty &&
                                      chatInputState.attachedFilePath == null &&
                                      chatInputState.speechUiState ==
                                          SpeechUiState.idle
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
                                      chatInputState.attachedFilePath == null &&
                                      chatInputState.speechUiState ==
                                          SpeechUiState.idle
                                  ? (theme.brightness == Brightness.dark
                                        ? ChatoraiColors.inputContainerDark
                                        : ChatoraiColors.inputContainerLight)
                                  : null,
                              onTap:
                                  _textController.text.trim().isEmpty &&
                                      chatInputState.attachedFilePath == null
                                  ? _handleMicrophoneAction
                                  : _sendMessage,
                              child: Icon(
                                _getActionIcon(chatInputState),
                                size: iconSize,
                                color: _getActionColor(theme, chatInputState),
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
                    const SizedBox(width: ChatoraiSpacing.sm),
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
                    const SizedBox(width: ChatoraiSpacing.sm),
                    _buildAgentButton(theme),
                    const SizedBox(width: ChatoraiSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (chatInputState.attachedFilePath != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ChatoraiSpacing.xs,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: _buildAttachedFilePreview(
                                  chatInputState,
                                ),
                              ),
                            ),
                            const SizedBox(height: ChatoraiSpacing.xs),
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
                                borderRadius: BorderRadius.circular(
                                  ChatoraiBorderRadius.md,
                                ),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? ChatoraiColors.inputContainerBorderDark
                                      : ChatoraiColors
                                            .inputContainerBorderLight,
                                  width: ChatoraiBorderWidth.thinBold,
                                ),
                              ),
                              child: textField,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ChatoraiSpacing.md),
                    if (widget.isStreaming)
                      buildStopButton(context, ref)
                    else
                      buildActionButton(
                        gradient:
                            _textController.text.trim().isEmpty &&
                                chatInputState.attachedFilePath == null &&
                                chatInputState.speechUiState ==
                                    SpeechUiState.idle
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
                                chatInputState.attachedFilePath == null &&
                                chatInputState.speechUiState ==
                                    SpeechUiState.idle
                            ? (theme.brightness == Brightness.dark
                                  ? ChatoraiColors.inputContainerDark
                                  : ChatoraiColors.inputContainerLight)
                            : null,
                        onTap:
                            _textController.text.trim().isEmpty &&
                                chatInputState.attachedFilePath == null
                            ? _handleMicrophoneAction
                            : _sendMessage,
                        child: Icon(
                          _getActionIcon(chatInputState),
                          color: _getActionColor(theme, chatInputState),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
