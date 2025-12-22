import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gen_ui_chat_ai/screens/chat_screen.dart';
import 'package:gen_ui_chat_ai/screens/settings_screen.dart';
import 'package:gen_ui_chat_ai/providers/theme_provider.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

void main() {
  // Initialize logger
  LogConfig.enabled = true;
  LogConfig.minimumLevel = LogLevel.debug;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.getTheme();
        final locale = Locale(themeProvider.selectedLanguage);

        // Determine navigation bar colors based on theme
        final isDark = theme.brightness == Brightness.dark;
        final navBarColor = isDark
            ? UbuntuColors.navBarBackgroundDark
            : UbuntuColors.navBarBackgroundLight;
        final navBarIconBrightness = isDark ? Brightness.light : Brightness.dark;

        return MaterialApp(
          title: 'ORAI',
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
          ],
          locale: locale,
          theme: theme,
          debugShowCheckedModeBanner: false,
          home: const ChatScreen(),
          routes: {
            '/settings': (context) => const SettingsScreen(),
          },
          builder: (context, child) {
            // Set system navigation bar color after theme is applied
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  systemNavigationBarColor: navBarColor,
                  systemNavigationBarIconBrightness: navBarIconBrightness,
                  // Add a subtle border line above the navigation bar
                  systemNavigationBarContrastEnforced: true,
                ),
              );
            });
            return child!;
          },
        );
      },
    );
  }
}
