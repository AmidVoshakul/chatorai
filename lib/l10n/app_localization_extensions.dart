import 'package:flutter/widgets.dart';
import 'app_localizations.dart';
import 'app_localizations_en.dart';

/// Extension on BuildContext for safe access to AppLocalizations
/// Provides a fallback to English if the current locale is not supported
extension LocalizationExtension on BuildContext {
  /// Get AppLocalizations with fallback to English
  /// Usage: context.l.deleteChat
  AppLocalizations get l {
    final loc = AppLocalizations.of(this);
    if (loc == null) {
      // Fallback to English - always available
      return AppLocalizationsEn();
    }
    return loc;
  }
}
