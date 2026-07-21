import 'package:flutter/material.dart';

const additionColor = Color(0xFF22C55E);
const removalColor = Color(0xFFEF4444);

extension ColorSchemeX on ColorScheme {
  Color get muted => onSurface.withValues(alpha: 0.4);
  Color get dim => onSurface.withValues(alpha: 0.7);

  Color get diffAddedBg => additionColor.withValues(alpha: 0.15);

  Color get diffRemovedBg => removalColor.withValues(alpha: 0.12);

  Color get diffAddedNumberBg =>
      additionColor.withValues(alpha: 0.25);

  Color get diffRemovedNumberBg =>
      removalColor.withValues(alpha: 0.20);

  Color get diffLineNumberFg => muted;
}
