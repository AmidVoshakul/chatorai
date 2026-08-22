import 'package:chatorai/core/permission/rule.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Validates and sanitizes a raw action string to a canonical [PermissionAction]
/// name, falling back to [PermissionAction.ask] for unknown values.
String sanitizeAction(String? raw) {
  if (raw == null) return PermissionAction.ask.name;
  final allowed = PermissionAction.values.map((e) => e.name).toSet();
  return allowed.contains(raw) ? raw : PermissionAction.ask.name;
}

/// Maps a canonical action name to its semantic color, or `null` when the
/// action is unknown (caller should supply a fallback).
Color? sanitizeActionColor(String? action) {
  if (action == null) return null;
  switch (action) {
    case 'allow':
      return ChatoraiColors.success;
    case 'ask':
      return ChatoraiColors.warning;
    case 'deny':
      return ChatoraiColors.error;
    default:
      return null;
  }
}
