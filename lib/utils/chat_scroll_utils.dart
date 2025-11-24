// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';

/// Utility class for managing scroll behavior in chat interfaces
class ChatScrollUtils {
  final ScrollController scrollController;
  final Duration animationDuration;
  final Curve animationCurve;
  
  // Debounce timer for scroll events to prevent excessive scrolling
  Timer? _scrollDebounceTimer;
  
  // Flag to track if we're currently animating
  bool _isAnimating = false;
  
  // Last known scroll position for comparison
  double _lastScrollPosition = 0.0;
  
  // Minimum distance threshold for auto-scroll (prevents tiny adjustments)
  static const double _minScrollThreshold = 5.0;
  
  // Auto-scroll lock to prevent conflicts during user interaction
  bool _autoScrollLocked = false;
  
  // Callback for when messages are updated
  final VoidCallback? onMessagesUpdated;
  
  // Auto-scroll to bottom when new content is added
  bool _autoScrollEnabled = true;
  
  // Linux-specific optimizations (increased thresholds for better responsiveness)
  static const double _scrollThreshold = 100.0; // Was 50, increased for Linux
  static const int _scrollDelay = 30; // Was 50ms, reduced for Linux
  
  /// Constructor
  ChatScrollUtils({
    required this.scrollController,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.onMessagesUpdated,
  }) {
    _initializeScrollListener();
  }
  
