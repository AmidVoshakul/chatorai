import 'package:flutter/material.dart';


/// - scrollToIndicator(): прокрутка к индикатору загрузки (три точки)
/// - scrollToBottom(): прокрутка в самый конец чата
/// - reset(): сброс состояния при смене чата
class ChatScrollUtils {
  final ScrollController scrollController;
  final Duration animationDuration;
  final Curve animationCurve;
  
  ChatScrollUtils({
    required this.scrollController,
    required this.animationDuration,
    required this.animationCurve,
  });
  
  /// Инициализация (вызывается после создания)
  void initialize() {
    // Ничего не нужно инициализировать
  }
  
  /// Очистка ресурсов
  void dispose() {
    // Ничего не нужно очищать
  }
  
  /// Скролл к индикатору (вызывается после добавления сообщения пользователя)
  /// Прокручивает в конец списка, чтобы индикатор "три точки" был виден
  Future<void> scrollToIndicator() async {
    if (!scrollController.hasClients) return;
    
    try {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      final scrollDifference = (maxScroll - currentScroll).abs();
      
      // Если уже близко к концу, не скроллим
      if (scrollDifference < 5) return;
      
      await scrollController.animateTo(
        maxScroll,
        duration: animationDuration,
        curve: animationCurve,
      );
    } catch (e) {
      // Тихий промах - скролл не критичен
    }
  }
  
  /// Скролл в самый конец (для смены чата)
  Future<void> scrollToBottom() async {
    if (!scrollController.hasClients) return;
    
    try {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;
      final scrollDifference = (maxScroll - currentScroll).abs();
      
      if (scrollDifference < 5) return;
      
      await scrollController.animateTo(
        maxScroll,
        duration: animationDuration,
        curve: animationCurve,
      );
    } catch (e) {
      // Тихий промах
    }
  }
  
  /// Сброс состояния (вызывается при выборе нового чата)
  void reset() {
    // Ничего не нужно сбрасывать - вся логика упрощена
  }
  
  /// Сброс блокировки автоскролла (перед отправкой нового сообщения)
  void resetAutoScrollLock() {
    // Упрощенная версия - ничего не делает
    // Вся логика автоскролла теперь простая и не требует блокировок
  }
}