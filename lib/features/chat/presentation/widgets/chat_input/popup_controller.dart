import 'package:flutter/material.dart';

/// Types of popups that can be shown in the chat input.
enum PopupType {
  agent,
  command,
  skills,
}

/// Abstract controller for managing popup overlays in ChatInput.
///
/// Centralizes overlay management to eliminate direct OverlayEntry manipulation
/// in mixins and ensures mutual exclusivity between popups.
abstract class PopupController {
  /// Shows a popup of the given [type].
  /// [onClose] is called when the popup is closed (via close button, escape, or outside tap).
  void showPopup(PopupType type, {VoidCallback? onClose});

  /// Hides the popup of the given [type].
  void hidePopup(PopupType type);

  /// Returns true if a popup of the given [type] is currently visible.
  bool isPopupVisible(PopupType type);

  /// Hides all popups.
  void hideAllPopups();

  /// Returns the overlay entry for the given [type], if it exists.
  OverlayEntry? getOverlay(PopupType type);

  /// Sets the overlay entry for the given [type].
  /// Should only be called by the popup builder methods.
  void setOverlay(PopupType type, OverlayEntry entry);
}

/// Implementation of [PopupController] that manages overlays in a ChatInput state.
class ChatInputPopupController implements PopupController {
  final Map<PopupType, OverlayEntry> _overlays = {};
  final Map<PopupType, VoidCallback?> _onCloseCallbacks = {};

  @override
  void showPopup(PopupType type, {VoidCallback? onClose}) {
    // Hide other popups first to maintain mutual exclusivity
    hideAllPopups();

    // Store the onClose callback for this popup
    if (onClose != null) {
      _onCloseCallbacks[type] = onClose;
    }
  }

  @override
  void hidePopup(PopupType type) {
    final entry = _overlays[type];
    if (entry != null) {
      entry.remove();
      _overlays.remove(type);
      _onCloseCallbacks.remove(type);
    }
  }

  @override
  bool isPopupVisible(PopupType type) => _overlays.containsKey(type);

  @override
  void hideAllPopups() {
    for (final type in _overlays.keys.toList()) {
      hidePopup(type);
    }
  }

  @override
  OverlayEntry? getOverlay(PopupType type) => _overlays[type];

  @override
  void setOverlay(PopupType type, OverlayEntry entry) {
    // Remove existing overlay of same type if any
    hidePopup(type);
    _overlays[type] = entry;
  }

  /// Calls the onClose callback for the given [type] if it exists.
  /// This is useful when the popup content wants to trigger close (e.g., after selection).
  void triggerOnClose(PopupType type) {
    final callback = _onCloseCallbacks[type];
    if (callback != null) {
      callback();
    }
  }

  /// Clears all callbacks (useful when disposing).
  void clearCallbacks() {
    _onCloseCallbacks.clear();
  }

  /// Disposes the controller, removing all overlays.
  void dispose() {
    hideAllPopups();
    clearCallbacks();
  }
}
