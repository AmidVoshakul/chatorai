import 'package:flutter/material.dart';

import 'package:chatorai/shared/theme/design_tokens/colors.dart';

/// Box shadow definitions for light and dark themes.
abstract class ChatoraiShadows {
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: ChatoraiColors.black10,
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lightFooterShadow => [
    BoxShadow(
      color: ChatoraiColors.black15,
      blurRadius: 8,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: ChatoraiColors.pureBlack.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get darkFooterShadow => [
    BoxShadow(
      color: ChatoraiColors.pureBlack.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: ChatoraiColors.black10,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get popupShadow => [
    BoxShadow(
      color: ChatoraiColors.black20,
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
