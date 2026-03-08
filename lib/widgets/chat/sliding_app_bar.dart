import 'package:flutter/material.dart';
import 'package:chatorai/services/openrouter_service.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/constants/sliding_app_bar_constants.dart';
import 'package:chatorai/l10n/app_localizations.dart';

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

/// A sliding app bar that hides when scrolling down and shows when scrolling up
///
/// Usage:
/// ```dart
/// SlidingAppBar(
///   selectedModel: 'model-id',
///   selectedModelObject: model,
///   onMenuPressed: () => Scaffold.of(context).openDrawer(),
///   onModelSelected: () => navigateToModels(),
///   hasHeadings: () => headings.isNotEmpty,
///   onNavigatorPressed: () => toggleNavigator(),
///   isMobile: isMobile,
/// )
/// ```
class SlidingAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Currently selected model ID
  final String selectedModel;

  /// Currently selected model object (for display name)
  final OpenRouterModel? selectedModelObject;

  /// Callback when menu button is pressed
  final VoidCallback onMenuPressed;

  /// Callback when model selection button is pressed
  final VoidCallback onModelSelected;

  /// Function that returns true if there are headings to show navigator
  final bool Function() hasHeadings;

  /// Callback when navigator button is pressed
  final VoidCallback onNavigatorPressed;

  /// Whether to use mobile layout (narrower model name)
  final bool isMobile;

  const SlidingAppBar({
    super.key,
    required this.selectedModel,
    required this.selectedModelObject,
    required this.onMenuPressed,
    required this.onModelSelected,
    required this.hasHeadings,
    required this.onNavigatorPressed,
    required this.isMobile,
  });

  @override
  State<SlidingAppBar> createState() => SlidingAppBarState();

  @override
  Size get preferredSize =>
      const Size.fromHeight(SlidingAppBarConstants.appBarHeight);
}

// ===========================================================================
// STATE CLASS
// ===========================================================================

class SlidingAppBarState extends State<SlidingAppBar> {
  double _lastScrollOffset = 0;
  double _hideProgress = 0.0;

  bool get isHidden => _hideProgress >= 1.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // =======================================================================
  // PUBLIC API METHODS
  // =======================================================================

  /// Handles scroll events to show/hide the app bar with smooth animation
  ///
  /// Call this method from the scroll controller listener:
  /// ```dart
  /// _messageScrollController.addListener(() {
  ///   _slidingAppBarKey.currentState?.handleScroll(_messageScrollController.offset);
  /// });
  /// ```
  void handleScroll(double scrollOffset) {
    final delta = scrollOffset - _lastScrollOffset;

    if (scrollOffset > _lastScrollOffset &&
        scrollOffset > SlidingAppBarConstants.hideThreshold) {
      final normalizedDelta = delta / SlidingAppBarConstants.hideThreshold;
      final newProgress = _hideProgress + (normalizedDelta * 0.8);
      _updateHideProgress(newProgress);
    } else if (scrollOffset < _lastScrollOffset ||
        scrollOffset < SlidingAppBarConstants.showThreshold) {
      final normalizedDelta =
          delta.abs() / SlidingAppBarConstants.showThreshold;
      final newProgress = _hideProgress - (normalizedDelta * 0.6);
      _updateHideProgress(newProgress);
    }

    _lastScrollOffset = scrollOffset;
  }

  void show() {
    if (_hideProgress > 0) {
      setState(() {
        _hideProgress = 0.0;
      });
    }
  }

  /// Reset the sliding app bar to initial visible state
  ///
  /// Call this when:
  /// - Switching chats
  /// - Creating new chat
  /// - Any action that should reset the UI state
  void reset() {
    _lastScrollOffset = 0;
    _hideProgress = 0.0;
  }

  // =======================================================================
  // PRIVATE METHODS
  // =======================================================================

