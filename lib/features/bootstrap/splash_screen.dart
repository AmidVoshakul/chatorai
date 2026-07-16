import 'package:chatorai/features/bootstrap/splash_visual.dart';
import 'package:chatorai/features/chat/presentation/widgets/chat_shimmer_text.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Брендированный splash-экран, показываемый пока [appBootstrapProvider]
/// выполняет инициализацию за первым кадром.
///
/// Чёрный фон + анимированное название «ChatORAI» (горизонтальный shimmer-блик)
/// и лёгкое «дышащее» радиальное сияние за текстом. Картинка-логотип
/// намеренно убрана — исходный ассет был залитым квадратом. Версия приложения
/// выводится внизу экрана (парсится из pubspec через [PackageInfo]).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _entranceScale;

  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  String _version = '';

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutExpo),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _glowOpacity = Tween<double>(begin: 0.10, end: 0.22).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion) {
      // Уважение настройки «уменьшить движение» — показываем статичный вид.
      _entranceController.value = 1.0;
    } else {
      _entranceController.forward();
      _glowController.repeat(reverse: true);
    }

    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = info.version.split('+').first);
      }
    } catch (_) {
      // Версия недоступна (например, в тестах без платформы) — не показываем.
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appName = AppLocalizations.of(context)?.appName ?? 'ChatORAI';
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Текст/шиммер: белый в тёмной теме, чёрный в светлой.
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: ChatoraiColors.pureBlack,
      body: Column(
        children: [
          // Сияние + название, отцентрированные по вертикали и горизонтали.
          Expanded(
            child: SplashVisual(
              title: FadeTransition(
                opacity: _entranceOpacity,
                child: ScaleTransition(
                  scale: _entranceScale,
                  child: ChatShimmerText(
                    text: appName,
                    textSize: 34,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    duration: const Duration(milliseconds: 1600),
                  ),
                ),
              ),
              textColor: textColor,
              glowOpacity: _glowOpacity,
              vignetteOpacity: 0.55,
              // Нейтральное сияние без брендового оранжевого.
              glowColor: isDark
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFBDBDBD),
            ),
          ),
          // Версия приложения — по центру и прижата к низу экрана.
          if (_version.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '${localizations?.versionLabel ?? 'Version:'} $_version',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
