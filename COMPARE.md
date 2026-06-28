# Сравнительный анализ архитектуры: ChatORAI vs OpenCode

## Обзор

Документ сравнивает ключевые архитектурные компоненты **ChatORAI** и конкурента **OpenCode**, отмечая сильные стороны, пробелы и конкретные рекомендации для улучшения ChatORAI.

## 1️⃣ Система провайдеров (Dependency Injection)

| Функция                 | ChatORAI                                                               | OpenCode                                                                   | Пробел                                                                           |
| ----------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Регистрация провайдеров | Централизованный `ProviderCatalogService` с ручным добавлением в коде. | Полиморфная `ProviderFactory` с автоматическим сканированием конфигурации. | Отсутствует авто‑дискавери; добавление нового провайдера требует изменения кода. |
| Инъекция аутентификации | Жёстко прописана в `ProviderConfig`.                                   | Поддержка различных методов (API‑key, OAuth, AWS, GCP) через конфигурацию. |
| Расширяемость           | Добавление нового провайдера → изменение Dart‑файла.                   | Добавление нового провайдера → изменение JSON/YAML‑конфига.                |

**Рекомендация:** добавить `ProviderFactory` (чтение JSON/YAML) либо расширить текущий `ProviderCatalogService`, чтобы поддерживать авто‑дискавери.

## 2️⃣ Каталог моделей и генерация вариантов

| Функция             | ChatORAI                                                 | OpenCode                                                                    | Пробел |
| ------------------- | -------------------------------------------------------- | --------------------------------------------------------------------------- | ------ |
| Источник моделей    | Статический каталог в `lib/core/llm/catalog/providers/`. | Мульти‑источник: `Models.dev`, конфиги, плагины.                            |
| Генерация вариантов | Ручное объявление каждой модели.                         | Автоматическое создание 6 вариантов (`none/minimal/low/medium/high/xhigh`). |
| Идентификаторы      | Конкатенация строк (`providerId/modelName`).             | Типизированные ID (`ProviderV2.ID`, `ModelV2.ID`).                          |

**Рекомендация:** реализовать `ModelVariantGenerator`, который после получения базовой модели генерирует все варианты, как в OpenCode.

## 3️⃣ Система прав (Permission)

| Функция            | ChatORAI                                         | OpenCode                                                              | Пробел |
| ------------------ | ------------------------------------------------ | --------------------------------------------------------------------- | ------ |
| Формат правил      | JSON с `allow/ask/deny`.                         | `PermissionV2` – wildcard, `last‑match‑wins`.                         |
| Детекция doom‑loop | Нет встроенной.                                  | Автоматическое срабатывание после 3 одинаковых вызовов (`doom_loop`). |
| UI‑диалог          | Обычное модальное окно без «once/always/reject». | Диалог с тремя вариантами + сохранение выбора.                        |

**Рекомендация:** добавить UI‑диалог `DoomLoopDialog` и хранить выбор в `SharedPreferences`.

## 4️⃣ Хранилище сессий и Event‑sourcing

| Функция            | ChatORAI                               | OpenCode                                                      | Пробел |
| ------------------ | -------------------------------------- | ------------------------------------------------------------- | ------ |
| Персистентность    | `SharedPreferences` + `SecureStorage`. | Drift SQLite с таблицей `events` (event‑sourced).             |
| Возможность реплея | Нет встроенного реплей.                | Полный реплей через `Projector`.                              |
| Иерархия сессий    | Родитель/дочерний ID в `sessions`.     | Структурный `SessionTree` с автоматическим cascade‑удалением. |

**Текущее состояние:** в ChatORAI полностью реализована event‑sourced модель с Drift, таблицы `events`, `sessions`, `messages`, `tool_results`, `context_epochs` в `lib/core/session/schema.dart`. Реплей реализован в `projector.dart`. `SessionRunner` управляет жизненным циклом сессий с поддержкой parent‑child иерархии через `ChildSessionCreated` события. `SessionTree` обеспечивает навигацию по дереву сессий. Модуль расположен в `lib/core/session/`. Пробелов в этом блоке нет.

## 5️⃣ Компакция контекста и подсчёт токенов

