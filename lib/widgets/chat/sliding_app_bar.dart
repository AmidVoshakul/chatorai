import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/services/openrouter_service.dart';
import 'package:gen_ui_chat_ai/themes/app_theme.dart';

/// Constants for SlidingAppBar behavior
class SlidingAppBarConstants {
  static const double hideThreshold = 100.0;
  static const double showThreshold = 50.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double mobileModelNameWidthFactor = 0.50;
  static const double mobileModelNameFontSize = 12.0;
  static const double desktopModelNameFontSize = 14.0;
  static const double iconSize = 20.0;
  static const double rightPadding = 8.0;
  static const double appBarHeight = 55.0;
}

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
  Size get preferredSize => const Size.fromHeight(SlidingAppBarConstants.appBarHeight);
}

class SlidingAppBarState extends State<SlidingAppBar> {
  double _lastScrollOffset = 0;
  bool _isHidden = false;

  // Public getter for debugging
  bool get isHidden => _isHidden;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handles scroll events to show/hide the app bar
  /// 
  /// Call this method from the scroll controller listener:
  /// ```dart
  /// _messageScrollController.addListener(() {
  ///   _slidingAppBarKey.currentState?.handleScroll(_messageScrollController.offset);
  /// });
  /// ```
  void handleScroll(double scrollOffset) {
    // Hide when scrolling down past threshold
    if (scrollOffset > _lastScrollOffset && 
        scrollOffset > SlidingAppBarConstants.hideThreshold) {
      if (!_isHidden) {
        setState(() {
          _isHidden = true;
        });
      }
    }
    // Show when scrolling up or at top
    else if (scrollOffset < _lastScrollOffset || 
             scrollOffset < SlidingAppBarConstants.showThreshold) {
      if (_isHidden) {
        setState(() {
          _isHidden = false;
        });
      }
    }
    _lastScrollOffset = scrollOffset;
  }

  /// Force show the app bar (resets to visible state)
  /// 
  /// Useful for:
  /// - New chat creation
  /// - Chat switching
  /// - Model changes
  /// - Navigator actions
  void show() {
    if (_isHidden) {
      setState(() {
        _isHidden = false;
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
    _isHidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adaptive text color based on theme
    final modelTextColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]
        : theme.iconTheme.color;

    // Completely hide the AppBar by returning empty container when hidden
    if (_isHidden) {
      return const SizedBox.shrink();
    }

    // Visible AppBar
    return Container(
      color: theme.canvasColor,
      height: SlidingAppBarConstants.appBarHeight,
      child: SafeArea(
        top: true,
        bottom: false,
        left: false,
        right: false,
        child: Row(
          children: [
            // Menu button
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: SlidingAppBarConstants.iconSize),
                color: UbuntuColors.orange,
                onPressed: widget.onMenuPressed,
              ),
            ),
            
            // Spacer to push model name to center
            const Spacer(),
            
            // Model name (centered, with overflow handling)
            _buildModelName(widget.selectedModelObject?.name ?? widget.selectedModel, 
                           modelTextColor, screenWidth),
            
            // Spacer to push buttons to right
            const Spacer(),
            
            // Model selection button
            IconButton(
              icon: const Icon(Icons.smart_toy, size: SlidingAppBarConstants.iconSize),
              color: UbuntuColors.orange,
              onPressed: widget.onModelSelected,
              tooltip: 'Select Model',
            ),
            
            // Navigator button (only if headings exist)
            if (widget.hasHeadings())
              IconButton(
                icon: const Icon(Icons.format_list_bulleted, size: SlidingAppBarConstants.iconSize),
                color: UbuntuColors.orange,
                onPressed: widget.onNavigatorPressed,
                tooltip: 'Toggle Navigator',
              ),
            
            // Right padding
            const SizedBox(width: SlidingAppBarConstants.rightPadding),
          ],
        ),
      ),
    );
  }

  /// Builds the model name widget with proper styling and overflow handling
  Widget _buildModelName(String name, Color? textColor, double screenWidth) {
    if (widget.isMobile) {
      // Mobile: limit width, center text
      return SizedBox(
        width: screenWidth * SlidingAppBarConstants.mobileModelNameWidthFactor,
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: SlidingAppBarConstants.mobileModelNameFontSize,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      // Desktop: full width, left-aligned
      return Text(
        name,
        style: TextStyle(
          fontSize: SlidingAppBarConstants.desktopModelNameFontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
  }
}
