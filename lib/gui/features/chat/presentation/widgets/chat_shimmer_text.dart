import 'package:chatorai/gui/shared/theme/app_theme.dart';
import 'package:chatorai/gui/shared/widgets/shimmer_mask.dart';
import 'package:flutter/material.dart';

// ===========================================================================
// CHAT SHIMMER TEXT — shared shimmer mask with a configurable weight/text.
// The animation itself is delegated to [ShimmerMask] so the effect stays
// identical across the app (same gradient, stops, repeat cadence).
// ===========================================================================

class ChatShimmerText extends StatelessWidget {
  final String text;
  final double? textSize;
  final Color? color;
  final FontWeight fontWeight;
  final Duration duration;

  const ChatShimmerText({
    super.key,
    required this.text,
    this.textSize,
    this.color,
    this.fontWeight = FontWeight.w500,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerMask(
      duration: duration,
      baseColor: color,
      child: Text(
        text,
        style: TextStyle(
          fontSize: textSize ?? ChatoraiFontSizes.md,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
