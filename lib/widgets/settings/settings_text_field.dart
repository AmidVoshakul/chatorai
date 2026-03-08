import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';

// ===========================================================================
// SETTINGS TEXT FIELD WIDGET
// ===========================================================================

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

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: isDark
            ? ChatoraiColors.darkInputFill
            : ChatoraiColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          borderSide: BorderSide(
            color: isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          borderSide: BorderSide(
            color: isDark
                ? ChatoraiColors.darkInputBorder
                : ChatoraiColors.inputBorder,
            width: ChatoraiBorderWidth.thinBold,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
          borderSide: BorderSide(
            color: ChatoraiColors.orange,
            width: ChatoraiBorderWidth.medium,
          ),
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
