# ChatORAI — Русская версия

Современный AI-чат на Flutter с поддержкой множества моделей, агентов и инструментов.

## ✨ Возможности

- **Мульти-провайдер** — OpenRouter, локальные LLM или любой OpenAI-совместимый endpoint
- **Агентная система** — Специализированные субагенты через `@mention` (explore, general)
- **Выполнение инструментов** — AI может запускать shell-команды, читать/редактировать файлы, искать код, получать веб-контент
- **Голос и камера** — Распознавание речи и изображения
- **Markdown** — Подсветка синтаксиса, сворачиваемые блоки рассуждений
- **Темы** — Светлая и тёмная тема с плавными переходами
- **Мультиязычность** — 6 языков (en, ru, uk, zh, ja, ar) с RTL для арабского
- **Недавние модели** — Горизонтальная лента из топ-6 недавно и часто используемых моделей на экране выбора моделей
- **Локальное хранилище** — История чата и настройки сохраняются на устройстве

## 🚀 Быстрый старт

### Пользователи (Flutter не требуется)

Установите ChatORAI одной командой — готовые бинарники публикуются в
[GitHub Releases](https://github.com/AmidVoshakul/chatorai/releases/latest):

**Linux (одна команда):**

```bash
curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | bash
```

Альтернативные форматы на странице релиза: `chatorai-*.AppImage` (переносимый, просто `chmod +x` и запуск) и `chatorai-*.deb` (`sudo apt install ./chatorai-*.deb`).

**Windows:** скачайте `install_chatorai.ps1` или `install_chatorai.bat` из релиза, либо используйте `chatorai-*.zip`.

**macOS:** скачайте `chatorai-*.dmg` из релиза и перетащите в Applications.

Обновление в любой момент: `chatorai upgrade`.

### Разработчики (сборка из исходников)

Требования:

- Flutter 3.44.0 (stable)
- Dart SDK 3.11.0+
- Linux: установите системные библиотеки (`libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`)

Настройка API:

**Для разработки** — скопируйте `.env.example` в `.env` и добавьте ключ:

```env
OPENROUTER_API_KEY=sk-...
NVIDIA_API_KEY=nvapi-...
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

`.env` не входит в release-сборки.

**Для пользователей** — ключ вводится в настройках приложения, хранится в `SharedPreferences`.

Сборка и запуск:

```bash
flutter pub get
flutter gen-l10n   # только после правки lib/l10n/*.arb
flutter analyze
flutter test
flutter run -d linux   # или windows, chrome, android, ios
LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux  # Linux software rendering
```

## 📚 Документация

### Основная документация

- [Architecture](ARCHITECTURE.md) — Архитектура и компоненты
- [API Reference](docs/API.md) — Провайдеры, сервисы, модели, инструменты
- [Commands](docs/COMMANDS.md) — CLI-команды и `@`-упоминания агентов
- [Environment](docs/ENVIRONMENT.md) — Настройка окружения и зависимости
- [Configuration](docs/CONFIGURATION.md) — Схема chatorai.json и опции
- [Security](docs/SECURITY.md) — Система разрешений, работа с секретами, границы доверия
- [Platform Paths](docs/xdg-paths.md) — Пути для Linux/macOS/Windows/mobile

### Диаграммы

- [Architecture Overview](docs/diagrams/architecture-overview.md) — Data flow, session pipeline, MCP topology, config resolution, install/upgrade flow
- [Session Core](docs/diagrams/sessions.md) — ER-диаграмма Drift и стейт-машина SessionEvent
- [Tool System](docs/diagrams/tools.md) — Реестр инструментов, условная регистрация, жизненный цикл
- [MCP Integration](docs/diagrams/mcp.md) — Транспорт, lifecycle подключения, модели конфигурации
- [CI / Release Pipeline](docs/diagrams/ci-release.md) — GitHub Actions workflow, сборка артефактов, публикация релизов

### Платформенные руководства

- [Windows Setup](WINDOWS_SETUP.md) — Visual Studio, CMake, troubleshooting
- [Privacy Policy](PRIVACY_POLICY.md) — Обработка данных и сторонние сервисы

### Сообщество

- [Contributing](CONTRIBUTING.md) — Git workflow, стиль кода, тестирование
- [Code of Conduct](CODE_OF_CONDUCT.md) — Стандарты сообщества

## 📦 Установка

Готовые бинарники публикуются в [GitHub Releases](https://github.com/AmidVoshakul/chatorai/releases/latest) для каждой версии. **Flutter SDK не нужен**.

### Linux (одна команда)

```bash
curl -fsSL https://raw.githubusercontent.com/AmidVoshakul/chatorai/main/install_chatorai.sh | bash
```

Скачивает пребилд, устанавливает в `~/.local/share/chatorai/` с ярлыком в меню и командой `chatorai`. Или возьмите `chatorai-*.AppImage` (запуск напрямую) / `chatorai-*.deb` со страницы релиза.

### Windows

Скачайте `install_chatorai.ps1` или `install_chatorai.bat` из релиза, либо распакуйте `chatorai-*.zip` в `C:\Program Files\ChatORAI\`. Добавляются ярлык в меню Пуск и PATH.

### macOS

Скачайте `chatorai-*.dmg` из релиза и перетащите в Applications.

### Обновление

```bash
chatorai upgrade
```

### Удаление

```bash
chatorai uninstall
```

### CLI

ChatORAI — единый бинарник. `chatorai --help` выводит команды (`stats`, `models`, `upgrade`, `--version`); `chatorai` без аргументов запускает GUI.

## 🔧 Разработка

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d linux
```

## 🛡️ Безопасность и разрешения

- **Dev vs Runtime**: `.env` только для разработки; в релизе пользователи вводят credentials в приложении.
- **Разрешения инструментов**: Управляются через `chatorai.json`. По умолчанию `read`, `glob`, `grep` разрешены; остальные требуют подтверждения.
- **Без секретов в логах**: API-ключи и токены никогда не выводятся в логи.
- **TLS**: Все внешние соединения используют HTTPS.

## 🤝 Вклад в проект

См. [CONTRIBUTING.md](CONTRIBUTING.md) для информации о workflow, стиле кода и тестировании.

## 📄 Лицензия

MIT
