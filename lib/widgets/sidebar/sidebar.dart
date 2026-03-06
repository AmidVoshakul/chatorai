import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/providers.dart' show themeProvider, languageProvider;
import 'package:chatorai/providers/chat/sidebar_provider.dart';
import 'package:chatorai/providers/chat/chat_providers.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/screens/settings_screen.dart';
import 'package:chatorai/widgets/sidebar/sidebar_chat_actions_menu.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/utils/format_time.dart';

import '../../utils/snackbar_utils.dart';

final _logger = LogTags.sidebar;

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
    final languageState = ref.watch(languageProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final sidebarState = ref.watch(sidebarProvider);
    final filteredChats = ref.watch(filteredChatsProvider);
    final chatsAsync = ref.watch(chatListProvider);

    final theme = themeNotifier.getTheme();
    final language = languageState.selectedLanguage;
    final localizations = AppLocalizations.of(context)!;

    chatsAsync.when(
      data: (data) => data,
      loading: () => <Chat>[],
      error: (e, st) => <Chat>[],
    );

    final currentChat = ref.watch(currentChatProvider);

    return AnimatedContainer(
      width: width,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          _buildHeader(context, theme, localizations),
          if (!isCollapsed) _buildSearchBar(context, ref, theme, localizations),
          Expanded(
            child: isCollapsed
                ? Container()
                : filteredChats.isEmpty
                ? _buildEmptyState(
                    context,
                    theme,
                    language,
                    localizations,
                    sidebarState.searchQuery,
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return _buildChatItem(
                        context,
                        ref,
                        chat,
                        theme,
                        language,
                        localizations,
                        currentChat,
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
        left: isCollapsed ? 2 : 16,
        right: isCollapsed ? 2 : 16,
        top: isCollapsed ? 0 : 12,
        bottom: isCollapsed ? 0 : 8,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
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
                  fontSize: 18,
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
              size: 18,
            ),
            onPressed: onToggleSidebar,
            padding: isCollapsed
                ? const EdgeInsets.all(4)
                : const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: isCollapsed ? 16 : 20,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: localizations.searchChats,
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  borderSide: BorderSide(color: theme.dividerColor, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  borderSide: BorderSide(color: theme.dividerColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                ref.read(sidebarProvider.notifier).setSearchQuery(value);
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: IconButton(
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_square),
              style: IconButton.styleFrom(
                side: BorderSide(color: theme.dividerColor, width: 1),
                padding: const EdgeInsets.all(8),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
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
    Chat? currentChat,
  ) {
    final isSelected = currentChat?.id == chat.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChatSelect(chat.id),
        borderRadius: BorderRadius.zero,
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          height: 60,
          child: Stack(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chat.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
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
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              Positioned(
                right: 8,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.chat_bubble_outline,
              size: 60,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? localizations.noChatsFound(searchQuery)
                  : localizations.noChatsYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? localizations.tryDifferentSearchTerm
                  : localizations.startConversation,
              style: TextStyle(
                fontSize: 12,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(localizations.settings),
            minLeadingWidth: 0,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () {
              _logger.logInfo('[Sidebar] Navigating to settings...');
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
