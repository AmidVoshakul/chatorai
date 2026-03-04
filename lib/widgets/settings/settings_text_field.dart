import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';

class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final VoidCallback? onCopy;
  final bool obscureText;

  const SettingsTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.onCopy,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark
                ? UbuntuColors.darkInputBorder
                : UbuntuColors.inputBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: UbuntuColors.orange, width: 2),
        ),
        suffixIcon: onCopy != null
            ? IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: onCopy,
              )
            : null,
      ),
      maxLines: 1,
    );
  }
}
