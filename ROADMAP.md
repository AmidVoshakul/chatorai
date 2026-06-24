# Implementation Roadmap – актуальное состояние проекта ChatORAI

*Все пункты важны, сроки нет. Обрабатываем API‑ключи как есть.*

---

## 0️⃣ Подготовительные действия (Read‑Only)
1. **Обновить индекс** – уже выполнено (`code-index_build_deep_index`).
2. **Проверить Drift‑схему** – таблицы `events`, `sessions`, `messages`, `tool_results`, `context_epochs` находятся в `lib/core/session/schema.dart`.
3. **Запустить тесты** – `flutter test` проходит без ошибок.
4. **Сохранить текущий граф архитектуры** – запустить под‑агент `explore` с запросом: 
   > *"Отобрази архитектурные деревья ProviderCatalogService, PermissionService, SessionEvent flow и UI‑виджеты (ProviderSettingsScreen). Сохрани результат в memory.*"
   (результат будет записан через `memory_create_entities`/`memory_create_relations`).

---

## 1️⃣ Автоматическое создание вариантов моделей (Model Variant Generator)
| Задача | Описание | Файл | Тест |
|-------|----------|------|------|
| **1.1** | Добавить утилиту `ModelVariantGenerator` – принимает `ModelConfig` и возвращает список вариантов (`none`, `minimal`, `low`, `medium`, `high`, `xhigh`) с различными `maxTokens` и `temperature` в соответствии с рекомендациями OpenCode. | `lib/core/llm/model_variant_generator.dart` (new) | `model_variant_generator_test.dart` |
| **1.2** | Интегрировать генератор в `ProviderCatalogService.discoverModels` – после получения модели из API вызвать генератор и сохранить полученные варианты в кэш. | `lib/core/llm/provider_catalog_service.dart` (modify) | Обновить существующие тесты `provider_catalog_service_test.dart` |

**Критерий приёма** – после вызова `discoverModels` у каждого провайдера в кэше находятся все 6 вариантов, UI‑select отображает их.

---

## 2️⃣ UI‑диалог для `doom_loop`
| Задача | Описание | Файл | Тест |
|-------|----------|------|------|
| **2.1** | Добавить экран/модальное окно `DoomLoopDialog` с тремя вариантами: *Ask once*, *Always allow*, *Reject*. Сохранять выбор в `SharedPreferences` под ключом `permission_doom_loop`. | `lib/features/settings/screens/doom_loop_dialog.dart` (new) | `doom_loop_dialog_test.dart` |
| **2.2** | В `PermissionService.ask` добавить проверку наличия сохранённого выбора для permission `doom_loop`. Если есть – возвращать результат без открытия диалога. | `lib/core/permission/permission_service.dart` (modify) | – |
| **2.3** | Обновить `ToolExecutor._doomLoopCheck` так, чтобы при первом запросе `doom_loop` вызывался `DoomLoopDialog` через `PermissionService`. | `lib/core/tools/tool_execution.dart` (modify) | – |

**Критерий приёма** – после трёх одинаковых вызовов инструмента появляется диалог, выбранный вариант сохраняется и влияет на последующие вызовы.

---

## 3️⃣ Регистрация инструмента `lsp`
| Задача | Описание | Файл | Тест |
|-------|----------|------|------|
| **3.1** | В `registerBuiltInTools` добавить регистрацию `lsp`‑инструмента, используя реализацию `dart-mcp-server_lsp`. | `lib/core/tools/built_in/built_in_tools.dart` (modify) | `lsp_tool_test.dart` |
| **3.2** | При необходимости добавить UI‑кнопку «Hover» в экране кода, вызывающую `lsp`‑инструмент и показывающую результат. | (опционально) | – |

**Критерий приёма** – `ToolRegistry` после инициализации содержит tool с id `lsp`; вызов `tool lsp` возвращает JSON‑ответ с hover‑информацией.

---

## 4️⃣ Обновление Knowledge Graph (memory)
После реализации каждого из пунктов 1‑3 выполнить:
1. `memory_create_entities` для новых сущностей: `ModelVariantGenerator`, `DoomLoopDialog`, `LspTool`.
2. `memory_create_relations` связывают их с существующими объектами (`ProviderCatalogService`, `PermissionService`, `ToolRegistry`).
3. `memory_add_observations` фиксируют причины изменений и ожидаемый эффект.

---

## 5️⃣ Финальная проверка
1. **Статический анализ** – `flutter analyze` без предупреждений.
2. **Тесты** – `flutter test` → все старые + новые тесты проходят.
3. **Ручная проверка UI (Linux)** – запустить приложение и убедиться:
   - в списке моделей отображаются все автогенерированные варианты;
   - при многократных вызовах side‑effect‑инструмента появляется диалог doom‑loop и сохраняет выбор;
   - команда `lsp` работает и показывает hover‑информацию.
4. **Git flow** – создать ветку, закоммитить с conventional‑commit, открыть PR, CI проходит.

---

**Следующий шаг** – выбрать один из пунктов (1, 2 или 3) и запустить соответствующий `task`‑sub‑agent для реализации.
