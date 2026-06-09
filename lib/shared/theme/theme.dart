// Shared theme — barrel export
// Design tokens (source of truth for theme primitives)
export 'design_tokens/colors.dart';
export 'design_tokens/typography.dart';
export 'design_tokens/spacing.dart';
export 'design_tokens/sizes.dart';
export 'design_tokens/borders.dart';
export 'design_tokens/shadows.dart';
export 'design_tokens/icons.dart';
export 'design_tokens/theme_builders.dart';
// Note: app_theme.dart is NOT re-exported here because it defines duplicate
// class names (ChatoraiColors, etc.) that conflict with design_tokens.
// Import app_theme.dart directly when needed.
export 'markdown_styles.dart';
