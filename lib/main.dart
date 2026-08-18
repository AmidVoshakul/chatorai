import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:chatorai/core/cli/cwd_override.dart';
import 'package:chatorai/core/cli/cli_commands.dart';
import 'package:chatorai/features/bootstrap/app_loading_screen.dart';
import 'package:chatorai/features/bootstrap/bootstrap_error_screen.dart';
import 'package:chatorai/core/keyboard/global_shortcut_handler.dart';
import 'package:chatorai/features/chat/presentation/screens/chat_screen.dart';
import 'package:chatorai/features/chat/presentation/widgets/permission_overlay.dart';
import 'package:chatorai/features/settings/screens/settings_screen.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/shared/widgets/network_aware_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// MAIN ENTRY POINT
// ===========================================================================

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main(List<String> args) async {
  final cwdResult = detectCwdOverride(args);

  Future<void> run() async {
    if (await runCliIfRequested(cwdResult.remainingArgs)) exit(0);

    WidgetsFlutterBinding.ensureInitialized();

    LogConfig.enabled = true;
    LogConfig.minimumLevel = LogLevel.debug;

    final platformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, estack) {
      if (error is DioException) {
        LogTags.chatService.logDebug(
          '[Global] swallowed DioException (handled by _retry)',
        );
        return true;
      }
      if (error is TimeoutException) {
        LogTags.chatService.logDebug(
          '[Global] swallowed TimeoutException (handled by _retry)',
        );
        return true;
      }
      return platformHandler?.call(error, estack) ?? false;
    };

    runApp(const ProviderScope(child: ChatoraiApp()));
  }

  if (cwdResult.hasOverride) {
    IOOverrides.runZoned(
      run,
      getCurrentDirectory: () => Directory(cwdResult.path!),
    );
  } else {
    await run();
  }
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
    final bootstrap = ref.watch(appBootstrapFastProvider);
    final theme = themeState.getTheme();
    final locale = Locale(languageState.selectedLanguage);

    final isDark = theme.brightness == Brightness.dark;
    final navBarColor = isDark
        ? ChatoraiColors.navBarBackgroundDark
        : ChatoraiColors.navBarBackgroundLight;
    final navBarIconBrightness = isDark ? Brightness.light : Brightness.dark;

    return MaterialApp(
      title: 'ChatORAI',
      navigatorKey: _navigatorKey,
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
      home: bootstrap.when(
        loading: () => const AppLoadingScreen(),
        error: (e, _) => const BootstrapErrorScreen(),
        data: (_) => const PermissionOverlay(
          child: NetworkAwareWidget(child: ChatScreen()),
        ),
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
            child: GlobalShortcutHandler(
              navigatorKey: _navigatorKey,
              child: child!,
            ),
          );
        }

        return GlobalShortcutHandler(
          navigatorKey: _navigatorKey,
          child: child!,
        );
      },
    );
  }
}
