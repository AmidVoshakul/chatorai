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
- **Локальное хранилище** — История чата и настройки сохраняются на устройстве

## 🚀 Быстрый старт

### 1. Требования

- Flutter 3.44.0 (stable)
- Dart SDK 3.11.0+
- Linux: установите системные библиотеки (`libgtk-3-0 libgdk-pixbuf-2.0-0 libpango-1.0-0 libcairo2`)

### 2. Настройка API

**Для разработки** — скопируйте `.env.example` в `.env` и добавьте ключ:

```env
OPENROUTER_API_KEY=ваш_ключ
```

`.env` не входит в release-сборки.

**Для пользователей** — ключ вводится в настройках приложения, хранится в `SharedPreferences`.

### 3. Запуск

```bash
flutter pub get
flutter gen-l10n   # только после правки lib/l10n/*.arb
flutter analyze
flutter test
flutter run -d linux   # или windows, chrome, android, ios
```

## 📚 Документация

### Основная документация

- [Architecture](ARCHITECTURE.md) — Архитектура и компоненты
- [API Reference](docs/API.md) — Провайдеры, сервисы, модели, инструменты
- [Commands](docs/COMMANDS.md) — CLI-команды и `@`-упоминания агентов
- [Environment](docs/ENVIRONMENT.md) — Настройка окружения и зависимости
- [Roadmap](docs/ROADMAP.md) — Выполненные milestones и планы
- [Configuration](docs/configuration.md) — Схема chatorai.json и опции
- [Security](docs/security.md) — Система разрешений, работа с секретами, границы доверия
- [Platform Paths](docs/xdg-paths.md) — Пути для Linux/macOS/Windows/mobile

### Диаграммы

- [Architecture Overview](docs/diagrams/architecture-overview.md) — Data flow, session pipeline, MCP topology
- [Session Core](docs/diagrams/sessions.md) — ER-диаграмма Drift и стейт-машина SessionEvent
- [Tool System](docs/diagrams/tools.md) — Реестр инструментов, условная регистрация, жизненный цикл
- [MCP Integration](docs/diagrams/mcp.md) — Транспорт, lifecycle подключения, модели конфигурации

### Платформенные руководства

- [Windows Setup](WINDOWS_SETUP.md) — Visual Studio, CMake, troubleshooting
- [Privacy Policy](PRIVACY_POLICY.md) — Обработка данных и сторонние сервисы

### Сообщество

- [Contributing](CONTRIBUTING.md) — Git workflow, стиль кода, тестирование
- [Code of Conduct](CODE_OF_CONDUCT.md) — Стандарты сообщества

## 📦 Установка

### Linux

```bash
sudo ./install_app.sh
```

Запуск: из меню или `chatorai` в терминале.

### Windows

```powershell
flutter build windows --release
PowerShell -ExecutionPolicy Bypass -File ".\install_app.ps1"
```

Запуск: из меню Пуск или рабочего стола.

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
