// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

/// Widget for horizontally scrollable action buttons
/// Used to prevent overflow when there are many action icons
class ScrollableActionButtons extends StatelessWidget {
  final List<Widget> children;
  final double buttonSpacing;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final ScrollController? scrollController;

  const ScrollableActionButtons({
    super.key,
    required this.children,
    this.buttonSpacing = 4.0,
    this.height = 40.0,
    this.padding,
    this.backgroundColor,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // If we have 4 or fewer buttons, don't use scrolling
    if (children.length <= 4) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: _buildButtonChildren(),
      );
    }

    return Container(
      height: height,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Left padding
          const SizedBox(width: 8),
          
          // Scrollable buttons
          Expanded(
            child: ListView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildButtonChildren(),
                ),
              ],
            ),
          ),
          
          // Right padding
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Build the list of button children with proper spacing
  List<Widget> _buildButtonChildren() {
    final List<Widget> buttonChildren = [];
    
    for (int i = 0; i < children.length; i++) {
      buttonChildren.add(children[i]);
      
      // Add spacing between buttons (not after the last one)
      if (i < children.length - 1) {
        buttonChildren.add(SizedBox(width: buttonSpacing));
      }
    }
    
    return buttonChildren;
  }
}