  /// Initialize scroll position tracking
  void initialize() {
    if (scrollController.hasClients) {
      _lastScrollPosition = scrollController.offset;
      
      // Force immediate scroll to bottom for better Linux compatibility
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
          print('[ChatScrollUtils] 🔧 Linux initialization: Force scroll to bottom');
        }
      });
    }
  }
  
  /// Start listening to scroll events
  void _initializeScrollListener() {
    scrollController.addListener(_onScrollEvent);
  }
  
  /// Stop listening to scroll events
  void dispose() {
    _scrollDebounceTimer?.cancel();
    scrollController.removeListener(_onScrollEvent);
  }
  
  /// Handle scroll events to determine auto-scroll behavior
  void _onScrollEvent() {
    if (!_autoScrollLocked) {
      final currentPosition = scrollController.offset;
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      
      // Use Linux-optimized threshold
      final threshold = _scrollThreshold;
      final isNearBottom = (maxScrollExtent - currentPosition) <= threshold;
      
      // Update auto-scroll lock based on user interaction
      _autoScrollLocked = !isNearBottom;
      
      // Store last position for comparison
      _lastScrollPosition = currentPosition;
      
      print('[ChatScrollUtils] 📱 Scroll position: $currentPosition, Max: $maxScrollExtent, Near bottom: $isNearBottom, Locked: $_autoScrollLocked');
    }
  }
  
  /// Scroll to bottom with optional animation
  Future<void> scrollToBottom({bool animated = true}) async {
    if (_isAnimating) {
      print('[ChatScrollUtils] ⏭️ Skip scroll - already animating');
      return;
    }
    
    try {
      _isAnimating = true;
      
      if (animated && scrollController.hasClients) {
        await scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: animationDuration,
          curve: animationCurve,
        );
        print('[ChatScrollUtils] 🎯 Smooth scroll to bottom completed');
      } else if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        print('[ChatScrollUtils] ⚡ Jump scroll to bottom completed');
      }
      
      // Force focus on the last content for Linux compatibility
      if (scrollController.hasClients) {
        // Small delay to ensure scroll is complete, then ensure we're really at bottom
        Future.delayed(const Duration(milliseconds: 10), () {
          if (scrollController.hasClients && scrollController.position.maxScrollExtent > 0) {
            final currentScroll = scrollController.offset;
            final maxScroll = scrollController.position.maxScrollExtent;
            
            // If we're not exactly at the bottom, make a final adjustment
            if ((maxScroll - currentScroll) > 1.0) {
              scrollController.jumpTo(maxScroll);
              print('[ChatScrollUtils] 🔧 Linux fix: Final adjustment to exact bottom position');
            }
          }
        });
      }
    } catch (e) {
      print('[ChatScrollUtils] ❌ Error scrolling to bottom: $e');
    } finally {
      _isAnimating = false;
    }
  }
  
  /// Scroll to specific position
  Future<void> scrollToPosition(
    double position, {
    bool animated = true,
  }) async {
    if (_isAnimating || !scrollController.hasClients) {
      return;
    }
    
    try {
      _isAnimating = true;
      
      if (animated) {
        await scrollController.animateTo(
          position,
          duration: animationDuration,
          curve: animationCurve,
        );
      } else {
        scrollController.jumpTo(position);
      }
      
      print('[ChatScrollUtils] 🎯 Scrolled to position: $position');
    } catch (e) {
      print('[ChatScrollUtils] ❌ Error scrolling to position $position: $e');
    } finally {
      _isAnimating = false;
    }
  }
  
  /// Debounced scroll to bottom (prevents excessive scrolling)
  void debouncedScrollToBottom({int debounceMs = 100}) {
    _scrollDebounceTimer?.cancel();
    
    _scrollDebounceTimer = Timer(Duration(milliseconds: debounceMs), () {
      if (!_autoScrollLocked) {
        scrollToBottom();
      }
    });
  }
  
  /// Lock auto-scroll (useful during user interaction)
  void lockAutoScroll() {
    _autoScrollLocked = true;
    print('[ChatScrollUtils] 🔒 Auto-scroll locked');
  }
  
  /// Unlock auto-scroll
  void unlockAutoScroll() {
    _autoScrollLocked = false;
    print('[ChatScrollUtils] 🔓 Auto-scroll unlocked');
    // Auto-scroll to bottom when unlocked if needed
    if (scrollController.hasClients) {
      final isNearBottom = (scrollController.position.maxScrollExtent - scrollController.offset) <= 50;
      if (isNearBottom) {
        scrollToBottom();
      }
    }
  }
  
  /// Check if scroll is at bottom
  bool get isAtBottom {
    if (!scrollController.hasClients) return true;
    
    final position = scrollController.offset;
    final maxExtent = scrollController.position.maxScrollExtent;
    return (maxExtent - position) <= _minScrollThreshold;
  }
  
  /// Check if auto-scroll is locked
  bool get isAutoScrollLocked => _autoScrollLocked;
  
  /// Get current scroll position
  double get currentPosition => scrollController.hasClients ? scrollController.offset : 0.0;
  
  /// Get max scroll extent
  double get maxScrollExtent => scrollController.hasClients ? scrollController.position.maxScrollExtent : 0.0;
  
  /// Smooth scroll with custom duration and curve
  Future<void> smoothScroll({
    required double targetPosition,
    Duration? duration,
    Curve? curve,
  }) async {
    if (_isAnimating || !scrollController.hasClients) return;
    
    try {
      _isAnimating = true;
      
      await scrollController.animateTo(
        targetPosition,
        duration: duration ?? animationDuration,
        curve: curve ?? animationCurve,
      );
      
      print('[ChatScrollUtils] 🎯 Smooth scroll completed: $targetPosition');
    } catch (e) {
      print('[ChatScrollUtils] ❌ Error in smooth scroll: $e');
    } finally {
      _isAnimating = false;
    }
  }
  
  /// Scroll to specific item index (if using ListView with item extent)
  Future<void> scrollToItem({
    required int index,
    double? itemExtent,
    bool animated = true,
  }) async {
    if (!scrollController.hasClients) return;
    
    try {
      double targetPosition;
      
      if (itemExtent != null) {
        // For fixed item extent
        targetPosition = index * itemExtent;
      } else {
        // For variable item extent, use an estimate
        targetPosition = index * 80.0; // Average message height
      }
      
      await scrollToPosition(
        targetPosition.clamp(0, scrollController.position.maxScrollExtent),
        animated: animated,
      );
      
      print('[ChatScrollUtils] 🎯 Scrolled to item $index at position $targetPosition');
    } catch (e) {
      print('[ChatScrollUtils] ❌ Error scrolling to item $index: $e');
    }
  }
  
  /// Reset scroll state
  void reset() {
    _autoScrollLocked = false;
    _isAnimating = false;
    _scrollDebounceTimer?.cancel();
    _lastScrollPosition = 0.0;
    _autoScrollEnabled = true;
    
    if (scrollController.hasClients) {
      _lastScrollPosition = scrollController.offset;
    }
    
    print('[ChatScrollUtils] 🔄 Scroll state reset');
  }
  
  /// Call this method when messages are updated to trigger auto-scroll
  void onNewMessages() {
    if (!_autoScrollLocked && _autoScrollEnabled) {
      // For better Linux support, always try to scroll immediately
      Future.delayed(Duration(milliseconds: _scrollDelay), () {
        if (scrollController.hasClients) {
          final currentPosition = scrollController.offset;
          final maxScrollExtent = scrollController.position.maxScrollExtent;
          final threshold = _scrollThreshold;
          final isNearBottom = (maxScrollExtent - currentPosition) <= threshold;
          
          if (isNearBottom) {
            // User is near bottom, scroll to keep them there with Linux-optimized animation
            scrollController.animateTo(
              maxScrollExtent,
              duration: const Duration(milliseconds: 150), // Faster animation for Linux
              curve: Curves.easeOut,
            );
            print('[ChatScrollUtils] 📨 Linux: Scrolling to bottom (user near bottom)');
          } else {
            // User is reading old messages, don't interrupt
            print('[ChatScrollUtils] 📨 Linux: Not scrolling (user reading old messages)');
          }
        }
      });
    } else {
      print('[ChatScrollUtils] 📨 New messages detected, but auto-scroll is locked or disabled');
    }
  }
  
  /// Enable or disable auto-scroll
  void setAutoScrollEnabled(bool enabled) {
    _autoScrollEnabled = enabled;
    print('[ChatScrollUtils] 🔄 Auto-scroll ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isAnimating': _isAnimating,
      'isAutoScrollLocked': _autoScrollLocked,
      'isAtBottom': isAtBottom,
      'autoScrollEnabled': _autoScrollEnabled,
      'currentPosition': currentPosition,
      'maxScrollExtent': maxScrollExtent,
      'lastScrollPosition': _lastScrollPosition,
      'hasClients': scrollController.hasClients,
    };
  }
}