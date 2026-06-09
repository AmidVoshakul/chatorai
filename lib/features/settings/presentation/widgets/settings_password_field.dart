import 'package:flutter/material.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

// ===========================================================================
// SETTINGS PASSWORD FIELD WIDGET
// ===========================================================================

class SettingsPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final VoidCallback? onCopy;
  final String? validationError;
  final ValueChanged<bool>? onVisibilityChanged;

  const SettingsPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.onCopy,
    this.validationError,
    this.onVisibilityChanged,
  });

  @override
  State<SettingsPasswordField> createState() => _SettingsPasswordFieldState();
}

class _SettingsPasswordFieldState extends State<SettingsPasswordField> {
  bool _obscureText = true;

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
    widget.onVisibilityChanged?.call(_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
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
        errorText: widget.validationError,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onCopy != null)
              IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: widget.onCopy,
              ),
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: _toggleObscureText,
            ),
          ],
        ),
      ),
      maxLines: 1,
    );
  }
}
