import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/themes/app_theme.dart';
import 'package:chatorai/providers.dart'
    show themeProvider, languageProvider, currentChatProvider;
import 'package:chatorai/providers/chat/sidebar_provider.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/screens/settings_screen.dart';
import 'package:chatorai/widgets/sidebar/sidebar_chat_actions_menu.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/utils/format_time.dart';
import 'package:chatorai/utils/snackbar_utils.dart';

// ===========================================================================
// SIDEBAR WIDGET
// ===========================================================================

class Sidebar extends ConsumerWidget {
  final double width;
  final bool isCollapsed;
  final VoidCallback onToggleSidebar;
  final Function(String) onChatSelect;
  final Function(String) onChatDelete;
  final Function() onNewChat;

  const Sidebar({
    super.key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleSidebar,
    required this.onChatSelect,
    required this.onChatDelete,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Оптимизация: минимизируем количество watch вызовов
    // Используем select для отслеживания только нужных полей
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = themeNotifier.getTheme();
    final localizations = AppLocalizations.of(context)!;

    // Отслеживаем только searchQuery, а не весь sidebarState
    final searchQuery = ref.watch(sidebarProvider.select((s) => s.searchQuery));

    // Отслеживаем только необходимые данные с оптимизацией
    final filteredChats = ref.watch(filteredChatsProvider);
    final isLoading = ref.watch(
      chatListLoadingProvider.select((value) => value),
    );
    final currentChatId = ref.watch(currentChatProvider.select((c) => c?.id));

    // Язык используется для форматирования даты в sidebar
    final language = ref.watch(
      languageProvider.select((s) => s.selectedLanguage),
    );

    return AnimatedContainer(
      width: width,
      duration: ChatoraiDurations.normal,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: ChatoraiShadows.lightShadow,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: ChatoraiBorderWidth.thinBold,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, theme, localizations),
          if (!isCollapsed) _buildSearchBar(context, ref, theme, localizations),
          Expanded(
            child: isCollapsed
                ? Container()
                : isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredChats.isEmpty
                ? _buildEmptyState(
                    context,
                    theme,
                    language,
                    localizations,
                    searchQuery,
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredChats.length,
                    itemExtent: ChatoraiSpacing.sidebarItemHeight,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return _buildChatItem(
                        context,
                        ref,
                        chat,
                        theme,
                        language,
                        localizations,
                        currentChatId,
                      );
                    },
                  ),
          ),
          if (!isCollapsed) _buildFooter(context, theme, localizations),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: isCollapsed ? ChatoraiSpacing.xs : ChatoraiSpacing.lg,
        right: isCollapsed ? ChatoraiSpacing.xs : ChatoraiSpacing.lg,
        top: isCollapsed ? 0 : ChatoraiSpacing.md,
        bottom: isCollapsed ? 0 : ChatoraiSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: ChatoraiBorderWidth.thinBold,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isCollapsed)
            Expanded(
              child: Text(
                localizations.appShortName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineSmall?.color,
                  fontSize: ChatoraiFontSizes.sidebarTitle,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          if (isCollapsed) const Spacer(),
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.menu : Icons.close,
              color: theme.iconTheme.color,
              size: ChatoraiIconSizes.sidebarMenuIcon,
            ),
            onPressed: onToggleSidebar,
            padding: isCollapsed
                ? const EdgeInsets.all(ChatoraiSpacing.xs)
                : const EdgeInsets.all(ChatoraiSpacing.sm),
            constraints: const BoxConstraints(
              minWidth: ChatoraiSizes.sidebarIconButtonSize,
              minHeight: ChatoraiSizes.sidebarIconButtonSize,
            ),
            splashRadius: isCollapsed
                ? ChatoraiSizes.sidebarSplashRadiusCollapsed
                : ChatoraiSizes.sidebarSplashRadiusExpanded,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatoraiSpacing.lg,
        vertical: ChatoraiSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: localizations.searchChats,
                prefixIcon: const Icon(
                  Icons.search,
                  size: ChatoraiIconSizes.lg,
                ),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(ChatoraiBorderRadius.sm),
                    bottomLeft: Radius.circular(ChatoraiBorderRadius.sm),
                  ),
                  borderSide: BorderSide(
                    color: theme.dividerColor,
                    width: ChatoraiBorderWidth.thinBold,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(ChatoraiBorderRadius.sm),
                    bottomLeft: Radius.circular(ChatoraiBorderRadius.sm),
                  ),
                  borderSide: BorderSide(
                    color: theme.dividerColor,
                    width: ChatoraiBorderWidth.thinBold,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(ChatoraiBorderRadius.sm),
                    bottomLeft: Radius.circular(ChatoraiBorderRadius.sm),
                  ),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: ChatoraiBorderWidth.thinBold,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ChatoraiSpacing.md,
                  vertical: ChatoraiSpacing.sm,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: ChatoraiFontSizes.base),
              onChanged: (value) {
                ref.read(sidebarProvider.notifier).setSearchQuery(value);
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: ChatoraiSpacing.xs),
            child: IconButton(
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_square),
              style: IconButton.styleFrom(
                side: BorderSide(
                  color: theme.dividerColor,
                  width: ChatoraiBorderWidth.thinBold,
                ),
                padding: const EdgeInsets.all(ChatoraiSpacing.sm),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(ChatoraiBorderRadius.sm),
                    bottomRight: Radius.circular(ChatoraiBorderRadius.sm),
                  ),
                ),
                backgroundColor: isDark
                    ? ChatoraiColors.darkGray
                    : ChatoraiColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    WidgetRef ref,
    Chat chat,
    ThemeData theme,
    String language,
    AppLocalizations localizations,
    String? currentChatId,
  ) {
    final isSelected = currentChatId == chat.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChatSelect(chat.id),
        borderRadius: BorderRadius.zero,
        hoverColor: ChatoraiColors.hoverLight,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.lg,
            vertical: ChatoraiSpacing.md,
          ),
          height: ChatoraiSpacing.sidebarItemHeight,
          child: Stack(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
                    size: ChatoraiIconSizes.sidebarIcon,
                  ),
                  const SizedBox(width: ChatoraiSpacing.sidebarIconSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chat.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: ChatoraiFontSizes.sidebarItem,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodyMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          formatSidebarDate(chat.updatedAt, context: context),
                          style: TextStyle(
                            fontSize: ChatoraiFontSizes.sidebarDate,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ChatoraiSizes.sidebarActionMenuWidth),
                ],
              ),
              Positioned(
                right: ChatoraiSpacing.sm,
                top: 0,
                bottom: 0,
                child: ChatActionsMenu(
                  chat: chat,
                  theme: theme,
                  language: language,
                  onRename: (newTitle) async {
                    try {
                      await ref
                          .read(sidebarProvider.notifier)
                          .renameChat(chat.id, newTitle);
                      if (context.mounted) {
                        SnackbarUtils.showSuccessSnackBar(
                          context: context,
                          message: localizations.chatRenamedTo(newTitle),
                          icon: Icons.edit,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SnackbarUtils.showErrorSnackBar(
                          context: context,
                          message: localizations.failedToRenameChat,
                          icon: Icons.error,
                        );
                      }
                    }
                  },
                  onDelete: () => onChatDelete(chat.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    String language,
    AppLocalizations localizations,
    String searchQuery,
  ) {
    final hasSearch = searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.chat_bubble_outline,
              size: ChatoraiIconSizes.emptyStateIcon,
              color: theme.iconTheme.color?.withValues(
                alpha: ChatoraiIconOpacity.low,
              ),
            ),
            const SizedBox(height: ChatoraiSpacing.lg),
            Text(
              hasSearch
                  ? localizations.noChatsFound(searchQuery)
                  : localizations.noChatsYet,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.lg,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ChatoraiSpacing.sm),
            Text(
              hasSearch
                  ? localizations.tryDifferentSearchTerm
                  : localizations.startConversation,
              style: TextStyle(
                fontSize: ChatoraiFontSizes.caption,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: ChatoraiShadows.lightFooterShadow,
      ),
      child: Column(
        children: [
          Divider(
            height: 1,
            thickness: ChatoraiBorderWidth.thinBold,
            color: theme.dividerColor,
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(localizations.settings),
            minLeadingWidth: 0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.lg,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
