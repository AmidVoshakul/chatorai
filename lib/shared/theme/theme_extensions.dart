import 'package:flutter/material.dart';

extension ColorSchemeX on ColorScheme {
  Color get muted => onSurface.withValues(alpha: 0.4);
  Color get dim => onSurface.withValues(alpha: 0.7);
}
