import 'package:flutter/material.dart';

// ===========================================================================
// SLIDING APP BAR CONSTANTS
// ===========================================================================

class SlidingAppBarConstants {
  SlidingAppBarConstants._();

  // =======================================================================
  // SCROLL THRESHOLDS
  // =======================================================================
  static const double hideThreshold = 100.0;
  static const double showThreshold = 50.0;

  // =======================================================================
  // ANIMATION
  // =======================================================================
  static const Duration animationDuration = Duration(milliseconds: 350);
  static const Curve animationCurve = Curves.easeInOutCubic;

  // =======================================================================
  // SIZES
  // =======================================================================
  static const double appBarHeight = 56.0;
  static const double iconSize = 20.0;
  static const double rightPadding = 2.0;

  // =======================================================================
  // MODEL NAME (MOBILE)
  // =======================================================================
  static const double mobileModelNameWidthFactor = 0.45;
  static const double mobileModelNameFontSize = 10.0;

  // =======================================================================
  // MODEL NAME (DESKTOP)
  // =======================================================================
  static const double desktopModelNameFontSize = 12.0;
}