  void _updateHideProgress(double newProgress) {
    final clampedProgress = newProgress.clamp(0.0, 1.0);

    if (clampedProgress != _hideProgress) {
      setState(() {
        _hideProgress = clampedProgress;
      });
    }
  }

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final modelTextColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]
        : theme.iconTheme.color;

    if (_hideProgress >= 1.0) {
      return const SizedBox.shrink();
    }

    final easedProgress = SlidingAppBarConstants.animationCurve.transform(
      _hideProgress,
    );

    final dynamicHeight =
        SlidingAppBarConstants.appBarHeight * (1.0 - easedProgress);

    return SizedBox(
      height: dynamicHeight,
      child: OverflowBox(
        maxHeight: SlidingAppBarConstants.appBarHeight,
        alignment: Alignment.topCenter,
        child: Container(
          height: SlidingAppBarConstants.appBarHeight,
          decoration: BoxDecoration(
            color: theme.canvasColor,
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 4.0,
                spreadRadius: 0.0,
              ),
            ],
          ),
          child: AnimatedOpacity(
            opacity: 1.0 - easedProgress,
            duration: SlidingAppBarConstants.animationDuration,
            curve: SlidingAppBarConstants.animationCurve,
            child: SafeArea(
              top: true,
              bottom: false,
              left: false,
              right: false,
              maintainBottomViewPadding: true,
              child: Container(
                height: SlidingAppBarConstants.appBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(
                          Icons.menu,
                          size: ChatoraiIconSizes.buttonIcon,
                        ),
                        color: ChatoraiColors.orange,
                        onPressed: widget.onMenuPressed,
                        padding: const EdgeInsets.only(
                          left: 4.0,
                          right: 4.0,
                          bottom: 8.0,
                          top: 4.0,
                        ),
                        constraints: const BoxConstraints(),
                        iconSize: ChatoraiIconSizes.buttonIcon,
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: _buildModelName(
                          widget.selectedModelObject?.name ?? '',
                          modelTextColor,
                          screenWidth,
                        ),
                      ),
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.smart_toy,
                            size: ChatoraiIconSizes.buttonIcon,
                          ),
                          color: ChatoraiColors.orange,
                          onPressed: widget.onModelSelected,
                          tooltip: AppLocalizations.of(
                            context,
                          )!.selectModelTooltip,
                          padding: const EdgeInsets.only(
                            left: 4.0,
                            right: 4.0,
                            bottom: 8.0,
                            top: 4.0,
                          ),
                          constraints: const BoxConstraints(),
                          iconSize: ChatoraiIconSizes.buttonIcon,
                        ),

                        if (widget.hasHeadings())
                          IconButton(
                            icon: Icon(
                              Icons.format_list_bulleted,
                              size: ChatoraiIconSizes.buttonIcon,
                            ),
                            color: ChatoraiColors.orange,
                            onPressed: widget.onNavigatorPressed,
                            tooltip: AppLocalizations.of(
                              context,
                            )!.toggleNavigatorTooltip,
                            padding: const EdgeInsets.only(
                              right: 4.0,
                              bottom: 8.0,
                              top: 4.0,
                            ),
                            constraints: const BoxConstraints(),
                            iconSize: ChatoraiIconSizes.buttonIcon,
                          ),

                        const SizedBox(
                          width: SlidingAppBarConstants.rightPadding,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // HELPER WIDGETS
  // =======================================================================

  Widget _buildModelName(String name, Color? textColor, double screenWidth) {
    if (widget.isMobile) {
      return SizedBox(
        width: screenWidth * SlidingAppBarConstants.mobileModelNameWidthFactor,
        child: Text(
          name,
          style: TextStyle(
            fontSize: SlidingAppBarConstants.mobileModelNameFontSize,
            fontWeight: FontWeight.w500,
            color: textColor,
            height: 1.2,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Text(
        name,
        style: TextStyle(
          fontSize: SlidingAppBarConstants.desktopModelNameFontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.2,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
  }
}
