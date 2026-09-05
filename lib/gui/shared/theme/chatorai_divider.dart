import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
