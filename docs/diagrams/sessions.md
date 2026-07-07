# Session Core Diagrams

**Last updated:** 2026-07-07

This file documents the event-sourced session subsystem: Drift database schema
(ER diagram) and the `SessionEvent` state machine.
---
## Drift Database ER Diagram

```mermaid
erDiagram
    SESSIONS ||--o{ EVENTS : "generates"
    SESSIONS ||--o{ MESSAGES : "contains"
    SESSIONS ||--o{ CONTEXT_EPOCHS : "tracks"
    EVENTS ||--o{ TOOL_RESULTS : "may produce"

    SESSIONS {
        string id PK "ses_{uuid}"
        string agent "general / explore / …"
        string model_ref "catalog model id"
        string title "auto-generated or set"
        string parent_id FK "nullable (hierarchy)"
        datetime created_at
        datetime updated_at
        datetime archived_at "soft delete (nullable)"
        real cost "USD cost"
        int tokens_input "prompt tokens"
        int tokens_output "completion tokens"
        int tokens_reasoning "thinking tokens"
        int tokens_cache_read "cached read tokens"
        int tokens_cache_write "cached write tokens"
        string permission_rules "serialized PermissionRuleset"
    }

    EVENTS {
        int id PK "auto-increment"
        string session_id FK
        string event_type
        string event_data "JSON payload"
        int sequence "monotonically increasing"
        datetime created_at
    }

    MESSAGES {
        string id PK
        string session_id FK
        int seq "ordering within session"
        string role "user/assistant/system/error"
        string content "text body"
        string model "model ref used"
        string reasoning "thinking process"
        bool is_complete "streaming finished"
        bool is_error
        string error "error text (nullable)"
        string parts_json "serialized MessagePart[]"
        datetime created_at
    }

    TOOL_RESULTS {
        string id PK "UUID"
        string session_id FK
        string message_id FK
        string tool_name "bash / read / …"
        string input_json "original tool input"
        string output_text "truncated to 2000 lines / 50 KB"
        string status "success / error"
        int duration_ms
        datetime created_at
    }

    CONTEXT_EPOCHS {
        string id PK "UUID"
        string session_id FK
        string agent "agent at this revision"
        string model_ref "model at this revision"
        string prompt_text "prompt snapshot"
        int revision "epoch sequence number"
        datetime created_at
    }
```
---
## SessionEvent State Machine

```mermaid
stateDiagram-v2
    [*] --> SessionCreated : startSession()
    SessionCreated --> StepStarted : LLM turn begins

    state StepStarted {
        [*] --> TextStarted
        TextStarted --> TextDelta : stream
        TextDelta --> TextDelta : stream
        TextDelta --> TextEnded : done

        [*] --> ReasoningStarted
        ReasoningStarted --> ReasoningDelta : stream
        ReasoningDelta --> ReasoningDelta : stream
        ReasoningDelta --> ReasoningEnded : done

        [*] --> ToolInputStarted
        ToolInputStarted --> ToolInputDelta : stream
        ToolInputDelta --> ToolInputDelta : stream
        ToolInputDelta --> ToolInputEnded : done
    }

    StepStarted --> StepEnded : no tool calls
    ToolInputEnded --> ToolSuccess : tool completed
    ToolSuccess --> StepEnded : next step
    StepEnded --> ToolSuccess : tool call in next step
    StepEnded --> StepFailed : non-retryable error
    StepFailed --> StepEnded : recover
    StepFailed --> CompactionStarted : fallback compaction

    StepEnded --> CompactionStarted : token overflow
    CompactionStarted --> CompactionEnded : summary written
    CompactionEnded --> StepStarted : resumed

    StepEnded --> MessageAdded : persist message
    MessageAdded --> [*] : session saved

    SessionCreated --> ChildSessionCreated : runTaskInChild()
    ChildSessionCreated --> [*] : linked to parent

    SessionCreated --> SessionArchived : soft delete
    SessionCreated --> SessionAgentSwitched : agent changed
    SessionCreated --> SessionModelSwitched : model changed

    state TaskFlow {
        [*] --> TaskStarted
        TaskStarted --> TaskPartStarted : part begins
        TaskPartStarted --> TaskPartCompleted : part done
        TaskPartStarted --> TaskPartError : part failed
        TaskPartCompleted --> TaskPartStarted : more parts
        TaskPartCompleted --> TaskCompleted : all done
        TaskPartError --> TaskStarted : retry
    }

    SessionCreated --> TaskFlow : subagent task
    TaskCompleted --> StepEnded : task result in message

    state QuestionFlow {
        [*] --> QuestionPartStarted
        QuestionPartStarted --> QuestionPartAnswered : user responds
        QuestionPartAnswered --> StepEnded : resume
    }

    StepStarted --> QuestionFlow : question tool
```
---
## Event Sequence: Tool Call Turn (Typical)

```mermaid
sequenceDiagram
    participant UI as ChatScreen
    participant SR as SessionRunnerSession
    participant Repo as SessionRepository
    participant ES as EventStore (Drift)
    participant PR as projectEvent()
    participant CAS as ChatAiService
    participant Tool as ToolExecutor

    UI->>SR: sendMessage(prompt)
    SR->>Repo: appendEvent(MessageAdded)
    Repo->>ES: insert into events + messages
    SR->>CAS: streamChatCompletion(messages, tools)
    CAS->>SR: onToolStart(ToolStartEvent)
    SR->>Repo: appendEvent(ToolInputStarted)
    Repo->>ES: insert event
    SR->>Tool: execute(toolDef, input)
    Tool->>Tool: permission check + cache + doom-loop (max 3)
    Tool-->>SR: Map<String, dynamic> result
    SR->>Repo: appendEvent(ToolSuccess)
    Repo->>ES: insert event
    ES->>PR: projectEvent(ToolSuccess)
    PR->>Repo: projectToDb() → write tool_results row
    CAS->>SR: onCompletion(finalMessageId)
    SR->>Repo: appendEvent(StepEnded)
    Repo->>UI: state update via session_providers
```
---
## Reference

| Diagram | Source |
|---------|--------|
| ER Schema | `lib/core/session/database.dart` (Drift tables, schema.dart columns) |
| Event State Machine | `lib/core/session/events.dart` (sealed `SessionEvent`) |
| Sequence | `lib/core/session/session_runner.dart` (`SessionRunnerSession.appendEvent`) |
