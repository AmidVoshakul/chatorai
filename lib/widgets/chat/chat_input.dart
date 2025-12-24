import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
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
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isSending = false;
  bool _plusActive = false;
  Timer? _plusTimer;

  final GlobalKey _plusKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Restore text from controller if it was preserved
    updateKeepAlive();
  }

  @override
  void dispose() {
    _textController.dispose();
    _plusTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSpeechToText() async {
    if (!_speechToText.isAvailable) {
      await _speechToText.initialize();
    }

    if (_speechToText.isListening) {
      await _speechToText.cancel();
      return;
    }

    setState(() => _isListening = true);

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
          _isListening = false;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    _textController.clear();
    widget.onSendMessage(message);
    widget.onToggleStreaming(true);

    setState(() => _isSending = false);
  }

  void _handleStopStreaming() {
    if (widget.onStopStreaming != null) {
      widget.onStopStreaming!();
    }
  }

  Future<void> _showPlusMenu(BuildContext context) async {
    setState(() => _plusActive = true);

    final RenderBox? box =
        _plusKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final localizations = AppLocalizations.of(context)!;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 80,
        offset.dx + size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          value: 'add_image',
          child: Row(
            children: [
              Icon(Icons.image, size: 20),
              SizedBox(width: 8),
              Text(localizations.addImageToFile),
            ],
          ),
        ),
      ],
    );

    if (selected == 'add_image') {
      // TODO
    }

    setState(() => _plusActive = false);
  }

  int _computeMaxLines(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.4;
    return (maxHeight / 24).floor().clamp(1, 12);
  }

  bool _isMobileLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

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
              hintText: localizations.typeYourMessage,
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
              children: [
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
                const SizedBox(height: 4),
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
                          gradient: _textController.text.trim().isEmpty
                              ? null
                              : LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                          bgColor: _textController.text.trim().isEmpty
                              ? (theme.brightness == Brightness.dark
                                  ? UbuntuColors.inputContainerDark
                                  : UbuntuColors.inputContainerLight)
                              : null,
                          onTap: _textController.text.trim().isEmpty
                              ? _startSpeechToText
                              : _sendMessage,
                          child: Icon(
                            _textController.text.trim().isEmpty
                                ? (_isListening ? Icons.stop : Icons.mic)
                                : (_isSending ? Icons.autorenew : Icons.send),
                            size: iconSize,
                            color: _textController.text.trim().isEmpty
                                ? theme.iconTheme.color
                                : Colors.white,
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
                  child: ConstrainedBox(
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
                    gradient: _textController.text.trim().isEmpty
                        ? null
                        : LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                    bgColor: _textController.text.trim().isEmpty
                        ? (theme.brightness == Brightness.dark
                            ? UbuntuColors.inputContainerDark
                            : UbuntuColors.inputContainerLight)
                        : null,
                    onTap: _textController.text.trim().isEmpty
                        ? _startSpeechToText
                        : _sendMessage,
                    child: Icon(
                      _textController.text.trim().isEmpty
                          ? (_isListening ? Icons.stop : Icons.mic)
                          : Icons.send,
                      color: _textController.text.trim().isEmpty
                          ? theme.iconTheme.color
                          : Colors.white,
                    ),
                  ),
              ],
            ),
    );
  }
}
