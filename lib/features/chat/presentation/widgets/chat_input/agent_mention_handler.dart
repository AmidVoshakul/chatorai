import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/shared/theme/app_theme.dart';
import 'package:chatorai/features/agents/data/models/agent_registry.dart';
import 'package:chatorai/features/chat/presentation/widgets/agent_mention_popup.dart';

mixin AgentMentionHandler<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  String _agentQuery = '';
  int _selectedAgentIndex = 0;
  OverlayEntry? _agentOverlay;

  TextEditingController get textController;

  void _detectAgentMention() {
    final text = textController.text;
    final cursorPos = textController.selection.baseOffset;
    if (cursorPos < 0) {
      hideAgentPopup();
      return;
    }
    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex == -1 ||
        (atIndex > 0 && beforeCursor[atIndex - 1] != ' ' && atIndex != 0)) {
      hideAgentPopup();
      return;
    }
    final query = beforeCursor.substring(atIndex + 1);
    if (query.contains(' ')) {
      hideAgentPopup();
      return;
    }
    _agentQuery = query;
    _selectedAgentIndex = 0;
    showAgentPopup();
  }

  List<AgentDefinition> filteredAgents() {
    final all = AgentRegistry().getSubagents();
    if (_agentQuery.isEmpty) return all.take(10).toList();
    final q = _agentQuery.toLowerCase();
    return all
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              (a.description?.toLowerCase().contains(q) ?? false),
        )
        .take(10)
        .toList();
  }

  void showAgentPopup() {
    if (_agentOverlay != null) return;
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final inputBox = context.findRenderObject() as RenderBox?;
    if (inputBox == null) return;
    final inputOffset = inputBox.localToGlobal(Offset.zero);
    _agentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height - inputOffset.dy + 8,
        left: inputOffset.dx + ChatoraiSpacing.lg,
        width: 340,
        child: AgentMentionPopup(
          agents: filteredAgents(),
          selectedIndex: _selectedAgentIndex,
          onSelected: insertAgentMention,
        ),
      ),
    );
    overlay.insert(_agentOverlay!);
  }

  void hideAgentPopup() {
    _agentOverlay?.remove();
    _agentOverlay = null;
  }

  void insertAgentMention(AgentDefinition agent) {
    final text = textController.text;
    final cursorPos = textController.selection.baseOffset;
    if (cursorPos < 0) return;
    final beforeCursor = text.substring(0, cursorPos);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex == -1) return;
    final afterCursor = text.substring(cursorPos);
    final newText = '${text.substring(0, atIndex)}@${agent.id} $afterCursor';
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + agent.id.length + 2),
    );
    hideAgentPopup();
  }

  void navigateAgentPopup(bool down) {
    final agents = filteredAgents();
    if (agents.isEmpty) return;
    if (down) {
      _selectedAgentIndex = (_selectedAgentIndex + 1) % agents.length;
    } else {
      _selectedAgentIndex =
          (_selectedAgentIndex - 1 + agents.length) % agents.length;
    }
    setState(() {});
    _refreshAgentPopup();
  }

  void _refreshAgentPopup() {
    hideAgentPopup();
    showAgentPopup();
  }

  void selectCurrentAgent() {
    final agents = filteredAgents();
    if (_selectedAgentIndex < agents.length) {
      insertAgentMention(agents[_selectedAgentIndex]);
    }
  }

  bool get isAgentPopupVisible => _agentOverlay != null;

  void detectAgentMentionListener() => _detectAgentMention();
}
