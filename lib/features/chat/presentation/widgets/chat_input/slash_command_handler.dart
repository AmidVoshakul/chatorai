// Config and Permission
// Agents
import 'package:chatorai/core/agents/agent_provider.dart'
    show currentAgentProvider;
import 'package:chatorai/core/config/config_provider.dart';
import 'package:chatorai/core/permission/permission_provider.dart';
import 'package:chatorai/core/permission/permission_service.dart';
import 'package:chatorai/core/permission/ruleset.dart';
// Skills
import 'package:chatorai/core/skills/skill_info.dart';
import 'package:chatorai/core/skills/skill_providers.dart'
    show skillServiceProvider;
import 'package:chatorai/core/skills/skill_service.dart';
// Chat models and providers
import 'package:chatorai/features/chat/data/models/chat_models.dart';
import 'package:chatorai/features/chat/data/providers/chat_providers.dart';
// Models (for selectedModelId)
import 'package:chatorai/features/models/providers/model_provider.dart'
    show modelProvider;
import 'package:chatorai/l10n/app_localizations.dart';
import 'package:chatorai/shared/utils/snackbar_utils.dart';
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

  // Extended command palette
  final List<SlashCommand> _allCommands = const [
    SlashCommand('/skills', 'Show available skills'),
    SlashCommand('/new', 'Start a new chat'),
    SlashCommand('/clear', 'Clear current chat'),
    SlashCommand('/compact', 'Compress conversation context'),
    SlashCommand('/help', 'Show help'),
    SlashCommand('/undo', 'Undo last action'),
    SlashCommand('/redo', 'Redo last undone action'),
    SlashCommand('/sessions', 'List sessions'),
    SlashCommand('/models', 'Select model'),
    SlashCommand('/theme', 'Change theme'),
  ];

  List<SlashCommand> get _filteredCommands {
    if (_commandQuery.isEmpty) return _allCommands;
    final q = _commandQuery.toLowerCase();
    return _allCommands
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q),
        )
        .toList();
  }

  TextEditingController get textController;
  PopupController get popupController;
  VoidCallback? get onMessageAdded;
  GlobalKey get textFieldKey;
  ScrollController get commandScrollController;
  ScrollController get skillsScrollController;
  // ref is inherited from ConsumerState

  @override
  void initState() {
    super.initState();
    _loadSkillService();
  }

  Future<void> _loadSkillService() async {
    if (_skillService != null) return;
    try {
      final service = await ref.read(skillServiceProvider.future);
      _skillService = service;
      debugPrint('[SlashCommandHandler] SkillService loaded');
    } catch (e) {
      debugPrint('[SlashCommandHandler] Failed to load SkillService: $e');
    }
  }

  void _detectSlashCommand() {
    final text = textController.text;
    final cursorPos = textController.selection.baseOffset;
    debugPrint(
      '[SlashCommandHandler] _detectSlashCommand: text="$text", cursor=$cursorPos',
    );

    if (cursorPos < 0) {
      debugPrint('[SlashCommandHandler] cursor < 0, hiding popups');
      hideCommandPopup();
      hideSkillsPopup();
      return;
    }
    final beforeCursor = text.substring(0, cursorPos);
    final slashIndex = beforeCursor.lastIndexOf('/');
    if (slashIndex != 0) {
      debugPrint(
        '[SlashCommandHandler] slash not at start of input, hiding popups',
      );
      hideCommandPopup();
      hideSkillsPopup();
      return;
    }
    final afterSlash = beforeCursor.substring(slashIndex + 1);
    final command = afterSlash.split(' ').first;
    debugPrint(
      '[SlashCommandHandler] afterSlash="$afterSlash", command="$command"',
    );

    if (command.isEmpty) {
      // Just "/" or "/ " → show command palette
      debugPrint('[SlashCommandHandler] showing command palette');
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
          debugPrint(
            '[SlashCommandHandler] exact /skills matched, showing skills popup',
          );
          _slashQuery = afterSlash.length > 6 ? afterSlash.substring(7) : '';
          showSkillsPopup();
          hideCommandPopup();
        } else {
          // Other exact command → show command palette (filtered to this command)
          debugPrint(
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

        debugPrint(
          '[SlashCommandHandler] partialMatches: ${partialMatches.map((c) => c.name).toList()}',
        );

        if (partialMatches.isEmpty) {
          debugPrint('[SlashCommandHandler] no matches, hiding popups');
          hideCommandPopup();
          hideSkillsPopup();
        } else {
          // Show command palette with partial matches
          debugPrint(
            '[SlashCommandHandler] showing command palette (partial matches)',
          );
          _commandQuery = afterSlash;
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
  }

  void hideCommandPopup() {
    popupController.hidePopup(PopupType.command);
  }

  void navigateCommandPopup(bool down) {
    final cmds = _filteredCommands;
    if (cmds.isEmpty) return;
    final newIndex = down
        ? _selectedCommandIndex + 1
        : _selectedCommandIndex - 1;
    if (newIndex >= 0 && newIndex < cmds.length) {
      _selectedCommandIndex = newIndex;
      _updateCommandPopup();
    }
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
    final newText =
        '${beforeCursor.substring(0, slashIndex)}${cmd.name} $afterCursor';
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: slashIndex + cmd.name.length + 1,
      ),
    );

    hideCommandPopup();

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
      debugPrint(
        '[SlashCommandHandler] Loading skills for agent: ${currentAgent.id}',
      );
      final allSkills = await _skillService!.listAll();
      final allowedSkills = await _skillService!.availableForAgent(
        currentAgent.id,
      );
      _allowedSkillNames = allowedSkills.map((s) => s.name).toSet();
      _allSkills = allSkills;
      debugPrint(
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
  }

  void hideSkillsPopup() {
    popupController.hidePopup(PopupType.skills);
  }

  void navigateSkillsPopup(bool down) {
    final skills = _filteredSkills;
    if (skills.isEmpty) return;
    final newIndex = down ? _selectedSkillIndex + 1 : _selectedSkillIndex - 1;
    if (newIndex >= 0 && newIndex < skills.length) {
      _selectedSkillIndex = newIndex;
      _updateSkillsPopup();
    }
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
      debugPrint(
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
        debugPrint(
          '[SlashCommandHandler] Permission granted for skill ${skill.name}',
        );
      } on PermissionDeniedError catch (e) {
        debugPrint(
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
        debugPrint(
          '[SlashCommandHandler] Permission rejected for skill ${skill.name}: $e',
        );
        return;
      } catch (e) {
        debugPrint(
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

  /// Render skill content with argument substitution.
  /// Supports $1, $2, $N (last $N gets all remaining args), $ARGUMENTS.
  String _renderSkillContent(String content, String arguments) {
    final argsRegex = RegExp(
      r"""(?:\[Image\s+\d+\]|"[^"]*"|'[^']*'|[^\s"']+)""",
    );
    final List<String> rawArgs = argsRegex
        .allMatches(arguments)
        .map((m) => m.group(0)!)
        .toList();
    final quoteTrim = RegExp("""^["']|["']\$""");
    final List<String> args = rawArgs
        .map((a) => a.replaceAll(quoteTrim, ''))
        .toList();

    final placeholderRegex = RegExp(r"""\$(\d+)""");
    final matches = placeholderRegex.allMatches(content).toList();
    final List<int> placeholders = matches
        .map((m) => int.parse(m.group(1)!))
        .toList();
    final last = placeholders.isEmpty
        ? 0
        : placeholders.reduce((a, b) => a > b ? a : b);

    var result = content.replaceAllMapped(placeholderRegex, (match) {
      final position = int.parse(match.group(1)!);
      final argIndex = position - 1;
      if (argIndex >= args.length) return '';
      if (position == last) {
        return args.sublist(argIndex).join(' ');
      }
      return args[argIndex];
    });

    final usesArguments = content.contains(r'$ARGUMENTS');
    result = result.replaceAll(r'$ARGUMENTS', arguments);

    if (placeholders.isEmpty && !usesArguments && arguments.trim().isNotEmpty) {
      result = '$result\n\n$arguments';
    }

    return result.trim();
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
    String content;
    if (afterSkill.isEmpty) {
      // No args → insert skill content directly without AI
      content = '**Loaded skill: ${skill.name}**\n\n${skill.content}';
    } else {
      // Has args → render template with arguments
      content = _renderSkillContent(skill.content, afterSkill);
    }

    return (content: content, skill: skill);
  }

  /// Insert skill content into chat history without triggering AI response.
  Future<void> insertSkillMessage(SkillInfo skill, String content) async {
    debugPrint('[SlashCommandHandler] Inserting skill: ${skill.name}');
    final storage = ref.read(chatStorageServiceProvider);
    final chatIdNotifier = ref.read(currentChatIdProvider.notifier);
    final chatListNotifier = ref.read(chatListProvider.notifier);
    final modelId = ref.read(modelProvider).selectedModelId;

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
      await storage.addMessageToChat(newChat.id, message);
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
      await storage.addMessageToChat(chat.id, message);
      final updatedChat = chat.copyWith(
        messages: [...chat.messages, message],
        updatedAt: DateTime.now(),
      );
      chatListNotifier.updateChat(updatedChat);
    }

    debugPrint('[SlashCommandHandler] Skill inserted: ${skill.name}');
    onMessageAdded?.call();

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
