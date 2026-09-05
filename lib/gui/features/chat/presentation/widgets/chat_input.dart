import 'dart:async';
import 'dart:io' show Platform;

import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/agent_highlight_controller.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/agent_mention_handler.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/attachment_input_handler.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/input_layout_builder.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/input_widget_builders.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/message_data.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/popup_controller.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/send_message_handler.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/slash_command_handler.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/speech_input_handler.dart';
import 'package:chatorai/gui/features/chat/presentation/widgets/chat_input_status_bar.dart';
import 'package:chatorai/gui/features/chat/services/speech_to_text_service.dart';
import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chatorai/gui/features/chat/presentation/widgets/chat_input/message_data.dart';

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
  final VoidCallback? onOpenModelSettings;
  final Future<void> Function()? onCompact;
  final ValueChanged<bool>? onPopupVisibilityChanged;

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
    this.onOpenModelSettings,
    this.onCompact,
    this.onPopupVisibilityChanged,
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
  final AgentHighlightController _textController = AgentHighlightController();
  final GlobalKey _textFieldKey = GlobalKey(); // for popup positioning
  Timer? _plusTimer;
  bool _hasText = false;
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
  bool Function(String)? get checkModelSupportsImages =>
      widget.checkModelSupportsImages;

  @override
  VoidCallback? get onOpenModelSettings => widget.onOpenModelSettings;

  @override
  Future<void> Function()? get onCompact => widget.onCompact;

  @override
  ValueChanged<bool>? get onPopupVisibilityChanged =>
      widget.onPopupVisibilityChanged;

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

  bool get _hasNonEmptyText => _textController.text.trim().isNotEmpty;

  void _onTextChanged() {
    final hasText = _hasNonEmptyText;
    if (hasText != _hasText) {
      _hasText = hasText;
      if (mounted) setState(() {});
    }
    detectAgentMentionListener();
    detectSlashCommandListener();
  }

  @override
  Future<ResolvedText?> resolveText(String text) async {
    final result = await resolveSkillCommand(text);
    if (result != null) {
      if (result.content.startsWith('**Loaded skill:**')) {
        // No args → insert skill content into chat without AI response
        await insertSkillMessage(result.skill, result.content);
        return null;
      }
      // Has args → send rendered content as user message, AI responds
      return ResolvedText(text: result.content);
    }
    return super.resolveText(text);
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
    final isMobile = Platform.isAndroid || Platform.isIOS;
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
    listenForSkillChanges();
    listenForCustomCommands();
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final isMobile = InputWidgetBuilders.isMobileLayout(context);
    final maxLines = InputWidgetBuilders.computeMaxLines(context);
    final chatInputState = ref.watch(chatInputProvider);
    const double buttonSize = 44.0;
    const double iconSize = ChatoraiIconSizes.buttonIcon;
    const double sidePadding = ChatoraiSpacing.lg;
    const double bottomPadding = ChatoraiSpacing.xs;

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

    final textField = Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          if (isAgentPopupVisible) {
            hideAgentPopup();
            return KeyEventResult.handled;
          }
          if (isCommandPopupVisible) {
            hideCommandPopup();
            return KeyEventResult.handled;
          }
          if (isSkillsPopupVisible) {
            hideSkillsPopup();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        return KeyEventResult.ignored;
      },
      child: InputWidgetBuilders.buildTextField(
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
      ),
    );

    final hasText = _hasNonEmptyText;
    final hasAttachment = chatInputState.attachedFilePath != null;
    final currentAgent = ref.watch(currentAgentProvider);

    final layoutConfig = ChatInputLayoutConfig(
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
    );

    final layoutChild = isMobile
        ? InputLayoutBuilder.buildMobileLayout(config: layoutConfig)
        : InputLayoutBuilder.buildDesktopLayout(config: layoutConfig);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final messageAsync = ref.watch(retryMessageProvider);
            final countdownAsync = ref.watch(retryCountdownProvider);
            final message = messageAsync.hasValue ? messageAsync.value : null;
            final progress = countdownAsync.hasValue
                ? countdownAsync.value
                : null;
            final isRetrying =
                progress != null && progress > 0 && progress <= 1;
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
              // На мобильном layout статус-бар живёт внутри того же
              // контейнера, что и поле ввода — единый фон, без видимого шва.
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        layoutChild,
                        ChatInputStatusBar(onCompact: widget.onCompact),
                      ],
                    )
                  : layoutChild,
            ),
          ],
        ),
        // На desktop — статус-бар снаружи (фон прозрачный, как и контейнер).
        if (!isMobile) ChatInputStatusBar(onCompact: widget.onCompact),
      ],
    );
  }
}
