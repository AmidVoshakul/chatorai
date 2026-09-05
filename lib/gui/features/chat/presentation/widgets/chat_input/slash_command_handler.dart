// Config and Permission
// Agents
import 'package:chatorai/core/agents/agent_provider.dart'
    show currentAgentProvider;
import 'package:chatorai/core/commands/command_parser.dart';
import 'package:chatorai/core/commands/command_providers.dart';
import 'package:chatorai/core/commands/skill_command_resolver.dart';
import 'package:chatorai/core/commands/slash_command.dart';
import 'package:chatorai/core/commands/slash_command_catalog.dart';
import 'package:chatorai/core/commands/slash_command_executor.dart';
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
// Session repository
import 'package:chatorai/core/session/events.dart';
import 'package:chatorai/core/session/session_db_provider.dart';
// Skills
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_providers.dart'
    show skillServiceProvider;
import 'package:chatorai/core/skills/skill_service.dart';
// Chat models and providers
import 'package:chatorai/core/chat/chat_models.dart';
import 'package:chatorai/gui/features/chat/data/providers/chat_providers.dart';
// Models (for selectedModelId)
import 'package:chatorai/gui/features/models/providers/model_provider.dart'
    show modelProvider;
import 'package:chatorai/gui/shared/theme/theme_provider.dart';
import 'package:chatorai/gui/shared/utils/snackbar_utils.dart';
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'command_popup.dart';
import 'popup_controller.dart';
// Popup widgets
import 'skills_popup.dart';

