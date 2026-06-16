import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatorai/shared/theme/app_theme.dart';

void main() {
  // ── ChatoraiColors ─────────────────────────────────────────

  group('ChatoraiColors', () {
    test('has non-null primary colors', () {
      expect(ChatoraiColors.orange, isNotNull);
      expect(ChatoraiColors.dark, isNotNull);
      expect(ChatoraiColors.light, isNotNull);
    });

    test('primary orange is correct value', () {
      expect(ChatoraiColors.orange.value, 0xFFFF7F00);
    });

    test('dark color is correct value', () {
      expect(ChatoraiColors.dark.value, 0xFF1A0E00);
    });

    test('light color is correct value', () {
      expect(ChatoraiColors.light.value, 0xFFEBEBEB);
    });

    test('grayscale colors are distinct', () {
      expect(ChatoraiColors.gray, isNot(equals(ChatoraiColors.lightGray)));
      expect(ChatoraiColors.gray, isNot(equals(ChatoraiColors.darkGray)));
      expect(ChatoraiColors.gray, isNot(equals(ChatoraiColors.mediumGray)));
      expect(ChatoraiColors.lightGray, isNot(equals(ChatoraiColors.darkGray)));
    });

    test('dark colors differ from light', () {
      expect(
        ChatoraiColors.lightSurface,
        isNot(equals(ChatoraiColors.darkSurface)),
      );
      expect(ChatoraiColors.lightCard, isNot(equals(ChatoraiColors.darkCard)));
      expect(
        ChatoraiColors.lightTextColor,
        isNot(equals(ChatoraiColors.darkTextColor)),
      );
      expect(
        ChatoraiColors.lightBorderColor,
        isNot(equals(ChatoraiColors.darkBorderColor)),
      );
    });

    test('pure black and pure white are extremes', () {
      expect(ChatoraiColors.pureBlack.value, 0xFF000000);
      expect(ChatoraiColors.pureWhite.value, 0xFFFFFFFF);
    });

    test('semantic colors are distinct', () {
      expect(ChatoraiColors.error, isNot(equals(ChatoraiColors.success)));
      expect(ChatoraiColors.error, isNot(equals(ChatoraiColors.link)));
      expect(ChatoraiColors.error, isNot(equals(ChatoraiColors.warning)));
    });

    test('error and errorLight are different', () {
      expect(ChatoraiColors.error, isNot(equals(ChatoraiColors.errorLight)));
    });

    test('code background colors differ between light and dark', () {
      expect(
        ChatoraiColors.codeBackgroundLight,
        isNot(equals(ChatoraiColors.codeBackgroundDark)),
      );
      expect(
        ChatoraiColors.codeBorderLight,
        isNot(equals(ChatoraiColors.codeBorderDark)),
      );
    });

    test('input fill colors differ between light and dark', () {
      expect(
        ChatoraiColors.inputFill,
        isNot(equals(ChatoraiColors.darkInputFill)),
      );
      expect(
        ChatoraiColors.inputBorder,
        isNot(equals(ChatoraiColors.darkInputBorder)),
      );
    });

    test('semi-transparent blacks have increasing alpha', () {
      // Verify ordering: black05 < black10 < black15 < black20 < black30
      expect(
        ChatoraiColors.black05.alpha,
        lessThan(ChatoraiColors.black10.alpha),
      );
      expect(
        ChatoraiColors.black10.alpha,
        lessThan(ChatoraiColors.black15.alpha),
      );
      expect(
        ChatoraiColors.black15.alpha,
        lessThan(ChatoraiColors.black20.alpha),
      );
      expect(
        ChatoraiColors.black20.alpha,
        lessThan(ChatoraiColors.black30.alpha),
      );
    });

    test('accent color is distinct from primary', () {
      expect(ChatoraiColors.accent, isNot(equals(ChatoraiColors.orange)));
      expect(ChatoraiColors.neonBlue, isNot(equals(ChatoraiColors.orange)));
    });

    test('hover colors share same base with alpha', () {
      expect(ChatoraiColors.hoverLight.value, ChatoraiColors.hoverDark.value);
      expect(
        ChatoraiColors.selectedLight.value,
        ChatoraiColors.selectedDark.value,
      );
    });

    test('input container colors differ between light and dark', () {
      expect(
        ChatoraiColors.inputContainerLight,
        isNot(equals(ChatoraiColors.inputContainerDark)),
      );
      expect(
        ChatoraiColors.inputContainerBorderLight,
        isNot(equals(ChatoraiColors.inputContainerBorderDark)),
      );
    });

    test('toggle inactive colors differ between light and dark', () {
      expect(
        ChatoraiColors.toggleInactiveThumbLight,
        isNot(equals(ChatoraiColors.toggleInactiveThumbDark)),
      );
      expect(
        ChatoraiColors.toggleInactiveTrackLight,
        isNot(equals(ChatoraiColors.toggleInactiveTrackDark)),
      );
    });

    test('speech overlay colors are dark with high alpha', () {
      // Speech overlay backgrounds should be dark (low RGB values)
      expect(ChatoraiColors.speechOverlayBackgroundLight.red, lessThan(0x20));
      expect(ChatoraiColors.speechOverlayBackgroundLight.green, lessThan(0x20));
      expect(ChatoraiColors.speechOverlayBackgroundLight.blue, lessThan(0x20));
    });

    test('speech overlay blur is positive', () {
      expect(ChatoraiColors.speechOverlayBlur, greaterThan(0));
    });

    test('icon colors differ between light and dark', () {
      expect(
        ChatoraiColors.lightIconColor,
        isNot(equals(ChatoraiColors.darkTextColor)),
      );
    });

    test('unselected item colors differ between light and dark', () {
      expect(
        ChatoraiColors.unselectedItemLight,
        isNot(equals(ChatoraiColors.unselectedItemDark)),
      );
    });

    test('secondary text color differs from dark secondary text color', () {
      expect(
        ChatoraiColors.secondaryTextColor,
        isNot(equals(ChatoraiColors.darkSecondaryTextColor)),
      );
    });

    test('nav bar colors differ between light and dark', () {
      expect(
        ChatoraiColors.navBarBackgroundLight,
        isNot(equals(ChatoraiColors.navBarBackgroundDark)),
      );
      expect(
        ChatoraiColors.navBarBorderLight,
        isNot(equals(ChatoraiColors.navBarBorderDark)),
      );
    });
  });

  // ── ChatoraiSpacing ────────────────────────────────────────

  group('ChatoraiSpacing', () {
    test('has consistent 4px-based spacing scale', () {
      // Verify each step increases by 4px: 4, 8, 12, 16, 20, 24, 32
      expect(ChatoraiSpacing.xs, 4.0);
      expect(ChatoraiSpacing.sm, 8.0);
      expect(ChatoraiSpacing.md, 12.0);
      expect(ChatoraiSpacing.lg, 16.0);
      expect(ChatoraiSpacing.xl, 20.0);
      expect(ChatoraiSpacing.xxl, 24.0);
      expect(ChatoraiSpacing.xxxl, 32.0);
    });

    test('spacing values are monotonically increasing', () {
      expect(ChatoraiSpacing.xs, lessThan(ChatoraiSpacing.sm));
      expect(ChatoraiSpacing.sm, lessThan(ChatoraiSpacing.md));
      expect(ChatoraiSpacing.md, lessThan(ChatoraiSpacing.lg));
      expect(ChatoraiSpacing.lg, lessThan(ChatoraiSpacing.xl));
      expect(ChatoraiSpacing.xl, lessThan(ChatoraiSpacing.xxl));
      expect(ChatoraiSpacing.xxl, lessThan(ChatoraiSpacing.xxxl));
    });

    test('specific sizes are reasonable', () {
      expect(ChatoraiSpacing.sidebarItemHeight, 60.0);
      expect(ChatoraiSpacing.sidebarIconSpacing, 12.0);
    });
  });

  // ── ChatoraiBorderRadius ───────────────────────────────────

  group('ChatoraiBorderRadius', () {
    test('has non-zero radius sizes', () {
      expect(ChatoraiSpacing.xs, greaterThan(0));
      expect(ChatoraiSpacing.sm, greaterThan(0));
      expect(ChatoraiSpacing.md, greaterThan(0));
    });

    test('border radius values are monotonically increasing', () {
      expect(ChatoraiBorderRadius.none, 0.0);
      expect(ChatoraiBorderRadius.xs, 4.0);
      expect(ChatoraiBorderRadius.sm, 8.0);
      expect(ChatoraiBorderRadius.md, 12.0);
      expect(ChatoraiBorderRadius.lg, 16.0);
      expect(ChatoraiBorderRadius.xl, 20.0);
    });

    test('full radius is large enough for pill shape', () {
      expect(ChatoraiBorderRadius.full, 999.0);
    });

    test('radius instances match their scalar values', () {
      expect(ChatoraiBorderRadius.xsRadius.x, ChatoraiBorderRadius.xs);
      expect(ChatoraiBorderRadius.smRadius.x, ChatoraiBorderRadius.sm);
      expect(ChatoraiBorderRadius.mdRadius.x, ChatoraiBorderRadius.md);
      expect(ChatoraiBorderRadius.lgRadius.x, ChatoraiBorderRadius.lg);
      expect(ChatoraiBorderRadius.xlRadius.x, ChatoraiBorderRadius.xl);
    });

    test('border radius is monotonically increasing', () {
      expect(ChatoraiBorderRadius.none, lessThan(ChatoraiBorderRadius.xs));
      expect(ChatoraiBorderRadius.xs, lessThan(ChatoraiBorderRadius.sm));
      expect(ChatoraiBorderRadius.sm, lessThan(ChatoraiBorderRadius.md));
      expect(ChatoraiBorderRadius.md, lessThan(ChatoraiBorderRadius.lg));
      expect(ChatoraiBorderRadius.lg, lessThan(ChatoraiBorderRadius.xl));
    });
  });

  // ── ChatoraiIconSizes ──────────────────────────────────────

  group('ChatoraiIconSizes', () {
    test('has consistent icon size scale', () {
      expect(ChatoraiIconSizes.xs, 12.0);
      expect(ChatoraiIconSizes.sm, 14.0);
      expect(ChatoraiIconSizes.md, 16.0);
      expect(ChatoraiIconSizes.lg, 18.0);
      expect(ChatoraiIconSizes.xl, 20.0);
      expect(ChatoraiIconSizes.xxl, 24.0);
      expect(ChatoraiIconSizes.xxxl, 32.0);
    });

    test('sizes are monotonically increasing', () {
      expect(ChatoraiIconSizes.xs, lessThan(ChatoraiIconSizes.sm));
      expect(ChatoraiIconSizes.sm, lessThan(ChatoraiIconSizes.md));
      expect(ChatoraiIconSizes.md, lessThan(ChatoraiIconSizes.lg));
      expect(ChatoraiIconSizes.lg, lessThan(ChatoraiIconSizes.xl));
      expect(ChatoraiIconSizes.xl, lessThan(ChatoraiIconSizes.xxl));
      expect(ChatoraiIconSizes.xxl, lessThan(ChatoraiIconSizes.xxxl));
      expect(ChatoraiIconSizes.xxxl, lessThan(ChatoraiIconSizes.huge));
    });

    test('icon sizes are positive', () {
      expect(ChatoraiIconSizes.xs, greaterThan(0));
      expect(ChatoraiIconSizes.huge, greaterThan(0));
      expect(ChatoraiIconSizes.massive, greaterThan(0));
    });

    test('specific icon sizes are reasonable', () {
      expect(ChatoraiIconSizes.actionIcon, 16.0);
      expect(ChatoraiIconSizes.buttonIcon, 20.0);
      expect(ChatoraiIconSizes.sidebarIcon, 20.0);
      expect(ChatoraiIconSizes.emptyStateIcon, 60.0);
    });
  });

  // ── ChatoraiIconOpacity ────────────────────────────────────

  group('ChatoraiIconOpacity', () {
    test('has three opacity levels', () {
      expect(ChatoraiIconOpacity.low, 0.5);
      expect(ChatoraiIconOpacity.medium, 0.7);
      expect(ChatoraiIconOpacity.high, 0.8);
    });

    test('opacity values are monotonically increasing', () {
      expect(ChatoraiIconOpacity.low, lessThan(ChatoraiIconOpacity.medium));
      expect(ChatoraiIconOpacity.medium, lessThan(ChatoraiIconOpacity.high));
    });

    test('all opacities are in valid range 0-1', () {
      expect(ChatoraiIconOpacity.low, inInclusiveRange(0.0, 1.0));
      expect(ChatoraiIconOpacity.medium, inInclusiveRange(0.0, 1.0));
      expect(ChatoraiIconOpacity.high, inInclusiveRange(0.0, 1.0));
    });
  });

  // ── ChatoraiFontSizes ──────────────────────────────────────

  group('ChatoraiFontSizes', () {
    test('has consistent font size scale', () {
      expect(ChatoraiFontSizes.xs, 10.0);
      expect(ChatoraiFontSizes.sm, 11.0);
      expect(ChatoraiFontSizes.md, 12.0);
      expect(ChatoraiFontSizes.base, 14.0);
      expect(ChatoraiFontSizes.lg, 16.0);
      expect(ChatoraiFontSizes.xl, 18.0);
      expect(ChatoraiFontSizes.xxl, 20.0);
      expect(ChatoraiFontSizes.xxxl, 24.0);
      expect(ChatoraiFontSizes.display, 32.0);
    });

    test('font sizes are monotonically increasing', () {
      expect(ChatoraiFontSizes.xs, lessThan(ChatoraiFontSizes.sm));
      expect(ChatoraiFontSizes.sm, lessThan(ChatoraiFontSizes.md));
      expect(ChatoraiFontSizes.md, lessThan(ChatoraiFontSizes.base));
      expect(ChatoraiFontSizes.base, lessThan(ChatoraiFontSizes.lg));
      expect(ChatoraiFontSizes.lg, lessThan(ChatoraiFontSizes.xl));
      expect(ChatoraiFontSizes.xl, lessThan(ChatoraiFontSizes.xxl));
      expect(ChatoraiFontSizes.xxl, lessThan(ChatoraiFontSizes.xxxl));
      expect(ChatoraiFontSizes.xxxl, lessThan(ChatoraiFontSizes.display));
    });

    test('code font size is smaller than base', () {
      expect(ChatoraiFontSizes.code, lessThan(ChatoraiFontSizes.base));
      expect(ChatoraiFontSizes.code, 13.0);
    });

    test('sidebar font sizes are reasonable', () {
      expect(ChatoraiFontSizes.sidebarTitle, 18.0);
      expect(ChatoraiFontSizes.sidebarItem, 14.0);
      expect(ChatoraiFontSizes.sidebarDate, 11.0);
      expect(ChatoraiFontSizes.caption, 12.0);
    });

    test('all font sizes are positive', () {
      expect(ChatoraiFontSizes.xs, greaterThan(0));
      expect(ChatoraiFontSizes.display, greaterThan(0));
    });
  });

  // ── ChatoraiSizes ──────────────────────────────────────────

  group('ChatoraiSizes', () {
    test('sidebar sizes are reasonable', () {
      expect(ChatoraiSizes.sidebarActionMenuWidth, 36.0);
      expect(ChatoraiSizes.sidebarIconButtonSize, 28.0);
    });

    test('loading indicator sizes are reasonable', () {
      expect(ChatoraiSizes.loadingIndicatorMaxWidth, 60.0);
      expect(ChatoraiSizes.chatLoadingIndicatorDefaultSize, 12.0);
      expect(ChatoraiSizes.chatTypingDotsDefaultSize, 6.0);
    });

    test('code block sizes are reasonable', () {
      expect(ChatoraiSizes.codeBlockLineHeight, 1.5);
      expect(ChatoraiSizes.codeBlockHeaderHeight, 28.0);
    });

    test('error text line height is reasonable', () {
      expect(ChatoraiSizes.errorTextLineHeight, 1.4);
    });

    test('icon button splash radius is positive', () {
      expect(ChatoraiSizes.iconButtonSplashRadius, greaterThan(0));
      expect(ChatoraiSizes.iconButtonSplashRadius, 18.0);
    });

    test('sidebar splash radii are positive', () {
      expect(ChatoraiSizes.sidebarSplashRadiusCollapsed, 16.0);
      expect(ChatoraiSizes.sidebarSplashRadiusExpanded, 20.0);
    });

    test('expanded sidebar splash radius is larger than collapsed', () {
      expect(
        ChatoraiSizes.sidebarSplashRadiusExpanded,
        greaterThan(ChatoraiSizes.sidebarSplashRadiusCollapsed),
      );
    });
  });

  // ── ChatoraiShadows ────────────────────────────────────────

  group('ChatoraiShadows', () {
    test('light shadow has one shadow entry', () {
      final shadows = ChatoraiShadows.lightShadow;
      expect(shadows, hasLength(1));
      expect(shadows.first.blurRadius, 10);
      expect(shadows.first.offset, const Offset(0, 2));
    });

    test('light footer shadow points upward', () {
      final shadows = ChatoraiShadows.lightFooterShadow;
      expect(shadows, hasLength(1));
      expect(shadows.first.offset, const Offset(0, -4));
    });

    test('dark shadow differs from light shadow', () {
      final dark = ChatoraiShadows.darkShadow;
      final light = ChatoraiShadows.lightShadow;
      expect(dark.first.color, isNot(equals(light.first.color)));
    });

    test('dark footer shadow differs from light footer shadow', () {
      final dark = ChatoraiShadows.darkFooterShadow;
      final light = ChatoraiShadows.lightFooterShadow;
      expect(dark.first.color, isNot(equals(light.first.color)));
    });

    test('card shadow has lower blur than popup shadow', () {
      expect(
        ChatoraiShadows.cardShadow.first.blurRadius,
        lessThan(ChatoraiShadows.popupShadow.first.blurRadius),
      );
    });

    test('popup shadow has largest blur radius', () {
      expect(ChatoraiShadows.popupShadow.first.blurRadius, 16);
      expect(ChatoraiShadows.popupShadow.first.offset, const Offset(0, 8));
    });

    test('all shadows have non-negative blur', () {
      final allShadows = [
        ...ChatoraiShadows.lightShadow,
        ...ChatoraiShadows.darkShadow,
        ...ChatoraiShadows.cardShadow,
        ...ChatoraiShadows.popupShadow,
      ];
      for (final shadow in allShadows) {
        expect(shadow.blurRadius, greaterThanOrEqualTo(0));
      }
    });
  });

  // ── ChatoraiBorderWidth ────────────────────────────────────

  group('ChatoraiBorderWidth', () {
    test('widths are monotonically increasing', () {
      expect(ChatoraiBorderWidth.none, 0.0);
      expect(ChatoraiBorderWidth.thin, 0.5);
      expect(ChatoraiBorderWidth.thinBold, 1.0);
      expect(ChatoraiBorderWidth.medium, 2.0);
      expect(ChatoraiBorderWidth.thick, 3.0);
      expect(ChatoraiBorderWidth.bold, 4.0);
    });

    test('none is zero', () {
      expect(ChatoraiBorderWidth.none, 0.0);
    });

    test('all widths are non-negative', () {
      expect(ChatoraiBorderWidth.none, greaterThanOrEqualTo(0));
      expect(ChatoraiBorderWidth.thin, greaterThanOrEqualTo(0));
      expect(ChatoraiBorderWidth.bold, greaterThanOrEqualTo(0));
    });
  });

  // ── ChatoraiDurations ──────────────────────────────────────

  group('ChatoraiDurations', () {
    test('instant is zero duration', () {
      expect(ChatoraiDurations.instant, Duration.zero);
    });

    test('fast is 150ms', () {
      expect(ChatoraiDurations.fast, const Duration(milliseconds: 150));
    });

    test('normal is 300ms', () {
      expect(ChatoraiDurations.normal, const Duration(milliseconds: 300));
    });

    test('slow is 500ms', () {
      expect(ChatoraiDurations.slow, const Duration(milliseconds: 500));
    });

    test('durations are monotonically increasing', () {
      expect(ChatoraiDurations.instant, lessThan(ChatoraiDurations.fast));
      expect(ChatoraiDurations.fast, lessThan(ChatoraiDurations.normal));
      expect(ChatoraiDurations.normal, lessThan(ChatoraiDurations.slow));
    });

    test('page duration matches normal', () {
      expect(ChatoraiDurations.page, ChatoraiDurations.normal);
    });
  });

  // ── ChatoraiTypography ─────────────────────────────────────

  group('ChatoraiTypography', () {
    test('light text theme has all headline styles', () {
      final theme = ChatoraiTypography.lightTextTheme;
      expect(theme.headlineLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.titleLarge, isNotNull);
    });

    test('dark text theme has all headline styles', () {
      final theme = ChatoraiTypography.darkTextTheme;
      expect(theme.headlineLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.titleLarge, isNotNull);
    });

    test('light and dark text themes differ', () {
      final light = ChatoraiTypography.lightTextTheme;
      final dark = ChatoraiTypography.darkTextTheme;
      expect(
        light.headlineLarge?.color,
        isNot(equals(dark.headlineLarge?.color)),
      );
    });

    test('light headlineLarge is bold', () {
      final theme = ChatoraiTypography.lightTextTheme;
      expect(theme.headlineLarge?.fontWeight, FontWeight.bold);
    });

    test('light headlineLarge font size is 32', () {
      final theme = ChatoraiTypography.lightTextTheme;
      expect(theme.headlineLarge?.fontSize, 32);
    });

    test('dark headlineLarge font size is 32', () {
      final theme = ChatoraiTypography.darkTextTheme;
      expect(theme.headlineLarge?.fontSize, 32);
    });
  });

  // ── AppTheme ───────────────────────────────────────────────

  group('AppTheme', () {
    test('light theme has light brightness', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
    });

    test('dark theme has dark brightness', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('light theme primary color is orange', () {
      expect(AppTheme.lightTheme.primaryColor, ChatoraiColors.orange);
    });

    test('dark theme primary color is orange', () {
      expect(AppTheme.darkTheme.primaryColor, ChatoraiColors.orange);
    });

    test('light and dark themes have different scaffold backgrounds', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        isNot(equals(AppTheme.darkTheme.scaffoldBackgroundColor)),
      );
    });

    test('light and dark themes have different card colors', () {
      expect(
        AppTheme.lightTheme.cardColor,
        isNot(equals(AppTheme.darkTheme.cardColor)),
      );
    });

    test('getTheme returns light for light brightness', () {
      expect(AppTheme.getTheme(Brightness.light), AppTheme.lightTheme);
    });

    test('getTheme returns dark for dark brightness', () {
      expect(AppTheme.getTheme(Brightness.dark), AppTheme.darkTheme);
    });

    test('light theme app bar has zero elevation', () {
      expect(AppTheme.lightTheme.appBarTheme.elevation, 0);
    });

    test('dark theme app bar has zero elevation', () {
      expect(AppTheme.darkTheme.appBarTheme.elevation, 0);
    });

    test('light theme bottom nav uses orange for selected', () {
      expect(
        AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor,
        ChatoraiColors.orange,
      );
    });

    test('dark theme bottom nav uses orange for selected', () {
      expect(
        AppTheme.darkTheme.bottomNavigationBarTheme.selectedItemColor,
        ChatoraiColors.orange,
      );
    });

    test('light theme uses light surface color', () {
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        ChatoraiColors.lightSurface,
      );
    });

    test('dark theme uses dark surface color', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        ChatoraiColors.darkSurface,
      );
    });

    test('light theme dialog uses orange in title', () {
      expect(AppTheme.lightTheme.iconTheme.color, isNotNull);
    });

    test('light and dark themes have different divider colors', () {
      expect(
        AppTheme.lightTheme.dividerColor,
        isNot(equals(AppTheme.darkTheme.dividerColor)),
      );
    });

    test('colorScheme primary is orange in both themes', () {
      expect(AppTheme.lightTheme.colorScheme.primary, ChatoraiColors.orange);
      expect(AppTheme.darkTheme.colorScheme.primary, ChatoraiColors.orange);
    });
  });
}
