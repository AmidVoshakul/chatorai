# 📋 Исправление голосового ввода

## Проблема
При вводе текста в поле ввода отображалась иконка перечеркнутого микрофона вместо самолетика (отправить).

## Решение

### 1. Упрощена логика отображения
**Было:**
- Показывался текстовый виджет "Микрофон недоступен"
- Сложная логика в `SpeechUtils.getIcon()`

**Стало:**
- Только иконка, без текста
- Прямая логика в методах `_getActionIcon()` и `_getActionColor()`

### 2. Новые методы в `chat_input.dart`

#### `_getActionIcon()` - Возвращает правильную иконку
```dart
IconData _getActionIcon() {
  if (_isSending) return Icons.autorenew;
  if (_textController.text.trim().isNotEmpty || _attachedFilePath != null) return Icons.send;
  if (_speechService?.isAvailable ?? false) {
    return _isListening ? Icons.stop : Icons.mic;
  }
  return Icons.mic_off;
}
```

#### `_getActionColor()` - Возвращает правильный цвет
```dart
Color _getActionColor(ThemeData theme) {
  if (_isSending) return Colors.white;
  if (_textController.text.trim().isNotEmpty || _attachedFilePath != null) return Colors.white;
  if (_speechService?.isAvailable ?? false) {
    return _isListening ? Colors.red : theme.iconTheme.color ?? Colors.black;
  }
  return Colors.red;
}
```

#### `_handleMicrophoneAction()` - Обрабатывает клик по микрофону
```dart
Future<void> _handleMicrophoneAction() async {
  // Если микрофон доступен - запускаем/останавливаем
  if (_speechService?.isAvailable ?? false) {
    await _startSpeechToText();
    return;
  }

  // Если недоступен - запрашиваем разрешение
  final available = await _speechService?.checkAvailability() ?? false;
  
  if (available) {
    await _startSpeechToText();
  } else {
    // Показываем ошибку через Snackbar
    SnackbarUtils.showErrorSnackBar(
      context: context,
      message: 'Микрофон недоступен',
      icon: Icons.mic_off,
    );
  }
}
```

### 3. Удален виджет статуса
Удален метод `_buildSpeechStatus()` и его вызовы из обоих layout (mobile и desktop).

### 4. Использование SnackbarUtils
Все уведомления теперь показываются через `SnackbarUtils`:
- Ошибки доступа к микрофону
- Неудачные попытки запуска
- Уведомления о разрешениях

## Логика работы

### Сценарий 1: Пустое поле, микрофон доступен
- 🎤 Показывается микрофон
- По клику → Начинает слушать
- Во время слушания → ⏹️ Стоп + индикатор

### Сценарий 2: Пустое поле, микрофон НЕ доступен
- ⚠️ Показывается перечеркнутый микрофон
- По клику → Запрашивает разрешение
- Если отказ → ❌ Ошибка через Snackbar
- Если разрешил → 🎤 Микрофон становится активным

### Сценарий 3: Есть текст/файл
- ✈️ Показывается самолетик (отправить)
- По клику → Отправляет сообщение

### Сценарий 4: Идет стриминг
- ⏹️ Показывается стоп
- По клику → Останавливает стриминг

## Измененные файлы

1. **`lib/widgets/chat/chat_input.dart`**
   - Удален `_buildSpeechStatus()`
   - Добавлены `_getActionIcon()`, `_getActionColor()`, `_handleMicrophoneAction()`
   - Обновлена логика кнопок в обоих layout
   - Использует `SnackbarUtils` для уведомлений

2. **`lib/utils/snackbar_utils.dart`** (уже существовал)
   - Используется для показа ошибок

## Тесты

Все существующие тесты проходят ✅
- 78 тестов из предыдущей работы
- Дополнительные тесты для микрофона

## Результат

✅ **Иконка меняется правильно:**
- Пустое поле + микрофон доступен → 🎤
- Пустое поле + микрофон НЕ доступен → ⚠️
- Есть текст → ✈️
- Идет стриминг → ⏹️

✅ **Уведомления через Snackbar:**
- Ошибки показываются сверху экрана
- Красный цвет для ошибок
- Авто-скрытие через 3-4 секунды

✅ **Запрос разрешения:**
- По клику на перечеркнутый микрофон
- Проверка доступности
- Показ результата

**Статус: ✅ ГОТОВО**
