import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Lightweight loading screen shown in the `loading` branch [appBootstrapFastProvider].
///
/// On mobile it is instantly covered by the native splash
/// (`flutter_native_splash`, same black background + “ChatORAI”), so
/// flickering is not visible. There is no native layer on the desktop/web - that’s what it is
/// loading screen. Same brand as the native layer to transition
/// to the chat was seamless.
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ChatoraiColors.pureBlack,
      child: Center(
        child: Image(
          image: AssetImage('assets/splash/chatorai_wordmark.png'),
          width: 260,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
