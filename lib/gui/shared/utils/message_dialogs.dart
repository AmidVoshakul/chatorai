import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardHandlerDialog extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEnter;
  final VoidCallback? onEscape;

  const KeyboardHandlerDialog({
    super.key,
    required this.child,
    this.onEnter,
    this.onEscape,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            onEnter?.call();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            onEscape?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