| Функция                        | ChatORAI                                    | OpenCode                                           | Пробел |
| ------------------------------ | ------------------------------------------- | -------------------------------------------------- | ------ |
| Детекция переполнения          | Примерная оценка `chars/4`.                 | Точная (`input`, `output`, `reasoning`, `cache`).  |
| Триггер компакции              | Ручной вызов `CompactionService.compact()`. | Автоматический при переполнении, LLM‑суммаризатор. |
| Обрезка output‑ов инструментов | Нет автоматической очистки.                 | Защита последних 40 k токенов, очистка старых.     |

**Текущее состояние:** `CompactionService` реализует OpenCode‑подобный алгоритм (head/tail, суммаризация, обрезка tool‑output) и вызывается в `chat_screen_streaming.dart`. Точная подсчёт‑токенов реализован в `TokenCounter` (см. `lib/core/context/token_counter.dart`). Пробелов нет.

## 6️⃣ Набор инструментов (Tool Suite)

| Функция             | ChatORAI                                                                                         | OpenCode                                         | Пробел |
| ------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------ | ------ |
| Базовые инструменты | 16+ (bash, read, edit, write, glob, grep, webfetch, websearch, task, todowrite, question, skill, apply_patch, lsp, format, invalid, external_directory, json_schema, plan). | 16+ (аналогично). |
| Проверка прав       | `assertPermission` per‑tool.                                                                     | Тоже + `doom_loop` guard.                        |
| Обрезка вывода      | Ручные проверки размера.                                                                         | Автоматическое `truncate.output()` (2000 симв.). |

**Текущее состояние:** Все инструменты зарегистрированы. `lsp` и `format` регистрируются условно (при наличии соответствующего сервиса). Обрезка вывода реализована в `TruncationService` (2000 строк / 50KB). Пробелов нет.

## 7️⃣ Оркестрация агентов

Обе системы используют `task`‑инструмент для запуска под‑агентов. OpenCode добавляет флаг фонового выполнения и наследование прав. В ChatORAI фоновые задачи пока не использованы.

## 8️⃣ Подсчёт токенов и оценка стоимости

OpenCode хранит детализированный учёт токенов per‑message. В ChatORAI реализован `TokenCounter` с оценкой и методом `recordUsage`, а UI уже показывает токены в чат‑бабблах.

---

## План действий (корректированный)

1. **Model Variant Generator** – добавить `ModelVariantGenerator` и интегрировать в `ProviderCatalogService`.
2. **Doom‑loop UI** – создать диалог `DoomLoopDialog`, добавить хранение выбора и связать с `PermissionService`.
3. **Регистрация `lsp`** – ✅ ВЫПОЛНЕНО. `lsp` зарегистрирован условно в `registerBuiltInTools`.
4. **Тестовое покрытие** – ✅ ВЫПОЛНЕНО. 140+ тестов для MCP, 36 для question core, 43 для provider catalog, 16+ для built-in tools registration.
5. **Обновление графа знаний** – задокументировать новые сущности и связи через `memory_*`‑инструменты.
6. **MCP серверы** – ✅ ВЫПОЛНЕНО. `McpClientService` с поддержкой stdio/http транспортов, OAuth конфигурация.
7. **Keybinds System** – система горячих клавиш для GUI (планируется, см. `keybinding` секция в `chatorai.json`).

Выполненные пункты (3, 4, 6) закрывают предыдущие пробелы. Оставшиеся пункты (1, 2, 7) являются следующими приоритетами.

---

### Post-Session-Core Updates (2026-06-28)

- Session Core: ✅ Implemented. Full parity with OpenCode's event-sourcing model.
- MCP Integration: ✅ Implemented. Stdio + HTTP transports, OAuth support.
- Tool Suite: ✅ 16 tools registered including previously missing `question`, `lsp`, `format`, `invalid`.
- Drift persistence: ✅ Crash recovery via event replay now functional.
- Remaining gaps: Keybinds system (R7), Doom-loop UI (R2), Model Variant Generator (R1).

---

_Подготовлено специалистом‑архитектором, экспертом по обратному инжинирингу и координации бенчмарков._

---

# ChatORAI vs OpenCode — Architecture & LLM Request Pipeline Benchmark

**Anchored:** 2026-06-28 (updated post-Session-Core)
**Scope:** LLM request pipeline — provider management, retry, error handling, streaming, session recovery
**Benchmark framework:** OpenCode CLI (`anomalyco/opencode`) as primary competitor

