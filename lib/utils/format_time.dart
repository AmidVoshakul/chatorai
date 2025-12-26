import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/l10n/app_localizations.dart';

/// Унифицированная функция форматирования времени
/// 
/// Форматирует разницу между текущим временем и заданным временем
/// в человекочитаемый формат на основе локализации
String formatTimeAgo(
  DateTime dateTime, {
  required BuildContext context,
  bool useShortFormat = false,
}) {
  final localizations = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  // Менее 1 минуты
  if (difference.inMinutes < 1) {
    return localizations.justNow;
  }
  
  // Менее 1 часа
  if (difference.inHours < 1) {
    return localizations.minAgo(difference.inMinutes);
  }
  
  // Менее 24 часов
  if (difference.inHours < 24) {
    if (difference.inHours == 1) {
      return localizations.onlyOneHourAgo;
    }
    return localizations.hoursAgo(difference.inHours);
  }
  
  // Менее 7 дней
  if (difference.inDays < 7) {
    if (difference.inDays == 1) {
      return localizations.onlyOneDayAgo;
    }
    return localizations.daysAgo(difference.inDays);
  }
  
  // Более 7 дней - показываем дату
  // Для короткого формата (в сообщениях) используем число/месяц/год
  if (useShortFormat) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  
  // Для длинного формата (в сайдбаре) используем формат из локализации
  // Простой формат для всех языков
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

/// Форматирование для сайдбара (с поддержкой локализации)
String formatSidebarDate(
  DateTime dateTime, {
  required BuildContext context,
}) {
  return formatTimeAgo(dateTime, context: context, useShortFormat: false);
}

/// Форматирование для сообщений (краткий формат)
String formatMessageTime(
  DateTime dateTime, {
  required BuildContext context,
}) {
  return formatTimeAgo(dateTime, context: context, useShortFormat: true);
}
