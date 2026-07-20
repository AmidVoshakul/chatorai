import 'package:chatorai/core/config/instructions_resolver.dart';
import 'package:chatorai/features/settings/providers/instructions_management_provider.dart';
import 'package:chatorai/features/settings/widgets/premium_blocks.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Premium GUI for reviewing, adding and editing the instruction files that
/// feed every prompt: auto-detected `AGENTS.md` / `CLAUDE.md` cards plus the
/// explicit `instructions[]` array of `chatorai.json`.
///
/// Backed by [instructionsManagementProvider]; every change persists to disk
/// and invalidates the resolved instructions so a running chat picks it up
/// without an app restart.
class AgentsInstructionsScreen extends ConsumerStatefulWidget {
  const AgentsInstructionsScreen({super.key});

  @override
  ConsumerState<AgentsInstructionsScreen> createState() =>
      _AgentsInstructionsScreenState();
}

class _AgentsInstructionsScreenState
    extends ConsumerState<AgentsInstructionsScreen> {
  InstructionsManagementNotifier get _notifier =>
      ref.read(instructionsManagementProvider.notifier);

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _uploadFile(InstructionsScope scope) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown', 'txt'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      await _notifier.addFileInstruction(path, scope: scope);
      _showSuccess(l10n.instructionsAddedFile(p.basename(path)));
    } catch (e) {
      _showError(l10n.instructionsSaveError(e.toString()));
    }
  }

  Future<void> _openDiscovered(DiscoveredInstructionFile file) async {
    final l10n = AppLocalizations.of(context)!;
    String initial;
    try {
      initial = await _notifier.readDiscoveredFile(file.path);
    } catch (e) {
      _showError(l10n.instructionsSaveError(e.toString()));
      return;
    }
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => FileEditorDialog(
        title: file.name,
        subtitle: file.path,
        initialContent: initial,
        readOnly: !file.editable,
        hintText: l10n.agentsMdHint,
      ),
    );
    if (result == null) return; // cancelled or read-only close

    try {
      await _notifier.saveDiscoveredAgents(file.path, result);
      _showSuccess(l10n.agentsMdSaved);
    } catch (e) {
      _showError(l10n.instructionsSaveError(e.toString()));
    }
  }

  Future<void> _createProjectAgents() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => FileEditorDialog(
        title: 'AGENTS.md',
        subtitle: l10n.instructionsScopeProject,
        initialContent: '',
        readOnly: false,
        hintText: l10n.agentsMdHint,
      ),
    );
    if (result == null) return;
    try {
      await _notifier.createProjectAgents(result);
      _showSuccess(l10n.agentsMdSaved);
    } catch (e) {
      _showError(l10n.instructionsSaveError(e.toString()));
    }
  }

  Future<void> _showInlineDialog(InstructionsScope scope) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_InlineResult>(
      context: context,
      builder: (_) => const _InlineInstructionDialog(),
    );
    if (result == null) return;
    try {
      await _notifier.addInlineInstruction(
        result.name,
        result.content,
        scope: scope,
      );
      _showSuccess(l10n.instructionsAddedInline);
    } catch (e) {
      _showError(l10n.instructionsSaveError(e.toString()));
    }
  }

  Future<void> _confirmRemove(String entry, InstructionsScope scope) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.instructionsRemoveTitle),
        content: Text(l10n.instructionsRemoveContent(p.basename(entry))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ChatoraiColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _notifier.removeInstruction(entry, scope: scope);
      _showInfo(l10n.instructionsRemoved);
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    SnackbarUtils.showSuccessSnackBar(context: context, message: message);
  }

  void _showError(String message) {
    if (!mounted) return;
    SnackbarUtils.showErrorSnackBar(context: context, message: message);
  }

  void _showInfo(String message) {
    if (!mounted) return;
    SnackbarUtils.showInfoSnackBar(context: context, message: message);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncState = ref.watch(instructionsManagementProvider);

    return asyncState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.agentsInstructions)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.agentsInstructions)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(ChatoraiSpacing.lg),
            child: Text(l10n.instructionsSaveError(error.toString())),
          ),
        ),
      ),
      data: (state) => _buildScaffold(context, l10n, isDark, state),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    InstructionsManagementState state,
  ) {
    // Mobile (no project scope): a single global view, no tabs.
    if (!state.supportsProjectScope) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.agentsInstructions)),
        body: _ScopeView(
          scope: InstructionsScope.global,
          data: state.global,
          isDark: isDark,
          onOpen: _openDiscovered,
          onCreateProjectAgents: _createProjectAgents,
          onInline: _showInlineDialog,
          onUpload: _uploadFile,
          onRemove: _confirmRemove,
        ),
      );
    }

    // Desktop: Global / Project tabs.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.agentsInstructions),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: hairlineColor(isDark)),
                ),
              ),
              child: TabBar(
                indicatorColor: ChatoraiColors.orange,
                dividerColor: Colors.transparent,
                labelColor: titleColor(isDark),
                unselectedLabelColor: subtleColor(isDark),
                tabs: [
                  Tab(text: l10n.instructionsScopeGlobal),
                  Tab(text: l10n.instructionsScopeProject),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _ScopeView(
              scope: InstructionsScope.global,
              data: state.global,
              isDark: isDark,
              onOpen: _openDiscovered,
              onCreateProjectAgents: _createProjectAgents,
              onInline: _showInlineDialog,
              onUpload: _uploadFile,
              onRemove: _confirmRemove,
            ),
            _ScopeView(
              scope: InstructionsScope.project,
              data: state.project,
              isDark: isDark,
              onOpen: _openDiscovered,
              onCreateProjectAgents: _createProjectAgents,
              onInline: _showInlineDialog,
              onUpload: _uploadFile,
              onRemove: _confirmRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Scope view (Global / Project tab body)
// =============================================================================

class _ScopeView extends StatelessWidget {
  final InstructionsScope scope;
  final ScopeInstructions data;
  final bool isDark;
  final void Function(DiscoveredInstructionFile) onOpen;
  final VoidCallback onCreateProjectAgents;
  final void Function(InstructionsScope) onInline;
  final void Function(InstructionsScope) onUpload;
  final void Function(String, InstructionsScope) onRemove;

  const _ScopeView({
    required this.scope,
    required this.data,
    required this.isDark,
    required this.onOpen,
    required this.onCreateProjectAgents,
    required this.onInline,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isProject = scope == InstructionsScope.project;

    return ListView(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      children: [
        // Auto-detected files.
        SectionTitle(
          title: l10n.instructionsAutoDetectedTitle,
          helper: l10n.instructionsAutoDetectedHelper,
          isDark: isDark,
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        if (data.discovered.isEmpty && isProject)
          _CreateAgentsCard(isDark: isDark, onCreate: onCreateProjectAgents)
        else
          CardGrid(
            children: [
              for (final file in data.discovered)
                _DiscoveredCard(
                  file: file,
                  isDark: isDark,
                  onTap: () => onOpen(file),
                ),
            ],
          ),

        const SizedBox(height: ChatoraiSpacing.xl),

        // Explicit instruction files.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SectionTitle(
                title: l10n.instructionsSectionTitle,
                helper: l10n.instructionsSectionHelper,
                isDark: isDark,
              ),
            ),
            _AddMenu(
              onInline: () => onInline(scope),
              onUpload: () => onUpload(scope),
            ),
          ],
        ),
        const SizedBox(height: ChatoraiSpacing.md),
        if (data.entries.isEmpty)
          _EmptyInstructions(isDark: isDark)
        else
          CardGrid(
            children: [
              for (final entry in data.entries)
                _InstructionCard(
                  entry: entry,
                  isDark: isDark,
                  onRemove: () => onRemove(entry, scope),
                ),
            ],
          ),
      ],
    );
  }
}

// =============================================================================
// Create-AGENTS.md card (Project tab, when none exists yet)
// =============================================================================

class _CreateAgentsCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCreate;

  const _CreateAgentsCard({required this.isDark, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: premiumCard(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_add_outlined,
                color: ChatoraiColors.orange,
                size: ChatoraiIconSizes.lg,
              ),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(
                'AGENTS.md',
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.lg,
                  fontWeight: FontWeight.w600,
                  color: titleColor(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.instructionsCreateAgents),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Discovered file card (AGENTS.md / CLAUDE.md)
// =============================================================================

class _DiscoveredCard extends StatelessWidget {
  final DiscoveredInstructionFile file;
  final bool isDark;
  final VoidCallback onTap;

  const _DiscoveredCard({
    required this.file,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChatoraiBorderRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(ChatoraiSpacing.lg),
          decoration: premiumCard(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    file.exists
                        ? Icons.description_rounded
                        : Icons.note_add_outlined,
                    color: file.exists
                        ? ChatoraiColors.orange
                        : subtleColor(isDark),
                    size: ChatoraiIconSizes.xxl,
                  ),
                  const Spacer(),
                  Icon(
                    file.editable
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                    size: ChatoraiIconSizes.md,
                    color: subtleColor(isDark),
                  ),
                ],
              ),
              const SizedBox(height: ChatoraiSpacing.sm),
              Text(
                file.name,
                style: TextStyle(
                  fontSize: ChatoraiFontSizes.lg,
                  fontWeight: FontWeight.w700,
                  color: titleColor(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                file.path,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: ChatoraiFontSizes.sm,
                  color: subtleColor(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: ChatoraiSpacing.md),
              Wrap(
                spacing: ChatoraiSpacing.xs,
                runSpacing: ChatoraiSpacing.xs,
                children: [
                  PillBadge(
                    label: file.isGlobal
                        ? l10n.instructionsBadgeGlobal
                        : l10n.instructionsBadgeProject,
                    color: ChatoraiColors.orange,
                    isDark: isDark,
                  ),
                  if (!file.editable)
                    PillBadge(
                      label: l10n.instructionsFileReadOnly,
                      color: subtleColor(isDark),
                      isDark: isDark,
                    ),
                  if (!file.exists)
                    PillBadge(
                      label: l10n.instructionsFileNotCreated,
                      color: subtleColor(isDark),
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Explicit instruction card + add menu + empty state
// =============================================================================

class _AddMenu extends StatelessWidget {
  final VoidCallback onInline;
  final VoidCallback onUpload;

  const _AddMenu({required this.onInline, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<int>(
      tooltip: l10n.instructionsAdd,
      position: PopupMenuPosition.under,
      icon: const Icon(
        Icons.add_circle_rounded,
        color: ChatoraiColors.orange,
        size: ChatoraiIconSizes.xxl,
      ),
      onSelected: (v) => v == 0 ? onInline() : onUpload(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 18),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(l10n.instructionsAddInline),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.upload_file_rounded, size: 18),
              const SizedBox(width: ChatoraiSpacing.sm),
              Text(l10n.instructionsUploadFile),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String entry;
  final bool isDark;
  final VoidCallback onRemove;

  const _InstructionCard({
    required this.entry,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ChatoraiSpacing.lg),
      decoration: premiumCard(isDark),
      child: Row(
        children: [
          const Icon(
            Icons.article_rounded,
            color: ChatoraiColors.orange,
            size: ChatoraiIconSizes.xxl,
          ),
          const SizedBox(width: ChatoraiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.basename(entry),
                  style: TextStyle(
                    fontSize: ChatoraiFontSizes.base,
                    fontWeight: FontWeight.w600,
                    color: titleColor(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ChatoraiFontSizes.sm,
                    color: subtleColor(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            iconSize: ChatoraiIconSizes.lg,
            color: ChatoraiColors.error,
            tooltip: AppLocalizations.of(context)!.commonRemove,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _EmptyInstructions extends StatelessWidget {
  final bool isDark;

  const _EmptyInstructions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChatoraiSpacing.xxl),
      decoration: premiumCard(isDark),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: ChatoraiIconSizes.huge,
            color: subtleColor(isDark),
          ),
          const SizedBox(height: ChatoraiSpacing.md),
          Text(
            l10n.instructionsEmpty,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.lg,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? ChatoraiColors.darkTextColor
                  : ChatoraiColors.lightTextColor,
            ),
          ),
          const SizedBox(height: ChatoraiSpacing.xs),
          Text(
            l10n.instructionsEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ChatoraiFontSizes.base,
              color: subtleColor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineResult {
  final String name;
  final String content;
  const _InlineResult(this.name, this.content);
}

class _InlineInstructionDialog extends StatefulWidget {
  const _InlineInstructionDialog();

  @override
  State<_InlineInstructionDialog> createState() =>
      _InlineInstructionDialogState();
}

class _InlineInstructionDialogState extends State<_InlineInstructionDialog> {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.instructionsAddInline),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.instructionsNameLabel,
                    hintText: l10n.instructionsNameHint,
                  ),
                ),
                const SizedBox(height: ChatoraiSpacing.md),
                TextField(
                  controller: _contentController,
                  minLines: 6,
                  maxLines: 14,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ChatoraiFontSizes.code,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.instructionsContentLabel,
                    hintText: l10n.instructionsContentHint,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ChatoraiColors.orange,
            foregroundColor: ChatoraiColors.pureWhite,
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            final content = _contentController.text;
            if (name.isEmpty || content.trim().isEmpty) return;
            Navigator.pop(context, _InlineResult(name, content));
          },
          child: Text(l10n.commonAdd),
        ),
      ],
    );
  }
}