---

## 1. Executive Architecture Matrix

| Dimension              | ChatORAI                                    | OpenCode CLI                                    |
| ---------------------- | ------------------------------------------- | ----------------------------------------------- |
| Language / Runtime     | Dart / Flutter 3.41                         | TypeScript / Effect-TS                          |
| DI / State             | Riverpod 3.x (imperative)                   | Effect Layer (functional)                       |
| LLM SDK                | ai_sdk_dart `streamText`                    | @opencode/llm `LLMClient`                       |
| HTTP layer             | Dio with interceptors                       | Effect `HttpClient` (Fetch)                     |
| Error model            | Sealed classes (`ClassifiedError`)          | Tagged union (`LLMError`)                       |
| Retry policy (default) | 3 attempts, exp backoff 500ms→10s, factor 2 | 2 attempts, jittered uniform 0.8x–1.2x, 10s cap |
| Rate-limit handling    | **BUG: isRetryable=false**                  | Retryable with retryAfterMs                     |
| Overflow detection     | Post-stream (after request)                 | Pre-stream (`isContextOverflowFailure`)         |
| Session persistence    | Drift SQLite (event-sourced) via `SessionRepository` | SQLite via Effect-Drizzle                       |
| Crash recovery         | Full event replay via Drift events replay    | Full event replay + compact                     |
| Tool orchestration     | LRU doom-loop + truncation                  | FiberSet + Semaphore(1)                         |
| Cancellation model     | Gen counter + CancellationToken             | Fiber cancellation                              |

---

## 2. ChatORAI LLM Request Pipeline

UI onChunk / onCompletion / onToolStart
└─ ChatAiService.streamChatCompletion()
├─ ModelResolver.resolve(modelId) ← catalog + headers
├─ ModelResolver.buildLanguageModel() ← ai_sdk_dart LanguageModelV3
├─ ChatRetryService.execute(operation)
│ ├─ \_isRetryable(ErrorClassifier) ← sealed class dispatch
│ ├─ \_nextDelay: baseDelay \* factor^attempt (750ms→1.5s→3s→6s→10s cap)
│ ├─ sleep: 50ms poll loop ← blocking
│ └─ isStillValid: gen == generation
└─ streamText(model, messages, ...)
└─ await for event in fullStream
├─ text-delta / reasoning-delta
├─ tool-start / tool-end / tool-error
└─ StreamTextErrorEvent → rethrow → retry loop

**Critical bugs identified (lib/core/error/error_classifier.dart):**

- `RateLimitError.isRetryable = false` — 429 never retried despite 3-attempt policy
- `UnknownError.isRetryable = false` — most platform errors silently dropped
- No Retry-After honored: `retryAfter` field exists but not consumed by retry loop

---

## 3. OpenCode LLM Request Pipeline

SessionRunner.runTurn(sessionId)
└─ models.resolve(session) ← catalog + route
└─ LLMClient.stream(request)
├─ compile(request) ← common→provider-native body
└─ route.streamPrepared(prepared, request)
└─ transport.frames(prepared)
└─ protocol.decodeEvent(frame) ← OpenAI/Anthropic/Bedrock
└─ protocol.stream.step(state, event)
└─ text/reasoning/tool/finish/provider-error
└─ Effect.runForEach(publish event) ← durable SQLite
└─ toolMaterialization.settle(toolCall) ← decode→execute→encode

**Robust properties:**

- `LLMError` tagged union: `RateLimitReason`, `ProviderInternalReason`, etc.
  each exposes `retryable` and `retryAfterMs` — retry decision is data-driven
- `retryDelay`: `randomUniform(0.8 * BASE * 2^attempt, 1.2 * BASE * 2^attempt)` — jittered
- Pre-stream overflow: `isContextOverflowFailure(request)` → `compactAfterOverflow`
- Durable event store: every LLMEvent persisted to SQLite before continuation
- FiberSet: concurrent tool calls via `Semaphore.makeUnsafe(1)` + `Effect.raceFirst`

---

## 4. Key Design Pattern Comparison

