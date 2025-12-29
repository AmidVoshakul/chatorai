# ChatORAI - Русская инструкция

Современный AI-чат с поддержкой нескольких моделей, голосового ввода и камеры.

## 🚀 Быстрый старт

### 1. Настройка API ключа

Создайте файл `.env` в корне проекта:
```env
OPENROUTER_API_KEY=ваш_ключ_здесь
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```

### 2. Установка зависимостей

```bash
flutter pub get
```

## 🪟 Установка на Windows

### Автоматическая установка (Рекомендуется)

1. **Соберите приложение**:
```bash
flutter build windows --release
```

2. **Запустите установщик**:
   - **PowerShell** (рекомендуется):
     ```powershell
     PowerShell -ExecutionPolicy Bypass -File ".\install_app.ps1"
     ```
   - **Командная строка**:
     ```cmd
     install_app.bat
     ```

### Ручная установка

1. Соберите: `flutter build windows --release`
2. Скопируйте файлы из `build\windows\runner\Release\`
3. Создайте ярлык на рабочем столе

### Запуск после установки

- **Пуск**: Поищите "ChatORAI"
- **Рабочий стол**: Двойной клик по ярлыку
- **Терминал**: `C:\Program Files\ChatORAI\chatorai.exe`

## 🐧 Установка на Linux

```bash
sudo ./install_app.sh
```

После установки:
- **Меню**: Найдите "ChatORAI"
- **Терминал**: `chatorai`

## 📱 Запуск для разработки

```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# Web (Chrome)
flutter run -d chrome
```

## 📁 Загрузка файлов

### Поддерживаемые типы

**Изображения**: PNG, JPG, JPEG, GIF, WebP, SVG  
**Текст**: TXT, MD, CSV, HTML, JSON, XML  
**Документы**: PDF, DOC, DOCX, XLS, XLSX  
**Архивы**: ZIP, RAR, 7Z  
**Код**: Dart, JS, Python, Java, C++, C#, Go, Rust, PHP  
**Аудио**: MP3, WAV, OGG  
**Видео**: MP4, AVI, MOV

### Как использовать

1. Нажмите кнопку 📎 (плюс)
2. Выберите "Файл" или "Изображение"
3. Выберите файл в проводнике
4. Файл прикрепится к сообщению
5. Отправьте сообщение

### Важные особенности

✅ **Проверка поддержки моделью** - приложение проверяет, поддерживает ли модель файлы  
✅ **Сохранение данных** - если модель не поддерживает файлы, ваш текст не удаляется  
✅ **Кроссплатформенность** - работает на Windows, Linux, macOS, Android, iOS, Web

## 🔧 Отладка

### Проверка установки Flutter
```bash
flutter doctor
```

### Проверка доступных устройств
```bash
flutter devices
```

### Решение проблем Windows

**Ошибка "Visual C++ не найден"**:
- Установите [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

**Приложение не запускается**:
- Проверьте антивирус (может блокировать)
- Запустите от имени администратора

**Файловый проводник не открывается**:
- Это исправлено в последней версии
- Должно работать на всех платформах

## 📋 Команды сборки

```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Android
flutter build apk --release

# Web
flutter build web
```

## 🗑️ Удаление

### Windows
```powershell
# Удалить папку
Remove-Item -Path "C:\Program Files\ChatORAI" -Recurse -Force

# Удалить ярлыки
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\ChatORAI.lnk" -Force
Remove-Item -Path "$env:USERPROFILE\Desktop\ChatORAI.lnk" -Force
```

### Linux
```bash
sudo rm -rf /usr/local/lib/chatorai
sudo rm /usr/local/bin/chatorai
sudo rm /usr/share/applications/chatorai.desktop
sudo rm /usr/share/icons/hicolor/256x256/apps/chatorai.png
```

## 📚 Дополнительно

- **Полная документация**: [README.md](README.md)
- **Настройка Windows**: [WINDOWS_SETUP.md](WINDOWS_SETUP.md)
- **Тестирование**: Запустите `flutter test`

## 🆘 Поддержка

Если возникли проблемы:
1. Проверьте `flutter doctor`
2. Убедитесь, что API ключ верный
3. Проверьте интернет-соединение
4. См. раздел "Troubleshooting" в README.md