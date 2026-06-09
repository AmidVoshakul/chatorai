import 'package:flutter/material.dart';

/// Border radius constants and pre-built Radius objects.
abstract class ChatoraiBorderRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;

  // Radius objects
  static final Radius xsRadius = Radius.circular(xs);
  static final Radius smRadius = Radius.circular(sm);
  static final Radius mdRadius = Radius.circular(md);
  static final Radius lgRadius = Radius.circular(lg);
  static final Radius xlRadius = Radius.circular(xl);
}

/// Border width constants.
abstract class ChatoraiBorderWidth {
  static const double none = 0.0;
  static const double thin = 0.5;
  static const double thinBold = 1.0;
  static const double medium = 2.0;
  static const double thick = 3.0;
  static const double bold = 4.0;
}
