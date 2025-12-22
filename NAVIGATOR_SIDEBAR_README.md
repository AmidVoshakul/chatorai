# Markdown Navigator Sidebar - Руководство по использованию

## Обзор

Новая функция "Сайдбар навигации по Markdown" позволяет удобно перемещаться по длинным ответам, содержащим заголовки (#, ##, ###).

## Возможности

- **Автоматическое определение заголовков** - парсит Markdown и находит все заголовки
- **Иерархическая навигация** - отображает заголовки с отступами по уровням
- **Слайд-меню** - открывается с правого края экрана, ширина 280px (как у основного сайдбара)
- **Единый стиль** - полностью соответствует стилю и дизайну основного сайдбара
- **Визуальная индикация** - активный заголовок подсвечивается
- **Удобный доступ** - иконка в заголовке на десктопе, жест двойного касания на мобильных

## Файлы компонента

1. **`lib/widgets/chat/markdown_navigator_sidebar.dart`** - основной сайдбар
2. **`lib/utils/markdown_parser.dart`** - утилита для парсинга Markdown
3. **`lib/widgets/chat/chat_with_navigator.dart`** - пример интеграции

## Как использовать

### Вариант 1: Полная интеграция (рекомендуется)

```dart
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/widgets/chat/markdown_navigator_sidebar.dart';
import 'package:gen_ui_chat_ai/utils/markdown_parser.dart';

class MyChatScreen extends StatefulWidget {
  @override
  State<MyChatScreen> createState() => _MyChatScreenState();
}

class _MyChatScreenState extends State<MyChatScreen> {
  bool _isNavigatorOpen = false;
  String _chatContent = ''; // Ваш длинный ответ с Markdown

  @override
  Widget build(BuildContext context) {
    final headings = MarkdownParser.parseHeadings(_chatContent);
    
    return Stack(
      children: [
        // Основной контент
        Column(
          children: [
            // Ваш чат
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  // Двойное касание для открытия/закрытия (мобильные)
                  if (headings.isNotEmpty) {
                    setState(() => _isNavigatorOpen = !_isNavigatorOpen);
                  }
                },
                child: SingleChildScrollView(
                  child: Text(_chatContent),
                ),
              ),
            ),
          ],
        ),
        
        // Сайдбар навигации
        MarkdownNavigatorSidebar(
          content: _chatContent,
          isOpen: _isNavigatorOpen,
          onClose: () => setState(() => _isNavigatorOpen = false),
          onHeadingTap: (headingText) {
            // Реализуйте прокрутку к заголовку
            _scrollToHeading(headingText);
          },
        ),
      ],
    );
  }
  
  void _scrollToHeading(String headingText) {
    // Ваша логика прокрутки к конкретному заголовку
  }
}
```

### Вариант 2: Использование готового компонента

```dart
import 'package:flutter/material.dart';
import 'package:gen_ui_chat_ai/widgets/chat/chat_with_navigator.dart';

// Просто передайте содержимое чата
ChatWithNavigator(
  chatContent: yourLongMarkdownResponse,
)
```

### Вариант 3: Ручная интеграция (полный контроль)

```dart
// 1. Парсим заголовки
final headings = MarkdownParser.parseHeadings(chatContent);

// 2. Создаем сайдбар
MarkdownNavigatorSidebar(
  content: chatContent,
  isOpen: _isNavigatorOpen,
  onClose: () => _toggleNavigator(),
  onHeadingTap: (text) => _handleHeadingTap(text),
);

// 3. Для мобильных: добавьте GestureDetector с onDoubleTap
// Для десктопа: добавьте иконку в заголовок приложения
```

## Как открыть навигатор

### На десктопе (компьютеры, планшеты)
- В правой части заголовка появляется иконка 📋 (список)
- Иконка видна только когда в чате есть заголовки
- Нажмите, чтобы открыть/закрыть сайдбар

### На мобильных устройствах
- Двойное касание по области сообщений чата
- Никаких дополнительных кнопок или подсказок
- Двойное касание открывает/закрывает навигатор
- Закрытие - только через иконку крестика в заголовке сайдбара

## Поддерживаемые заголовки

- `# Заголовок 1 уровня`
- `## Заголовок 2 уровня`
- `### Заголовок 3 уровня`
- `#### Заголовок 4 уровня`

## Особенности реализации

### Анимация
- Плавное открытие/закрытие (300ms)
- Затемнение фона (backdrop)
- Слайд с правого края

### Визуальные элементы
- **Заголовки 1 уровня** - без отступа, жирный шрифт
- **Заголовки 2 уровня** - отступ 12px
- **Заголовки 3 уровня** - отступ 24px
- **Активный заголовок** - подсветка и цветная рамка
- **Метка уровня** - H1, H2, H3, H4 справа от заголовка

### Локализация
Поддерживается на русском и английском языках:
- `tableOfContents` - "Содержание" / "Table of Contents"
- `noHeadingsFound` - "Заголовки не найдены" / "No headings found"
- `useMarkdownHeadings` - "Используйте #, ##, ### в Markdown" / "Use #, ##, ### in Markdown"
- `totalHeadings` - "Всего заголовков" / "Total headings"

## Интеграция в существующий чат

### Шаг 1: Добавьте импорты
```dart
import 'package:gen_ui_chat_ai/widgets/chat/markdown_navigator_sidebar.dart';
import 'package:gen_ui_chat_ai/widgets/chat/markdown_navigator_button.dart';
import 'package:gen_ui_chat_ai/utils/markdown_parser.dart';
```

### Шаг 2: Добавьте состояние
```dart
bool _isNavigatorOpen = false;
List<MarkdownHeadingInfo> _headings = [];

void _updateHeadings(String content) {
  setState(() {
    _headings = MarkdownParser.parseHeadings(content);
  });
}
```

### Шаг 3: Добавьте UI
В вашем виджете чата добавьте:
- Кнопку навигатора (если `_headings.isNotEmpty`)
- Сайдбар (в Stack)

### Шаг 4: Обработка прокрутки
Реализуйте метод `_scrollToHeading()` для прокрутки к конкретному заголовку в вашем ScrollView.

## Пример ответа с заголовками

```markdown
# Введение в Flutter

Flutter - это фреймворк для создания кроссплатформенных приложений.

## Основные преимущества

### Быстрая разработка
- Hot Reload
- Единый код для всех платформ

### Высокая производительность
- Нативная производительность
- 60 FPS

## Начало работы

### Установка
1. Скачайте Flutter SDK
2. Добавьте в PATH
3. Запустите `flutter doctor`

### Создание проекта
```bash
flutter create my_app
```

## Заключение

Flutter предоставляет мощные инструменты для современной разработки.
```

Этот ответ создаст навигатор с 7 заголовками (1 H1, 3 H2, 3 H3).

## Производительность

- Парсинг выполняется мгновенно
- Не блокирует UI поток
- Кэширует результаты парсинга
- Оптимизирован для длинных текстов

## Доступность (Accessibility)

- Поддержка VoiceOver/TalkBack
- Клавиатурная навигация
- Высокий контраст
- Масштабирование шрифта

## Планы на будущее

- [x] Прокрутка к заголовку при клике - **РЕАЛИЗОВАНО**
- [x] Кнопка в AppBar для десктопа - **РЕАЛИЗОВАНО**
- [x] Жест двойного касания для мобильных - **РЕАЛИЗОВАНО**
- [ ] Поиск по заголовкам
- [ ] Возможность свернуть/развернуть секции
- [ ] Индикатор прогресса чтения
- [ ] Боковая панель с миниатюрами

## Вопросы и проблемы

Если возникнут проблемы:
1. Проверьте, что заголовки начинаются с `#` и пробела
2. Убедитесь, что локализация подключена
3. Проверьте консоль на наличие ошибок парсинга
