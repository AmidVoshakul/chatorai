import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatorai/features/agents/data/models/agent_registry.dart';
import 'package:chatorai/features/chat/presentation/widgets/agent_mention_popup.dart';
import 'popup_controller.dart';

mixin AgentMentionHandler<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  String _agentQuery = '';
  int _selectedAgentIndex = 0;

  TextEditingController get textController;
  PopupController get popupController;
  GlobalKey get textFieldKey;

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
    if (!mounted) return;

    popupController.hideAllPopups();

    final overlay = Overlay.of(context);
    final textFieldBox = textFieldKey.currentContext?.findRenderObject() as RenderBox?;
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
                onTap: hideAgentPopup,
              ),
            ),
            // Popup
            Positioned(
              bottom: bottom,
              left: left,
              width: popupWidth,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: AgentMentionPopup(
                  agents: filteredAgents(),
                  selectedIndex: _selectedAgentIndex,
                  onSelected: (agent) {
                    insertAgentMention(agent);
                    hideAgentPopup();
                  },
                  onClose: hideAgentPopup,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    popupController.setOverlay(PopupType.agent, entry);
    overlay.insert(entry);
  }

  void hideAgentPopup() {
    popupController.hidePopup(PopupType.agent);
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
  }

  void navigateAgentPopup(bool down) {
    final agents = filteredAgents();
    if (agents.isEmpty) return;
    final newIndex = down
        ? _selectedAgentIndex + 1
        : _selectedAgentIndex - 1;
    if (newIndex >= 0 && newIndex < agents.length) {
      _selectedAgentIndex = newIndex;
      _updateAgentPopup();
    }
  }

  void _updateAgentPopup() {
    final entry = popupController.getOverlay(PopupType.agent);
    entry?.markNeedsBuild();
  }

  void selectCurrentAgent() {
    final agents = filteredAgents();
    if (_selectedAgentIndex >= 0 && _selectedAgentIndex < agents.length) {
      insertAgentMention(agents[_selectedAgentIndex]);
    }
  }

  bool get isAgentPopupVisible => popupController.isPopupVisible(PopupType.agent);

  void detectAgentMentionListener() => _detectAgentMention();

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
}
