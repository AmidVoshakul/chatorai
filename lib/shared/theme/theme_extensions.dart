import 'package:flutter/material.dart';

const additionColor = Color(0xFF22C55E);
const removalColor = Color(0xFFEF4444);

const diffBgColor = Color(0xFF000000);

const diffMarkerWidth = 16.0;

extension ColorSchemeX on ColorScheme {
  Color get muted => onSurface.withValues(alpha: 0.4);
  Color get dim => onSurface.withValues(alpha: 0.7);

  Color get diffAddedBg => additionColor.withValues(alpha: 0.15);

  Color get diffRemovedBg => removalColor.withValues(alpha: 0.12);

  Color get diffLineNumberFg => muted;
}
