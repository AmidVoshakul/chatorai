import 'package:flutter/material.dart';
import 'package:chatorai/themes/app_theme.dart';

/// A styled divider used throughout the ChatORAI application.
class ChatoraiDivider extends StatelessWidget {
  const ChatoraiDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? ChatoraiColors.darkInputBorder
          : ChatoraiColors.inputBorder,
    );
  }
}
