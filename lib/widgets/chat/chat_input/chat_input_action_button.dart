import 'package:flutter/material.dart';

class ChatInputActionButton extends StatelessWidget {
  final Key? buttonKey;
  final Widget child;
  final Gradient? gradient;
  final Color? bgColor;
  final VoidCallback? onTap;
  final double size;

  const ChatInputActionButton({
    super.key,
    this.buttonKey,
    required this.child,
    this.gradient,
    this.bgColor,
    this.onTap,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: buttonKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? bgColor : null,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
