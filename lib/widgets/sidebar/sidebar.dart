import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatorai/providers/theme_provider.dart';
import 'package:chatorai/providers/language_provider.dart';
import 'package:chatorai/models/chat_models.dart';
import 'package:chatorai/screens/settings_screen.dart';
import 'package:chatorai/widgets/sidebar/sidebar_controller.dart';
import 'package:chatorai/widgets/sidebar/sidebar_chat_actions_menu.dart';
import 'package:chatorai/utils/logger.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/utils/format_time.dart';

import '../../utils/snackbar_utils.dart';

final _logger = LogTags.sidebar;

class Sidebar extends StatefulWidget {
  final double width;
  final bool isCollapsed;
  final VoidCallback onToggleSidebar;
  final List<Chat> chats;
  final Chat? currentChat;
  final Function(String) onChatSelect;
  final Function(String) onChatDelete;
  final Function() onNewChat;

  const Sidebar({
    super.key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleSidebar,
    required this.chats,
    required this.currentChat,
    required this.onChatSelect,
    required this.onChatDelete,
    required this.onNewChat,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late SidebarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SidebarController(chats: widget.chats);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = themeProvider.getTheme();
    final language = languageProvider.selectedLanguage;
    final localizations = AppLocalizations.of(context)!;

    return AnimatedContainer(
      width: widget.width,
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
          _buildHeader(theme, localizations),
          if (!widget.isCollapsed) _buildSearchBar(theme, localizations),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (widget.isCollapsed) {
                  return Container();
                }
                if (_controller.filteredChats.isEmpty) {
                  return _buildEmptyState(theme, language, localizations);
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _controller.filteredChats.length,
                  itemBuilder: (context, index) {
                    final chat = _controller.filteredChats[index];
                    return _buildChatItem(chat, theme, language, localizations);
                  },
                );
              },
            ),
          ),
          if (!widget.isCollapsed) _buildFooter(theme, localizations),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: EdgeInsets.only(
        left: widget.isCollapsed ? 2 : 16,
        right: widget.isCollapsed ? 2 : 16,
        top: widget.isCollapsed ? 0 : 12,
        bottom: widget.isCollapsed ? 0 : 8,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.isCollapsed)
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
          if (widget.isCollapsed) const Spacer(),
          IconButton(
            icon: Icon(
              widget.isCollapsed ? Icons.menu : Icons.close,
              color: theme.iconTheme.color,
              size: 18,
            ),
            onPressed: widget.onToggleSidebar,
            padding: widget.isCollapsed
                ? const EdgeInsets.all(4)
                : const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: widget.isCollapsed ? 16 : 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, AppLocalizations localizations) {
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
                setState(() {
                  _controller.setSearchQuery(value);
                });
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: IconButton(
              onPressed: widget.onNewChat,
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
    Chat chat,
    ThemeData theme,
    String language,
    AppLocalizations localizations,
  ) {
    final isSelected = widget.currentChat?.id == chat.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onChatSelect(chat.id),
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
                      await _controller.renameChat(context, chat, newTitle);
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
                  onDelete: () => widget.onChatDelete(chat.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    String language,
    AppLocalizations localizations,
  ) {
    final hasSearch = _controller.searchQuery.isNotEmpty;

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
                  ? localizations.noChatsFound(_controller.searchQuery)
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

  Widget _buildFooter(ThemeData theme, AppLocalizations localizations) {
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
