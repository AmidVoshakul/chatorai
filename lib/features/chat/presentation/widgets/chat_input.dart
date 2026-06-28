import 'dart:async';
import 'dart:io' show Platform;

import 'package:chatorai/features/chat/presentation/widgets/chat_input/agent_mention_handler.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/attachment_input_handler.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/input_layout_builder.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/input_widget_builders.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/popup_controller.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/send_message_handler.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/slash_command_handler.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_input/speech_input_handler.dart';
import 'package:chatorai/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chatorai/features/chat/presentation/widgets/chat_input/message_data.dart';

class ChatInput extends ConsumerStatefulWidget {
  final Function(MessageData) onSendMessage;
  final Function(bool) onToggleStreaming;
  final VoidCallback? onStopStreaming;
  final bool isStreaming;
  final FocusNode? focusNode;
  final Function(SpeechUiState, String)? onSpeechStateChanged;
  final bool Function(String)? checkModelSupportsImages;
  final Function(double)? onSoundLevelChanged;
  final Function(String)? onRecognizedText;
  final VoidCallback? onMessageAdded;

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
    this.onRecognizedText,
    this.onMessageAdded,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput>
    with
        AutomaticKeepAliveClientMixin,
        AgentMentionHandler,
        SlashCommandHandler,
        SpeechInputHandler,
        AttachmentInputHandler,
        SendMessageHandler {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _textFieldKey = GlobalKey(); // for popup positioning
  Timer? _plusTimer;
  final GlobalKey _plusKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _agentKey = GlobalKey();
  late final ChatInputPopupController _popupController;
  // Scroll controllers for popups
  final ScrollController _commandScrollController = ScrollController();
  final ScrollController _skillsScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  TextEditingController get textController => _textController;

  @override
  PopupController get popupController => _popupController;

  @override
  VoidCallback? get onMessageAdded => widget.onMessageAdded;

  @override
  bool Function(String)? get checkModelSupportsImages =>
      widget.checkModelSupportsImages;

  @override
  void Function(SpeechUiState, String)? get onSpeechStateChanged =>
      widget.onSpeechStateChanged;

  @override
  void Function(double)? get onSoundLevelChanged => widget.onSoundLevelChanged;

  @override
  Function(String)? get onRecognizedText => widget.onRecognizedText;

  @override
  GlobalKey get textFieldKey => _textFieldKey;

  @override
  ScrollController get commandScrollController => _commandScrollController;

  @override
  ScrollController get skillsScrollController => _skillsScrollController;

  @override
  void initState() {
    super.initState();
    updateKeepAlive();
    _popupController = ChatInputPopupController();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
    detectAgentMentionListener();
    detectSlashCommandListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (speechService == null) {
      initSpeechService();
    }
  }

  @override
  void dispose() {
    _commandScrollController.dispose();
    _skillsScrollController.dispose();
    _popupController.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _plusTimer?.cancel();
    disposeSpeechService();
    super.dispose();
  }

  Future<void> _showPlusMenu(BuildContext context) async {
    ref.read(chatInputProvider.notifier).setPlusActive(true);
    final RenderBox? box =
        _plusKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localizations = AppLocalizations.of(context)!;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final menuItems = <PopupMenuEntry<String>>[
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
      await handleCamera();
    } else if (selected == 'add_image') {
      await handleImage();
    } else if (selected == 'add_file') {
      await handleFile();
    }
    ref.read(chatInputProvider.notifier).setPlusActive(false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile = InputWidgetBuilders.isMobileLayout(context);
    final maxLines = InputWidgetBuilders.computeMaxLines(context);
    final chatInputState = ref.watch(chatInputProvider);
    const double buttonSize = 44.0;
    const double iconSize = ChatoraiIconSizes.buttonIcon;
    const double sidePadding = ChatoraiSpacing.lg;
    const double bottomPadding = ChatoraiSpacing.md;

    final keyboardBindings = <ShortcutActivator, VoidCallback>{
      // Tab: navigate agent, command, or skills popup
      SingleActivator(LogicalKeyboardKey.tab): () {
        if (isAgentPopupVisible) {
          navigateAgentPopup(true);
        } else if (isCommandPopupVisible) {
          navigateCommandPopup(true);
        } else if (isSkillsPopupVisible) {
          navigateSkillsPopup(true);
        }
      },
      SingleActivator(LogicalKeyboardKey.tab, shift: true): () {
        if (isAgentPopupVisible) {
          navigateAgentPopup(false);
        } else if (isCommandPopupVisible) {
          navigateCommandPopup(false);
        } else if (isSkillsPopupVisible) {
          navigateSkillsPopup(false);
        }
      },
      // Enter: select from any popup or send message
      SingleActivator(LogicalKeyboardKey.enter): () {
        if (isAgentPopupVisible) {
          selectCurrentAgent();
        } else if (isCommandPopupVisible) {
          selectCurrentCommand();
        } else if (isSkillsPopupVisible) {
          selectCurrentSkillFromPopup();
        } else if (!HardwareKeyboard.instance.isShiftPressed) {
          performSend(
            onSendMessage: widget.onSendMessage,
            onToggleStreaming: widget.onToggleStreaming,
            onClearAttachedFile: clearAttachedFile,
          );
        }
      },
      // Escape: close any popup
      SingleActivator(LogicalKeyboardKey.escape): () {
        if (isAgentPopupVisible) {
          hideAgentPopup();
        } else if (isCommandPopupVisible) {
          hideCommandPopup();
        } else if (isSkillsPopupVisible) {
          hideSkillsPopup();
        }
      },
      // Arrow keys: navigate popups
      SingleActivator(LogicalKeyboardKey.arrowDown): () {
        if (isAgentPopupVisible) {
          navigateAgentPopup(true);
        } else if (isCommandPopupVisible) {
          navigateCommandPopup(true);
        } else if (isSkillsPopupVisible) {
          navigateSkillsPopup(true);
        }
      },
      SingleActivator(LogicalKeyboardKey.arrowUp): () {
        if (isAgentPopupVisible) {
          navigateAgentPopup(false);
        } else if (isCommandPopupVisible) {
          navigateCommandPopup(false);
        } else if (isSkillsPopupVisible) {
          navigateSkillsPopup(false);
        }
      },
    };

    final textField = InputWidgetBuilders.buildTextField(
      key: _textFieldKey,
      controller: _textController,
      focusNode: widget.focusNode,
      maxLines: maxLines,
      isMobile: isMobile,
      enabled: !chatInputState.isSending,
      theme: theme,
      localizations: localizations,
      hintText: localizations.typeYourMessage,
      keyboardBindings: keyboardBindings,
    );

    final hasText = _textController.text.trim().isNotEmpty;
    final hasAttachment = chatInputState.attachedFilePath != null;
    final currentAgent = ref.watch(currentAgentProvider);

    final layoutChild = isMobile
        ? InputLayoutBuilder.buildMobileLayout(
            context: context,
            theme: theme,
            chatInputState: chatInputState,
            textField: textField,
            isMobile: isMobile,
            hasText: hasText,
            hasAttachment: hasAttachment,
            buttonSize: buttonSize,
            iconSize: iconSize,
            sidePadding: sidePadding,
            bottomPadding: bottomPadding,
            onClearAttachedFile: clearAttachedFile,
            onPlusMenu: () => _showPlusMenu(context),
            onModelSettings: handleModelSettings,
            onAgentSwitcher: () => showAgentSwitcher(context, _agentKey),
            onMicrophoneAction: handleMicrophoneAction,
            onSend: () => performSend(
              onSendMessage: widget.onSendMessage,
              onToggleStreaming: widget.onToggleStreaming,
              onClearAttachedFile: clearAttachedFile,
            ),
            onStopStreaming: widget.onStopStreaming,
            onLongPressMic: handleMicrophoneAction,
            ref: ref,
            plusKey: _plusKey,
            settingsKey: _settingsKey,
            agentKey: _agentKey,
            isStreaming: widget.isStreaming,
            currentAgent: currentAgent,
          )
        : InputLayoutBuilder.buildDesktopLayout(
            context: context,
            theme: theme,
            chatInputState: chatInputState,
            textField: textField,
            isMobile: isMobile,
            hasText: hasText,
            hasAttachment: hasAttachment,
            buttonSize: buttonSize,
            iconSize: iconSize,
            onClearAttachedFile: clearAttachedFile,
            onPlusMenu: () => _showPlusMenu(context),
            onModelSettings: handleModelSettings,
            onAgentSwitcher: () => showAgentSwitcher(context, _agentKey),
            onMicrophoneAction: handleMicrophoneAction,
            onSend: () => performSend(
              onSendMessage: widget.onSendMessage,
              onToggleStreaming: widget.onToggleStreaming,
              onClearAttachedFile: clearAttachedFile,
            ),
            onStopStreaming: widget.onStopStreaming,
            onLongPressMic: handleMicrophoneAction,
            ref: ref,
            plusKey: _plusKey,
            settingsKey: _settingsKey,
            agentKey: _agentKey,
            isStreaming: widget.isStreaming,
            currentAgent: currentAgent,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final messageAsync = ref.watch(retryMessageProvider);
            final countdownAsync = ref.watch(retryCountdownProvider);
            final message = messageAsync.hasValue ? messageAsync.value : null;
            final progress = countdownAsync.hasValue ? countdownAsync.value : null;
            final isRetrying = progress != null && progress > 0 && progress <= 1;
            if (message == null || message.isEmpty || !isRetrying) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: ChatoraiSpacing.md,
                  bottom: ChatoraiSpacing.xs,
                ),
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ChatoraiColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
        Stack(
          children: [
            InputLayoutBuilder.buildContainer(
              isMobile: isMobile,
              theme: theme,
              child: layoutChild,
            ),
          ],
        ),
      ],
    );
  }
}
