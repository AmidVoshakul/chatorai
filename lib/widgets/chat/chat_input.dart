import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool) onToggleStreaming;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onToggleStreaming,
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

    await Future.delayed(const Duration(seconds: 2));
    widget.onToggleStreaming(false);
  }

  Future<void> _showPlusMenu() async {
    setState(() => _plusActive = true);

    final RenderBox? box =
        _plusKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

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
      items: const [
        PopupMenuItem(
          value: 'add_image',
          child: Row(
            children: [
              Icon(Icons.image, size: 20),
              SizedBox(width: 8),
              Text('+ add image to file'),
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
              hintText: 'Type your message...',
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
              hintText: 'Type your message...',
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
      textInputAction: isMobile ? TextInputAction.send : null,
      onChanged: (text) => setState(() {}),
      onEditingComplete: isMobile ? _sendMessage : null,
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
        color: isMobile ? const Color(0xFF1A1A1A) : Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: isMobile
            ? const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                      color: const Color(0xFF1A1A1A),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: textField,
                  ),
                ),
                const SizedBox(height: 8),
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
                            : const Color(0xFF1A1A1A),
                        onTap: _showPlusMenu,
                        child: Icon(
                          Icons.add,
                          size: iconSize,
                          color: _plusActive
                              ? Colors.white
                              : theme.iconTheme.color,
                        ),
                      ),
                      const Spacer(),
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
                            ? const Color(0xFF1A1A1A)
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
                  bgColor: theme.iconTheme.color?.withValues(alpha: 0.1),
                  onTap: _showPlusMenu,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.iconTheme.color?.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
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
                      ? theme.iconTheme.color?.withValues(alpha: 0.1)
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
