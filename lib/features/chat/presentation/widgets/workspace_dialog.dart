import 'dart:async';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:chatorai/core/keyboard/shortcut_handler.dart';
import 'package:chatorai/core/keyboard/shortcuts.dart';
import 'package:chatorai/core/session/session_state.dart';
import 'package:chatorai/features/chat/presentation/providers/chat_stream_actions.dart';
import 'package:chatorai/features/chat/presentation/widgets/workspace_switch_confirm_sheet.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/providers.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/format_time_utils.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:chatorai/features/chat/presentation/widgets/premium_confirm_sheet.dart';
import 'package:path/path.dart' as p;

Future<String?> showWorkspaceDialog(BuildContext context, WidgetRef ref) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierColor: ChatoraiColors.black30,
    builder: (_) => const _WorkspaceDialog(),
  );
}

class _WorkspaceDialog extends ConsumerStatefulWidget {
  const _WorkspaceDialog();

  @override
  ConsumerState<_WorkspaceDialog> createState() => _WorkspaceDialogState();
}

class _WorkspaceDialogState extends ConsumerState<_WorkspaceDialog> {
  final _directorySearchController = TextEditingController();
  final _sessionSearchController = TextEditingController();
  String _directoryQuery = '';
  String _sessionQuery = '';
  String _selectedDirectory = '';
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(workspaceProvider.notifier)
          .init()
          .then((_) {
            if (mounted) {
              final current = ref.read(workspaceProvider).currentPath;
              if (current.isNotEmpty) {
                setState(() => _selectedDirectory = current);
              }
            }
          })
          .catchError((e, st) {
            LogTags.chatService.logWarning('Workspace init failed', e, st);
          }),
    );
  }

  @override
  void dispose() {
    _directorySearchController.dispose();
    _sessionSearchController.dispose();
    super.dispose();
  }

  Future<void> _onAddDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || !mounted) return;
    final notifier = ref.read(workspaceProvider.notifier);
    try {
      await notifier.addDirectory(path);
    } on ArgumentError {
      return;
    }
    if (!mounted) return;
    final switched = await _ensureSwitchedTo(path);
    if (!switched) return;
    if (mounted) {
      Navigator.pop(context, path);
    }
  }

  List<String> _filteredDirectories(List<String> known) {
    if (_directoryQuery.isEmpty) return known;
    final q = _directoryQuery.toLowerCase();
    return known.where((path) {
      final basename = p.basename(path).toLowerCase();
      final fullPath = path.toLowerCase();
      return basename.contains(q) || fullPath.contains(q);
    }).toList();
  }

  Future<void> _openSession(SessionState session) async {
    final dir = session.directory ?? _selectedDirectory;
    final current = ref.read(workspaceProvider).currentPath;

    if (dir != current) {
      final switched = await _ensureSwitchedTo(dir);
      if (!switched) return;
    }

    ref.read(currentChatIdProvider.notifier).setChatId(session.id.value);
    unawaited(
      ref.read(chatListProvider.notifier).ensureChatLoaded(session.id.value),
    );
    if (mounted) {
      Navigator.pop(context, dir);
    }
  }

  Future<void> _onDeleteSession(SessionState session) async {
    final l10n = AppLocalizations.of(context)!;
    final title = session.title.isEmpty ? 'Session' : session.title;
    final confirmed = await showPremiumConfirmSheet(
      context: context,
      title: l10n.deleteChat,
      message: l10n.confirmDeleteMessage(title),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (confirmed != true) return;

    final currentChatId = ref.read(currentChatIdProvider);
    final isStreaming = ref.read(chatScreenProvider).isStreaming;
    if (isStreaming && currentChatId == session.id.value) {
      stopActiveStreaming(ref);
    }

    await ref.read(chatListProvider.notifier).deleteChat(session.id.value);
    if (currentChatId == session.id.value) {
      ref.read(currentChatIdProvider.notifier).setChatId(null);
    }
    ref.invalidate(
      sessionsByDirectoryProvider(session.directory ?? _selectedDirectory),
    );
  }

  Future<void> _onNewSession() async {
    final target = _selectedDirectory.isEmpty
        ? ref.read(workspaceProvider).currentPath
        : _selectedDirectory;
    if (target.isEmpty) return;

    final current = ref.read(workspaceProvider).currentPath;
    if (target != current) {
      final switched = await _ensureSwitchedTo(target);
      if (!switched) return;
    }

    final newChat = await ref
        .read(chatListProvider.notifier)
        .createNewChat(directory: target);
    ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
    unawaited(ref.read(chatListProvider.notifier).ensureChatLoaded(newChat.id));
    if (mounted) {
      Navigator.pop(context, target);
    }
  }

  Future<bool> _ensureSwitchedTo(String target) async {
    final current = ref.read(workspaceProvider).currentPath;
    if (target == current) return true;

    if (ref.read(chatScreenProvider).isStreaming) {
      final proceed = await showWorkspaceSwitchConfirmSheet(context);
      if (proceed != true) return false;
      stopActiveStreaming(ref);
    }
    await ref.read(workspaceProvider.notifier).switchWorkspace(target);

    final chatId = ref.read(currentChatIdProvider);
    if (chatId != null) {
      final repository = await ref.read(sessionRepositoryProvider.future);
      final session = await repository.getSessionMetaFromId(chatId);
      if (session == null ||
          session.directory == null ||
          session.directory != target) {
        ref.read(currentChatIdProvider.notifier).setChatId(null);
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChatoraiSettingsWindow.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(workspaceProvider);
    final filtered = _filteredDirectories(state.knownDirectories);
    final screenSize = MediaQuery.sizeOf(context);
    final maxHeight = (720.0)
        .clamp(0.0, math.max(0.0, screenSize.height - 64))
        .toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isClosing) return;
        _isClosing = true;
        try {
          if (_selectedDirectory.isNotEmpty &&
              _selectedDirectory != ref.read(workspaceProvider).currentPath) {
            final switched = await _ensureSwitchedTo(_selectedDirectory);
            if (switched && context.mounted) {
              Navigator.pop(context, _selectedDirectory);
            } else {
              _isClosing = false;
            }
          } else if (context.mounted) {
            Navigator.pop(context);
          } else {
            _isClosing = false;
          }
        } catch (_) {
          _isClosing = false;
          rethrow;
        }
      },
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ChatoraiSettingsWindow.maxWindowWidth,
              maxHeight: maxHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xl),
                border: Border.all(
                  color: palette.border,
                  width: ChatoraiBorderWidth.thin,
                ),
                boxShadow: ChatoraiShadows.windowShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.xl),
                child: Material(
                  color: palette.surface,
                  child: ShortcutHandler(
                    autofocus: true,
                    shortcuts: [
                      AppShortcuts.closeDialog(() => Navigator.pop(context)),
                    ],
                    child: Column(
                      children: [
                        _DialogHeader(palette: palette, l10n: l10n),
                        _HairlineDivider(color: palette.divider),
                        Expanded(
                          child: _TwoColumnBody(
                            palette: palette,
                            l10n: l10n,
                            filteredDirectories: filtered,
                            directoryQuery: _directoryQuery,
                            sessionQuery: _sessionQuery,
                            selectedDirectory: _selectedDirectory,
                            currentPath: state.currentPath,
                            onDirectoryQueryChanged: (value) =>
                                setState(() => _directoryQuery = value),
                            onSessionQueryChanged: (value) =>
                                setState(() => _sessionQuery = value),
                            onSelectDirectory: (path) {
                              setState(() => _selectedDirectory = path);
                            },
                            onOpenSession: _openSession,
                            onDeleteSession: _onDeleteSession,
                            onAddDirectory: _onAddDirectory,
                            onNewSession: _onNewSession,
                            onSwitchDirectory: _ensureSwitchedTo,
                            directorySearchController:
                                _directorySearchController,
                            sessionSearchController: _sessionSearchController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final ChatoraiSettingsWindowColors palette;
  final AppLocalizations l10n;

  const _DialogHeader({required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ChatoraiSettingsWindow.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.workspaces,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.xxl,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            _ToolbarIconButton(
              icon: Icons.close,
              tooltip: l10n.close,
              onPressed: () => Navigator.pop(context),
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ChatoraiSettingsWindowColors palette;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: ChatoraiIconSizes.md, color: palette.icon),
        ),
      ),
    );
  }
}

class _TwoColumnBody extends StatelessWidget {
  final ChatoraiSettingsWindowColors palette;
  final AppLocalizations l10n;
  final List<String> filteredDirectories;
  final String directoryQuery;
  final String sessionQuery;
  final String selectedDirectory;
  final String currentPath;
  final ValueChanged<String> onDirectoryQueryChanged;
  final ValueChanged<String> onSessionQueryChanged;
  final ValueChanged<String> onSelectDirectory;
  final Future<void> Function(SessionState) onOpenSession;
  final Future<void> Function(SessionState) onDeleteSession;
  final VoidCallback onAddDirectory;
  final VoidCallback onNewSession;
  final Future<bool> Function(String) onSwitchDirectory;
  final TextEditingController directorySearchController;
  final TextEditingController sessionSearchController;

  const _TwoColumnBody({
    required this.palette,
    required this.l10n,
    required this.filteredDirectories,
    required this.directoryQuery,
    required this.sessionQuery,
    required this.selectedDirectory,
    required this.currentPath,
    required this.onDirectoryQueryChanged,
    required this.onSessionQueryChanged,
    required this.onSelectDirectory,
    required this.onOpenSession,
    required this.onDeleteSession,
    required this.onAddDirectory,
    required this.onNewSession,
    required this.onSwitchDirectory,
    required this.directorySearchController,
    required this.sessionSearchController,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 640;

    if (isWide) {
      return Row(
        children: [
          SizedBox(
            width: 300,
            child: _DirectoryColumn(
              palette: palette,
              l10n: l10n,
              filtered: filteredDirectories,
              query: directoryQuery,
              selectedDirectory: selectedDirectory,
              currentPath: currentPath,
              onQueryChanged: onDirectoryQueryChanged,
              onSelectDirectory: onSelectDirectory,
              onAddDirectory: onAddDirectory,
              onSwitchDirectory: onSwitchDirectory,
              searchController: directorySearchController,
            ),
          ),
          Container(width: ChatoraiBorderWidth.thin, color: palette.divider),
          Expanded(
            child: _SessionColumn(
              palette: palette,
              l10n: l10n,
              directory: selectedDirectory,
              query: sessionQuery,
              onQueryChanged: onSessionQueryChanged,
              onOpenSession: onOpenSession,
              onDeleteSession: onDeleteSession,
              onNewSession: onNewSession,
              searchController: sessionSearchController,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _DirectoryColumn(
            palette: palette,
            l10n: l10n,
            filtered: filteredDirectories,
            query: directoryQuery,
            selectedDirectory: selectedDirectory,
            currentPath: currentPath,
            onQueryChanged: onDirectoryQueryChanged,
            onSelectDirectory: onSelectDirectory,
            onAddDirectory: onAddDirectory,
            onSwitchDirectory: onSwitchDirectory,
            searchController: directorySearchController,
          ),
        ),
        Container(height: ChatoraiBorderWidth.thin, color: palette.divider),
        Expanded(
          flex: 3,
          child: _SessionColumn(
            palette: palette,
            l10n: l10n,
            directory: selectedDirectory,
            query: sessionQuery,
            onQueryChanged: onSessionQueryChanged,
            onOpenSession: onOpenSession,
            onDeleteSession: onDeleteSession,
            onNewSession: onNewSession,
            searchController: sessionSearchController,
          ),
        ),
      ],
    );
  }
}

class _DirectoryColumn extends ConsumerWidget {
  final ChatoraiSettingsWindowColors palette;
  final AppLocalizations l10n;
  final List<String> filtered;
  final String query;
  final String selectedDirectory;
  final String currentPath;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSelectDirectory;
  final VoidCallback onAddDirectory;
  final Future<bool> Function(String) onSwitchDirectory;
  final TextEditingController searchController;

  const _DirectoryColumn({
    required this.palette,
    required this.l10n,
    required this.filtered,
    required this.query,
    required this.selectedDirectory,
    required this.currentPath,
    required this.onQueryChanged,
    required this.onSelectDirectory,
    required this.onAddDirectory,
    required this.onSwitchDirectory,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChatoraiSpacing.lg,
            ChatoraiSpacing.lg,
            ChatoraiSpacing.lg,
            ChatoraiSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.directoryTitle,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              Text(
                '(${filtered.length})',
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
          child: TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchDirectories,
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: palette.content,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                borderSide: BorderSide(
                  color: palette.border,
                  width: ChatoraiBorderWidth.thin,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                borderSide: BorderSide(
                  color: ChatoraiColors.orange,
                  width: ChatoraiBorderWidth.thinBold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.noWorkspacesFound,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: ChatoraiFontSizes.base,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: ChatoraiSpacing.xs,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final path = filtered[index];
                    final isActive = path == currentPath;
                    final isSelected = path == selectedDirectory;
                    return _WorkspaceRow(
                      path: path,
                      isActive: isActive,
                      isSelected: isSelected,
                      palette: palette,
                      l10n: l10n,
                      onTap: () async {
                        onSelectDirectory(path);
                        final switched = await onSwitchDirectory(path);
                        if (!switched) return;
                        if (context.mounted) {
                          Navigator.pop(context, path);
                        }
                      },
                      onDelete: isActive
                          ? null
                          : () async {
                              await ref
                                  .read(workspaceProvider.notifier)
                                  .removeDirectory(path);
                            },
                    );
                  },
                ),
        ),
        _HairlineDivider(color: palette.divider),
        InkWell(
          onTap: onAddDirectory,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.lg,
              vertical: ChatoraiSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: ChatoraiIconSizes.md,
                  color: palette.icon,
                ),
                const SizedBox(width: ChatoraiSpacing.sm),
                Text(
                  l10n.addDirectory,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionColumn extends ConsumerWidget {
  final ChatoraiSettingsWindowColors palette;
  final AppLocalizations l10n;
  final String directory;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(SessionState) onOpenSession;
  final Future<void> Function(SessionState) onDeleteSession;
  final VoidCallback onNewSession;
  final TextEditingController searchController;

  const _SessionColumn({
    required this.palette,
    required this.l10n,
    required this.directory,
    required this.query,
    required this.onQueryChanged,
    required this.onOpenSession,
    required this.onDeleteSession,
    required this.onNewSession,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsByDirectoryProvider(directory));
    final sessions = sessionsAsync.value ?? const <SessionState>[];
    final filtered = sessions
        .where((s) => s.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChatoraiSpacing.lg,
            ChatoraiSpacing.lg,
            ChatoraiSpacing.lg,
            ChatoraiSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sessionsTitle,
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              Text(
                '(${filtered.length})',
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.sm,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChatoraiSpacing.lg),
          child: TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.searchSessions,
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: palette.content,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                borderSide: BorderSide(
                  color: palette.border,
                  width: ChatoraiBorderWidth.thin,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
                borderSide: BorderSide(
                  color: ChatoraiColors.orange,
                  width: ChatoraiBorderWidth.thinBold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ChatoraiSpacing.sm),
        Expanded(
          child: sessionsAsync.when(
            loading: () => const Center(
              child: SpinKitCircle(size: 14, color: ChatoraiColors.gray),
            ),
            error: (_, _) => Center(
              child: Text(
                l10n.noSessions,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: ChatoraiFontSizes.base,
                ),
              ),
            ),
            data: (sessions) {
              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noSessions,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: ChatoraiFontSizes.base,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: ChatoraiSpacing.xs,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final session = filtered[index];
                  return _SessionRow(
                    session: session,
                    palette: palette,
                    l10n: l10n,
                    onTap: () => onOpenSession(session),
                    onDelete: () => onDeleteSession(session),
                  );
                },
              );
            },
          ),
        ),
        _HairlineDivider(color: palette.divider),
        InkWell(
          onTap: onNewSession,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatoraiSpacing.lg,
              vertical: ChatoraiSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: ChatoraiIconSizes.md,
                  color: palette.icon,
                ),
                const SizedBox(width: ChatoraiSpacing.sm),
                Text(
                  l10n.newSession,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final SessionState session;
  final ChatoraiSettingsWindowColors palette;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SessionRow({
    required this.session,
    required this.palette,
    required this.l10n,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      child: Container(
        color: palette.navItemSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.lg,
            vertical: ChatoraiSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      session.title.isEmpty ? 'Session' : session.title,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: ChatoraiFontSizes.base,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      formatSidebarDate(session.updatedAt, context: context),
                      style: TextStyle(
                        fontSize: ChatoraiFontSizes.sm,
                        color: palette.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteChat,
                  onPressed: onDelete,
                  splashRadius: ChatoraiSizes.iconButtonSplashRadius,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: ChatoraiIconSizes.md,
                  color: palette.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  final Color color;
  const _HairlineDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: ChatoraiBorderWidth.thin, color: color);
  }
}

class _WorkspaceRow extends StatelessWidget {
  final String path;
  final bool isActive;
  final bool isSelected;
  final ChatoraiSettingsWindowColors palette;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _WorkspaceRow({
    required this.path,
    required this.isActive,
    required this.isSelected,
    required this.palette,
    required this.l10n,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChatoraiBorderRadius.sm),
      child: Container(
        color: isSelected ? palette.navItemSelected : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChatoraiSpacing.lg,
            vertical: ChatoraiSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: ChatoraiIconSizes.md,
                color: isActive ? ChatoraiColors.orange : palette.textMuted,
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.basename(path),
                      style: TextStyle(
                        color: palette.text,
                        fontSize: ChatoraiFontSizes.base,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    Text(
                      path,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: ChatoraiFontSizes.sm,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.removeDirectory,
                  onPressed: onDelete,
                  splashRadius: ChatoraiSizes.iconButtonSplashRadius,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: ChatoraiIconSizes.md,
                  color: palette.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
