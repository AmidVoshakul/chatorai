import 'package:flutter/material.dart';
import 'package:chatorai/models/chat_model.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/screens/models_screen.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/constants/chat_constants.dart';

// ===========================================================================
// WIDGET CLASS
// ===========================================================================

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedModel;
  final ChatModel? selectedModelObject;
  final bool Function() hasHeadings;
  final VoidCallback onToggleNavigator;
  final Function(String modelId, ChatModel? modelObject) onModelSelected;
  final VoidCallback? onMenuPressed;

  const ChatAppBar({
    super.key,
    required this.selectedModel,
    this.selectedModelObject,
    required this.hasHeadings,
    required this.onToggleNavigator,
    required this.onModelSelected,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // =======================================================================
  // BUILD METHOD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < ChatScreenConstants.mobileBreakpoint;
    final isDark = theme.brightness == Brightness.dark;

    final modelTextColor = isDark ? Colors.grey[700] : theme.iconTheme.color;
    final localizations = AppLocalizations.of(context);

    return AppBar(
      title: const Text(''),
      backgroundColor: theme.canvasColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, size: ChatoraiIconSizes.buttonIcon),
          onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        if (selectedModelObject != null)
          isMobile
              ? SizedBox(
                  width: screenWidth * 0.50,
                  child: Center(
                    child: Text(
                      selectedModelObject!.name,
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.sm,
                        fontWeight: FontWeight.w500,
                        color: modelTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Text(
                  selectedModelObject!.name,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.sm,
                    fontWeight: FontWeight.w600,
                    color: modelTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        IconButton(
          icon: Icon(Icons.smart_toy, size: ChatoraiIconSizes.buttonIcon),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModelsScreen(
                  onModelSelected: (String modelId, ChatModel? modelObject) {
                    onModelSelected(modelId, modelObject);
                  },
                  currentModel: selectedModel,
                ),
              ),
            );
          },
          tooltip: localizations?.selectModelTooltip ?? 'Select Model',
        ),
        if (hasHeadings())
          IconButton(
            icon: Icon(
              Icons.format_list_bulleted,
              size: ChatoraiIconSizes.buttonIcon,
            ),
            onPressed: onToggleNavigator,
            tooltip:
                localizations?.toggleNavigatorTooltip ?? 'Toggle Navigator',
          ),
      ],
    );
  }
}
