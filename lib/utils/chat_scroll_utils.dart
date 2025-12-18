// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/utils/logger.dart';

final _logger = LogTags.scroll;

/// Упрощенная логика автоскролла для чата
/// 
/// Правила:
/// 1. После отправки → скролл к индикатору (ОДИН РАЗ)
/// 2. Во время стриминга → НЕ скроллим
/// 3. В конце → НЕ скроллим (если пользователь не двигал)
class ChatScrollUtils {
  final ScrollController scrollController;
  final Duration animationDuration;
  final Curve animationCurve;
  
  // Флаги состояния
  bool _isAnimating = false;
  bool _autoScrollLocked = false;
  bool _hasScrolledToIndicator = false; // NEW: Флаг, что уже скроллили к индикатору
  
  // Для отладки: история операций
  final List<String> _debugHistory = [];
  
  ChatScrollUtils({
    required this.scrollController,
    required this.animationDuration,
    required this.animationCurve,
  });
  
  /// Инициализация (вызывается после создания)
  void initialize() {
    _initListener();
    _log('[INIT] ChatScrollUtils initialized');
  }
  
  /// Очистка
  void dispose() {
    _log('[DISPOSE] ChatScrollUtils disposed');
    _debugHistory.clear();
  }
  
  void _initListener() {
    scrollController.addListener(() {
      // НЕ реагируем, если идет анимация скролла
      if (_isAnimating) return;
      
      final current = scrollController.offset;
      final max = scrollController.position.maxScrollExtent;
      final distance = (max - current).abs();
      
      // Если пользователь отскроллил больше 50px от конца → блокируем автоскролл
      if (distance > 50 && !_autoScrollLocked) {
        _autoScrollLocked = true;
        _log('[USER SCROLL] Locked auto-scroll (distance: ${distance.toStringAsFixed(1)}px)');
      }
    });
  }
  
  void _log(String message) {
    _debugHistory.add('${DateTime.now().toString().split(' ')[1]}: $message');
    if (_debugHistory.length > 20) {
      _debugHistory.removeAt(0); // Keep last 20 entries
    }
    // Выводим в консоль для отладки
    print('[SCROLL] $message');
    _logger.logInfo('[Scroll] $message');
  }
  
  /// Скролл к индикатору (вызывается ПОСЛЕ добавления сообщения)
  /// 
  /// Скроллит в конец списка, чтобы индикатор был виден под AppBar
  /// Вызывается ТОЛЬКО ОДИН РАЗ (флаг _hasScrolledToIndicator)
  Future<void> scrollToIndicator() async {
    // ПРОВЕРКА: Если уже скроллили к индикатору — ВЫХОДИМ
    if (_hasScrolledToIndicator) {
      _log('[SKIP] Already scrolled to indicator (once)');
      return;
    }
    
    // Быстрая проверка: если уже анимируем или заблокировано — выходим
    if (_isAnimating) {
      _log('[SKIP] Already animating');
      return;
    }
    
    if (!scrollController.hasClients) {
      _log('[SKIP] Controller not attached');
      return;
    }
    
    // Проверяем, не заблокирован ли автоскролл пользователем
    if (_autoScrollLocked) {
      _log('[SKIP] Auto-scroll locked by user');
      return;
    }
    
    _isAnimating = true;
    _log('[START] scrollToIndicator');
    
    // Ждем, чтобы ListView обновился
    await Future.delayed(const Duration(milliseconds: 30));
    
    // Проверяем еще раз после задержки
    if (!scrollController.hasClients || _autoScrollLocked) {
      _isAnimating = false;
      return;
    }
    
    try {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      
      // Скроллим в конец (где индикатор)
      final targetScroll = maxScroll;
      
      // Проверяем, нужно ли скроллить
      final scrollDifference = (targetScroll - currentScroll).abs();
      if (scrollDifference < 5) {
        _log('[SKIP] Already at target position (diff: ${scrollDifference.toStringAsFixed(1)}px)');
        _isAnimating = false;
        return;
      }
      
      _log('[EXECUTE] current=${currentScroll.toStringAsFixed(0)}, target=${targetScroll.toStringAsFixed(0)}');
      
      await scrollController.animateTo(
        targetScroll,
        duration: animationDuration,
        curve: animationCurve,
      );
      
      _hasScrolledToIndicator = true; // УСТАНАВЛИВАЕМ ФЛАГ
      _log('[COMPLETE] Scrolled to indicator (once)');
    } catch (e) {
      _log('[ERROR] $e');
      _logger.logError('[Scroll] Error scrolling to indicator: $e');
    } finally {
      _isAnimating = false;
    }
  }
  
  /// Скролл в конец (для смены чата)
  /// 
  /// Скроллит в самый низ, чтобы видеть последние сообщения
  Future<void> scrollToBottom() async {
    if (_isAnimating) {
      _log('[SKIP] Already animating');
      return;
    }
    
    if (!scrollController.hasClients) {
      _log('[SKIP] Controller not attached');
      return;
    }
    
    _isAnimating = true;
    _log('[START] scrollToBottom');
    
    try {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      
      final scrollDifference = (maxScroll - currentScroll).abs();
      if (scrollDifference < 5) {
        _log('[SKIP] Already at bottom (diff: ${scrollDifference.toStringAsFixed(1)}px)');
        _isAnimating = false;
        return;
      }
      
      _log('[EXECUTE] target=${maxScroll.toStringAsFixed(0)}, current=${currentScroll.toStringAsFixed(0)}');
      
      await scrollController.animateTo(
        maxScroll,
        duration: animationDuration,
        curve: animationCurve,
      );
      
      _log('[COMPLETE] Scrolled to bottom');
    } catch (e) {
      _log('[ERROR] $e');
      _logger.logError('[Scroll] Error scrolling to bottom: $e');
    } finally {
      _isAnimating = false;
    }
  }
  

  
  /// Сброс состояния (вызывается при новом чате)
  void reset() {
    _autoScrollLocked = false;
    _isAnimating = false;
    _hasScrolledToIndicator = false; // СБРОС ФЛАГА
    _debugHistory.clear();
    _log('[RESET] All state cleared');
  }
  
  /// Сбросить только блокировку автоскролла (перед отправкой сообщения)
  void resetAutoScrollLock() {
    if (_autoScrollLocked) {
      _autoScrollLocked = false;
      _log('[RESET] Auto-scroll lock cleared');
    }
    // СБРОС ФЛАГА: новое сообщение = новый скролл
    _hasScrolledToIndicator = false;
    _log('[RESET] Indicator scroll flag cleared');
  }
  
  /// Проверка, внизу ли пользователь
  bool get isAtBottom {
    if (!scrollController.hasClients) return true;
    final current = scrollController.offset;
    final max = scrollController.position.maxScrollExtent;
    return (max - current) <= 20;
  }
  
  /// Разрешить/запретить автоскролл
  set autoScrollLocked(bool locked) {
    _autoScrollLocked = locked;
    _log('[SET] Auto-scroll ${locked ? 'LOCKED' : 'UNLOCKED'}');
  }
  
  bool get autoScrollLocked => _autoScrollLocked;
  
  /// Получить историю для отладки
  List<String> getDebugHistory() => List.from(_debugHistory);
}