| Pattern                    | ChatORAI                      | OpenCode                           | Verdict                  |
| -------------------------- | ----------------------------- | ---------------------------------- | ------------------------ |
| Provider abstraction       | Resolver + buildLanguageModel | Route (Protocol + Endpoint + Auth) | OpenCode more composable |
| Retry backoff              | Fixed exp                     | Jittered exp                       | OpenCode safer           |
| Retry trigger              | isRetryable flag              | LLMErrorTag + reason.retryable     | OpenCode more granular   |
| Rate-limit armoring        | ❌ Not retried, no retryAfter | ✅ retryable + retryAfterMs        | OpenCode wins            |
| Overflow detection         | Post-request                  | Pre-request                        | OpenCode wins            |
| Session recovery           | ✅ Full event replay          | ✅ Event replay                    | Parity                   |
| Tool-ordering cancellation | Doom-loop LRU                 | FiberSemaphore + interrupt         | OpenCode wins            |
| Cancellation correctness   | Gen counter                   | FiberSet                           | Both adequate            |

---

## 5. Competitor Post-Mortem

### OpenCode Public Issues

- **#3011 (Oct 2025, open):** Retry not configurable per-provider — hardcoded max 2 attempts
- **#5485 (Dec 2025, closed):** App stalls on provider package mismatch; cleared via `rm ~/.cache/opencode`
- **NVIDIA GLM-5 (Feb 2026):** Malformed tool-call JSON from non-conforming model → parser error
- **Pattern across issues:** Provider package cache staleness is the dominant runtime failure mode

### ChatORAI Internal Findings (Source Analysis)

- **BUG 429:** `RateLimitError.isRetryable=false` — rate limits terminate the call immediately
- **BUG Unknown:** `UnknownError.isRetryable=false` — platform exceptions silently unrecovered
- **BUG Silent Fallback:** `buildLanguageModel` failure falls through `try/catch` without rethrow
- **BUG Cache Version:** `cacheVersion < 3` → full model re-discovery on every upgrade (cold-start)
- **ANTI-PATTERN:** 50ms polling `_sleep` blocks event loop microtasks

---

## 6. Refactoring Blueprint

### P0 — Patch (release-blocking)

R1. error_classifier.dart: RateLimitError.isRetryable → true
\_sleep: parse retryAfter header, honor it before exp backoff
R2. error_classifier.dart: UnknownError.isRetryable → true
fallback to NetworkError for Dio/FormatException
R3. chat_ai_service.dart: rethrow after buildLanguageModel failure
(remove fall-through silent catch)

### P1 — Iteration

R4. Implement jittered backoff: 0.8x, 1.2x _ base _ 2^attempt
R5. Pre-stream overflow: check token count vs model limit before streamText
R6. Incremental cache invalidation: bump by provider, not global clear
R7. Replace \_sleep 50ms poll with Stream.periodic + takeUntil

### P2 — Evolution

R8. ~~Drift event store~~ — ✅ IMPLEMENTED. Drift schema, EventStore, Projector, SessionRepository all operational.
R9. ProviderCircuitBreaker: 3 consecutive failures → 30s blackout per provider
R10. Per-provider HTTP timeout in chatorai.json config schema
R11. Structured error surfacing in UI (technicalDetails, retryAfter, providerId)

---

## 7. Risk Register

| Risk                                 | Likelihood                        | Impact                     | Mitigation                                          |
| ------------------------------------ | --------------------------------- | -------------------------- | --------------------------------------------------- |
| 429 silent termination               | High (shared with OpenCode #3011) | High — UX break            | R1 patch in error_classifier                        |
| Provider cache cold-start on upgrade | Certain on major version bump     | Medium                     | R6 incremental invalidation                         |
| ai_sdk_dart internal retry conflict  | Medium                            | High — silent double retry | Document contract; pin `maxRetries: 0` definitively |
| Polling sleep event loop burn        | Low-Medium                        | Low under normal load      | R7 stream-based timer                               |
| Session state loss on crash          | Low (drift implemented)           | High — data loss           | Session Core already done   |

---

## Conclusion

ChatORAI's LLM request pipeline is architecturally well-structured (sealed errors, generation cancellation, doom-loop detection) but has a **single critical semantic bug** (`RateLimitError.isRetryable=false`) that directly produces the "модели не отвечают" symptom. Fixing R1+R2+R3 resolves the user's primary complaints. The remaining roadmap (circuit-breaker, jitter, pre-stream overflow, drift) closes the structural gap to OpenCode while preserving ChatORAI's Flutter-native imperative style.