mixin SlashCommandHandler<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  // Skill service and cache
  SkillService? _skillService;
  String _slashQuery = '';
  int _selectedSkillIndex = 0;
  List<SkillInfo> _allSkills = [];
  Set<String> _allowedSkillNames = {};
  String? _lastAgentId;

  // Command popup state
  int _selectedCommandIndex = 0;
  String _commandQuery = '';

  // Adapter to bridge generated AppLocalizations to core interface.
  SlashCommandLocalizations? get _coreLocalizations {
    final loc = AppLocalizations.of(context);
    if (loc == null) return null;
    return _AppLocalizationsAdapter(loc);
  }

  List<SlashCommand> _localizedBuiltinCommands() =>
      SlashCommandCatalog.builtIns(_coreLocalizations);

  /// Built-ins plus file-defined commands from the global and project config
  /// roots. Custom entries are mapped eagerly so the palette stays
  /// synchronous; unknown-yet loads simply contribute nothing.
  List<SlashCommand> get _allCommands {
    final custom = ref.read(customCommandsProvider).value;
    if (custom == null || custom.isEmpty) return _localizedBuiltinCommands();
    return [
      ..._localizedBuiltinCommands(),
      ...custom.map(SlashCommandCatalog.fromCommandInfo),
    ];
  }

  List<SlashCommand> get _filteredCommands =>
      SlashCommandCatalog.filter(_allCommands, _commandQuery);

  TextEditingController get textController;
  PopupController get popupController;
  GlobalKey get textFieldKey;
  ScrollController get commandScrollController;
  ScrollController get skillsScrollController;
  Future<void> Function()? get onCompact;
  ValueChanged<bool>? get onPopupVisibilityChanged;
  // ref is inherited from ConsumerState

  @override
  void initState() {
    super.initState();
    _loadSkillService();
    // Warm the custom-command cache so the palette shows them on first '/'.
    ref.read(customCommandsProvider.future).ignore();
  }

  /// Must be called from `build()` (Riverpod forbids `ref.listen` in
  /// `initState`). Re-fetches skills when the service is rebuilt (e.g. after
  /// a marketplace install/uninstall invalidates [skillServiceProvider]), so
  /// `/skills` shows fresh data without an app restart.
  void listenForSkillChanges() {
    ref.listen<AsyncValue<SkillService>>(skillServiceProvider, (prev, next) {
      if (prev == null || !next.hasValue) return;
      _skillService = next.value;
      _allSkills = [];
      _allowedSkillNames.clear();
    });
  }

  /// Must be called from `build()` (same rule as [listenForSkillChanges]).
  /// Re-renders the input when custom commands change on disk so the palette
  /// getter (which reads the provider eagerly) is refreshed deterministically
  /// instead of relying on incidental rebuilds from typing.
  void listenForCustomCommands() {
    ref.listen<AsyncValue<List<CommandInfo>>>(customCommandsProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _loadSkillService() async {
    if (_skillService != null) return;
    try {
      final service = await ref.read(skillServiceProvider.future);
      _skillService = service;
      LogTags.chat.logDebug('[SlashCommandHandler] SkillService loaded');
    } catch (e) {
      LogTags.chat.logDebug(
        '[SlashCommandHandler] Failed to load SkillService: $e',
      );
    }
  }

  void _detectSlashCommand() {
    final text = textController.text;
    final cursorPos = textController.selection.baseOffset;
    LogTags.chat.logDebug(
      '[SlashCommandHandler] _detectSlashCommand: text="$text", cursor=$cursorPos',
    );

    if (cursorPos < 0) {
      LogTags.chat.logDebug('[SlashCommandHandler] cursor < 0, hiding popups');
      hideCommandPopup();
      hideSkillsPopup();
      return;
    }
    final beforeCursor = text.substring(0, cursorPos);
    final slashIndex = beforeCursor.lastIndexOf('/');
    if (slashIndex != 0) {
      LogTags.chat.logDebug(
        '[SlashCommandHandler] slash not at start of input, hiding popups',
      );
      hideCommandPopup();
      hideSkillsPopup();
      return;
    }
    final afterSlash = beforeCursor.substring(slashIndex + 1);
    final command = afterSlash.split(' ').first;
    LogTags.chat.logDebug(
      '[SlashCommandHandler] afterSlash="$afterSlash", command="$command"',
    );

    if (command.isEmpty) {
      // Just "/" or "/ " → show command palette
      LogTags.chat.logDebug('[SlashCommandHandler] showing command palette');
      _commandQuery = afterSlash;
      _selectedCommandIndex = 0;
      showCommandPopup();
      hideSkillsPopup();
    } else {
      // Check for exact command match first
      SlashCommand? exactCmd;
      for (final c in _allCommands) {
        if (c.name == '/$command') {
          exactCmd = c;
          break;
        }
      }

      if (exactCmd != null) {
        // Exact match found
        if (exactCmd.name == '/skills') {
          // Exact /skills → show skills popup with optional filter
          LogTags.chat.logDebug(
            '[SlashCommandHandler] exact /skills matched, showing skills popup',
          );
          const skillsName = 'skills';
          _slashQuery = afterSlash.length > skillsName.length
              ? afterSlash.substring(skillsName.length + 1).trimLeft()
              : '';
          showSkillsPopup();
          hideCommandPopup();
        } else if (afterSlash.contains(' ')) {
          // Arguments are being typed after a complete command name — the
          // palette has served its purpose and must stay out of the way.
          hideCommandPopup();
          hideSkillsPopup();
        } else {
          // Complete name, no arguments yet → keep the single candidate visible
          LogTags.chat.logDebug(
            '[SlashCommandHandler] exact command ${exactCmd.name} matched, showing command palette',
          );
          _commandQuery = afterSlash;
          _selectedCommandIndex = 0;
          showCommandPopup();
          hideSkillsPopup();
        }
      } else {
        // No exact match: check for partial matches (name OR description)
        final partialMatches = _allCommands.where((c) {
          final nameLower = c.name.toLowerCase();
          final descLower = c.description.toLowerCase();
          final queryLower = command.toLowerCase();
          return nameLower.startsWith('/$queryLower') ||
              nameLower.contains(queryLower) ||
              descLower.contains(queryLower);
        }).toList();

        LogTags.chat.logDebug(
          '[SlashCommandHandler] partialMatches: ${partialMatches.map((c) => c.name).toList()}',
        );

        if (partialMatches.isEmpty) {
          LogTags.chat.logDebug(
            '[SlashCommandHandler] no matches, hiding popups',
          );
          hideCommandPopup();
          hideSkillsPopup();
        } else {
          // Show command palette with partial matches — filter by first word only
          LogTags.chat.logDebug(
            '[SlashCommandHandler] showing command palette (partial matches)',
          );
          _commandQuery = command;
          _selectedCommandIndex = 0;
          showCommandPopup();
          hideSkillsPopup();
        }
      }
    }
  }

  // ===========================================================================
  // COMMAND POPUP
  // ===========================================================================

  void showCommandPopup() {
    if (!mounted) return;
    popupController.hideAllPopups();

    final overlay = Overlay.of(context);
    final textFieldBox =
        textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    final inputOffset = textFieldBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottom = screenHeight - inputOffset.dy + 8;
    final popupWidth = textFieldBox.size.width;
    final left = inputOffset.dx;

    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Stack(
          children: [
            // Barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: hideCommandPopup,
              ),
            ),
            // Popup
            Positioned(
              bottom: bottom,
              left: left,
              width: popupWidth,
              child: CommandPopup(
                commands: _filteredCommands,
                selectedIndex: _selectedCommandIndex,
                scrollController: commandScrollController,
                onSelected: _selectCommand,
                filter: _commandQuery,
                onClose: hideCommandPopup,
              ),
            ),
          ],
        ),
      ),
    );

    popupController.setOverlay(PopupType.command, entry);
    overlay.insert(entry);
    _notifyPopupVisibility();
  }

  void _notifyPopupVisibility() {
    final anyVisible =
        popupController.isPopupVisible(PopupType.command) ||
        popupController.isPopupVisible(PopupType.skills) ||
        popupController.isPopupVisible(PopupType.agent);
    onPopupVisibilityChanged?.call(anyVisible);
  }

  void hideCommandPopup() {
    popupController.hidePopup(PopupType.command);
    _notifyPopupVisibility();
  }

  void navigateCommandPopup(bool down) {
    final cmds = _filteredCommands;
    if (cmds.isEmpty) return;
    final len = cmds.length;
    _selectedCommandIndex = down
        ? (_selectedCommandIndex + 1) % len
        : (_selectedCommandIndex - 1 + len) % len;
    _updateCommandPopup();
  }

  void _updateCommandPopup() {
    final entry = popupController.getOverlay(PopupType.command);
    entry?.markNeedsBuild();
  }

  void _selectCommand(SlashCommand cmd) async {
    final text = textController.text;
    final cursorPos = textController.selection.baseOffset;
    if (cursorPos < 0) return;
    final beforeCursor = text.substring(0, cursorPos);
    final slashIndex = beforeCursor.lastIndexOf('/');
    if (slashIndex == -1) return;
    final afterCursor = text.substring(cursorPos);

    hideCommandPopup();

    final executorCtx = SlashCommandExecutorContext(
      onCompact: onCompact,
      onCreateNewChat: () async {
        final newChat = await ref
            .read(chatListProvider.notifier)
            .createNewChat();
        ref.read(currentChatIdProvider.notifier).setChatId(newChat.id);
        ref.read(permissionServiceProvider).clearSession();
      },
      onSetExpandReasoning: (newValue) => ref
          .read(themeProvider.notifier)
          .setExpandReasoningByDefault(newValue),
      expandReasoningCurrent: ref.read(themeProvider).expandReasoningByDefault,
      clearInput: textController.clear,
    );
    final execResult = await SlashCommandExecutor.execute(cmd, executorCtx);
    if (execResult.handled) return;

    final newText =
        '${beforeCursor.substring(0, slashIndex)}${cmd.name} $afterCursor';
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: slashIndex + cmd.name.length + 1,
      ),
    );

    // If command is /skills, trigger skills popup
    if (cmd.name == '/skills') {
      _slashQuery = '';
      await Future.microtask(() => showSkillsPopup());
    }
  }

  void selectCurrentCommand() {
    final cmds = _filteredCommands;
    if (_selectedCommandIndex >= 0 && _selectedCommandIndex < cmds.length) {
      _selectCommand(cmds[_selectedCommandIndex]);
    }
  }

  bool get isCommandPopupVisible =>
      popupController.isPopupVisible(PopupType.command);

  // ===========================================================================
  // SKILLS POPUP
  // ===========================================================================

  Future<void> showSkillsPopup() async {
    if (!mounted) return;
    popupController.hideAllPopups();

    await _loadSkillService();
    if (!mounted) return;

    final currentAgent = ref.read(currentAgentProvider);
    if (_lastAgentId != currentAgent.id) {
      _allSkills = [];
      _allowedSkillNames.clear();
      _lastAgentId = currentAgent.id;
    }

    if (_allSkills.isEmpty) {
      if (_skillService == null) {
        LogTags.chat.logDebug(
          '[SlashCommandHandler] SkillService not available, cannot load skills',
        );
        return;
      }
      LogTags.chat.logDebug(
        '[SlashCommandHandler] Loading skills for agent: ${currentAgent.id}',
      );
      final allSkills = await _skillService!.listAll();
      final allowedSkills = await _skillService!.availableForAgent(
        currentAgent.id,
      );
      _allowedSkillNames = allowedSkills.map((s) => s.name).toSet();
      _allSkills = allSkills;
      LogTags.chat.logDebug(
        '[SlashCommandHandler] Loaded ${allSkills.length} skills (${allowedSkills.length} allowed)',
      );
      if (!mounted) return;
    }

    _selectedSkillIndex = 0;

    final overlay = Overlay.of(context);
    final textFieldBox =
        textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    final inputOffset = textFieldBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final bottom = screenHeight - inputOffset.dy + 8;
    final popupWidth = textFieldBox.size.width;
    final left = inputOffset.dx;

    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: hideSkillsPopup,
              ),
            ),
            Positioned(
              bottom: bottom,
              left: left,
              width: popupWidth,
              child: SkillsPopup(
                skills: _allSkills,
                allowedSkillNames: _allowedSkillNames,
                selectedIndex: _selectedSkillIndex,
                scrollController: skillsScrollController,
                onSelected: (skill) {
                  hideSkillsPopup();
                  selectCurrentSkill(skill);
                },
                filter: _slashQuery,
                onClose: hideSkillsPopup,
                isLoading: _skillService == null,
              ),
            ),
          ],
        ),
      ),
    );

    popupController.setOverlay(PopupType.skills, entry);
    overlay.insert(entry);
    _notifyPopupVisibility();
  }

  void hideSkillsPopup() {
    popupController.hidePopup(PopupType.skills);
    _notifyPopupVisibility();
  }

  void navigateSkillsPopup(bool down) {
    final skills = _filteredSkills;
    if (skills.isEmpty) return;
    final len = skills.length;
    _selectedSkillIndex = down
        ? (_selectedSkillIndex + 1) % len
        : (_selectedSkillIndex - 1 + len) % len;
    _updateSkillsPopup();
  }

  void _updateSkillsPopup() {
    final entry = popupController.getOverlay(PopupType.skills);
    entry?.markNeedsBuild();
  }

  List<SkillInfo> get _filteredSkills {
    if (_slashQuery.isEmpty) return _allSkills;
    final q = _slashQuery.toLowerCase();
    return _allSkills
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> selectCurrentSkill(SkillInfo skill) async {
    final isAllowed = _allowedSkillNames.contains(skill.name);
    if (!isAllowed) {
      LogTags.chat.logDebug(
        '[SlashCommandHandler] Skill ${skill.name} requires permission, requesting...',
      );
      try {
        final permissionService = ref.read(permissionServiceProvider);
        final config = await ref.read(configProvider.future);
        final rulesList = PermissionRuleset.fromConfig(
          config.permission as Map<String, dynamic>,
        );
        final ruleset = PermissionRuleset(rules: rulesList);

        final request = PermissionRequest(
          id: 'skill_${skill.name}_${DateTime.now().millisecondsSinceEpoch}',
          toolName: 'skill',
          permission: 'skill',
          patterns: ['skill:name=${skill.name}'],
          metadata: {'skillName': skill.name},
        );

        await permissionService.ask(request, ruleset);
        _allowedSkillNames.add(skill.name);
        LogTags.chat.logDebug(
          '[SlashCommandHandler] Permission granted for skill ${skill.name}',
        );
      } on PermissionDeniedError catch (e) {
        LogTags.chat.logDebug(
          '[SlashCommandHandler] Permission denied for skill ${skill.name}: $e',
        );
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context: context,
            message: 'Permission denied for skill: ${skill.name}',
            duration: const Duration(seconds: 2),
          );
        }
        return;
      } on PermissionRejectedError catch (e) {
        LogTags.chat.logDebug(
          '[SlashCommandHandler] Permission rejected for skill ${skill.name}: $e',
        );
        return;
      } catch (e) {
        LogTags.chat.logDebug(
          '[SlashCommandHandler] Error requesting permission for skill ${skill.name}: $e',
        );
        return;
      }
    }

    _insertSkillCommand(skill.name);
  }

  void _insertSkillCommand(String skillName) {
    final text = textController.text;
    final cursorPos = textController.selection.baseOffset;
    if (cursorPos < 0) return;
    final beforeCursor = text.substring(0, cursorPos);
    final slashIndex = beforeCursor.lastIndexOf('/');
    if (slashIndex == -1) return;
    final afterCursor = text.substring(cursorPos);
    final newText =
        '${beforeCursor.substring(0, slashIndex)}/$skillName $afterCursor';
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: slashIndex + skillName.length + 2,
      ),
    );
  }

  void selectCurrentSkillFromPopup() {
    final skills = _filteredSkills;
    if (_selectedSkillIndex >= 0 && _selectedSkillIndex < skills.length) {
      selectCurrentSkill(skills[_selectedSkillIndex]);
    }
  }

  /// Check if text starts with a skill command and return rendered content.
  /// Returns null if not a skill command.
  /// When [hasArgs] is false, the skill is inserted without AI response.
  Future<({String content, SkillInfo skill})?> resolveSkillCommand(
    String text,
  ) async {
    final match = RegExp(r'^/(\S+)').firstMatch(text);
    if (match == null) return null;

    final skillName = match.group(1)!;
    final service = _skillService;
    if (service == null) return null;

    final skill = await service.getByName(skillName);
    if (skill == null) return null;

    final afterSkill = text.substring(match.end).trim();
    final content = SkillCommandResolver.resolve(skill, afterSkill);

    return (content: content, skill: skill);
  }

  /// Insert skill content into chat history without triggering AI response.
  Future<void> insertSkillMessage(SkillInfo skill, String content) async {
    LogTags.chat.logDebug(
      '[SlashCommandHandler] Inserting skill: ${skill.name}',
    );
    final chatIdNotifier = ref.read(currentChatIdProvider.notifier);
    final chatListNotifier = ref.read(chatListProvider.notifier);
    final modelId = ref.read(modelProvider).selectedModelId;
    final sessionRepository = await ref.read(sessionRepositoryProvider.future);

    final chat = ref.read(currentChatProvider);
    Message message;
    if (chat == null) {
      final newChat = await chatListNotifier.createNewChat();
      chatIdNotifier.setChatId(newChat.id);
      message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        isComplete: true,
        model: modelId,
      );
      final sessionId = newChat.toSessionId();
      await sessionRepository.appendEvent(
        MessageAdded(
          sessionId: sessionId,
          messageId: message.id,
          role: message.role.name,
          content: message.content,
          timestamp: message.timestamp,
        ),
      );
      final updatedChat = newChat.copyWith(
        messages: [message],
        updatedAt: DateTime.now(),
      );
      chatListNotifier.updateChat(updatedChat);
    } else {
      message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
        isComplete: true,
        model: modelId,
      );
      final sessionId = chat.toSessionId();
      await sessionRepository.appendEvent(
        MessageAdded(
          sessionId: sessionId,
          messageId: message.id,
          role: message.role.name,
          content: message.content,
          timestamp: message.timestamp,
        ),
      );
      final updatedChat = chat.copyWith(
        messages: [...chat.messages, message],
        updatedAt: DateTime.now(),
      );
      chatListNotifier.updateChat(updatedChat);
    }

    LogTags.chat.logDebug(
      '[SlashCommandHandler] Skill inserted: ${skill.name}',
    );

    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      SnackbarUtils.showSuccessSnackBar(
        context: context,
        message: localizations.skillExecuted(skill.name),
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool get isSkillsPopupVisible =>
      popupController.isPopupVisible(PopupType.skills);

  void detectSlashCommandListener() => _detectSlashCommand();
}

class _AppLocalizationsAdapter implements SlashCommandLocalizations {
  final AppLocalizations _loc;
  _AppLocalizationsAdapter(this._loc);

  @override
  String get slashCommandClear => _loc.slashCommandClear;
  @override
  String get slashCommandCompact => _loc.slashCommandCompact;
  @override
  String get slashCommandHelp => _loc.slashCommandHelp;
  @override
  String get slashCommandModels => _loc.slashCommandModels;
  @override
  String get slashCommandNew => _loc.slashCommandNew;
  @override
  String get slashCommandRedo => _loc.slashCommandRedo;
  @override
  String get slashCommandSessions => _loc.slashCommandSessions;
  @override
  String get slashCommandSkills => _loc.slashCommandSkills;
  @override
  String get slashCommandTheme => _loc.slashCommandTheme;
  @override
  String get slashCommandThinking => _loc.slashCommandThinking;
  @override
  String get slashCommandUndo => _loc.slashCommandUndo;
}
