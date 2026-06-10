import 'package:chatorai/features/chat/presentation/screens/chat_screen.dart';
import 'package:chatorai/features/chat/presentation/widgets/permission_overlay.dart';
import 'package:chatorai/features/settings/presentation/screens/settings_screen.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/widgets/network_aware_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// MAIN ENTRY POINT
// ===========================================================================

void main() {
  LogConfig.enabled = true;
  LogConfig.minimumLevel = LogLevel.debug;

  runApp(const ProviderScope(child: ChatoraiApp()));
}

// ===========================================================================
// CHATORAI APP WIDGET
// ===========================================================================

class ChatoraiApp extends ConsumerWidget {
  const ChatoraiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final themeState = ref.watch(themeProvider);
    final theme = themeState.getTheme();
    final locale = Locale(languageState.selectedLanguage);

    final isDark = theme.brightness == Brightness.dark;
    final navBarColor = isDark
        ? ChatoraiColors.navBarBackgroundDark
        : ChatoraiColors.navBarBackgroundLight;
    final navBarIconBrightness = isDark ? Brightness.light : Brightness.dark;

    return MaterialApp(
      title: 'ChatORAI',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('uk'),
        Locale('zh'),
        Locale('ja'),
        Locale('ar'),
      ],
      locale: locale,
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const PermissionOverlay(
        child: NetworkAwareWidget(child: ChatScreen()),
      ),
      routes: {'/settings': (context) => const SettingsScreen()},
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              systemNavigationBarColor: navBarColor,
              systemNavigationBarIconBrightness: navBarIconBrightness,
              systemNavigationBarContrastEnforced: true,
            ),
          );
        });

        if (languageState.isRTL) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        }

        return child!;
      },
    );
  }
}
