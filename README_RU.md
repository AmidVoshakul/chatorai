# ChatORAI — Русская версия

Современный AI-чат на Flutter с поддержкой множества моделей, агентов и инструментов.

## 🚀 Быстрый старт

### 1. API ключ

**Для разработки** — создайте `.env` из `.env.example`:
```env
OPENROUTER_API_KEY=ваш_ключ
```
Файл `.env` не входит в release-сборки.

**Для пользователей** — ключ вводится в настройках приложения, хранится в SharedPreferences.

### 2. Запуск

```bash
flutter pub get
flutter gen-l10n   # только после правки lib/l10n/*.arb
flutter analyze
flutter test
flutter run -d linux   # или windows, chrome, android, ios
```

## 📚 Документация

Полная документация на английском:

- [Architecture](ARCHITECTURE.md) — Архитектура и компоненты
- [API Reference](docs/API.md) — API, провайдеры, инструменты
- [Commands](docs/COMMANDS.md) — Команды и @-упоминания
- [Environment](docs/ENVIRONMENT.md) — Настройка окружения
- [Changelog](CHANGELOG.md) — Изменения и история версий

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
flutter test
flutter analyze
flutter run --hot-reload
```

## 🌐 Языки

Приложение доступно на 6 языках: английский, русский, украинский, китайский, японский, арабский (с RTL).

## 📄 Лицензия

MIT