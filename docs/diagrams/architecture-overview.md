# Architecture Overview Diagrams

**Last updated:** 2026-07-07

This file contains high-level mermaid diagrams for data flow, session pipeline,
tool execution, MCP topology, and config resolution.  Each diagram is
self-contained and cross-referenced to the relevant `.md` file.
---
## High-Level Data Flow

```mermaid
graph LR
    subgraph UI["Presentation Layer (Flutter)"]
        screens["Screens\n(ChatScreen, Settings…)"]
        widgets["Widgets\n(ChatInput, ChatMessageBubble…)"]
    end

    subgraph state["State Management (Riverpod 3.x)"]
        providers["Providers\n(session_providers, streaming…)"]
        notifiers["Notifiers\n(ChatScreenNotifier…)"]
    end

    subgraph core["Core Services"]
        session["SessionRunner"]
        chat["ChatAiService"]
        tool_reg["ToolRegistry"]
        perm["PermissionService"]
        catalog["ProviderCatalogService"]
        mcp["McpClientService"]
    end

    subgraph infra["Infrastructure"]
        event_store["EventStore (Drift/SQLite)"]
        projector_fn["projectEvent()\n(pure function)"]
        repo["SessionRepository"]
        prefs["SharedPreferences"]
        dio["Dio HTTP Client"]
    end

    subgraph external["External"]
        api["LLM API\n(OpenRouter / local)"]
        mcp_srv["MCP Servers\n(local stdio / remote HTTP)"]
    end

    screens --> widgets
    widgets -->|"ref.watch / ref.read"| providers
    providers --> notifiers
    notifiers --> session
    notifiers --> chat
    chat --> tool_reg
    chat --> mcp
    session -->|"appendEvent()"| repo
    repo --> event_store
    repo --> projector_fn
    projector_fn -.->|"pure function\n→ write to DB"| event_store
    session -->|"streamChatCompletion"| dio
    dio --> api
    mcp -->|"stdio / http"| mcp_srv
    catalog --> dio
    prefs -.->|"24h cache"| catalog
```
---
## Session Event Pipeline

```mermaid
graph LR
    subgraph runner["SessionRunner (Orchestrator)"]
        start["startSession()"]
        run_task["runTaskInChild()"]
        append["repository.appendEvent()"]
    end

    subgraph store["Persistence (Drift)"]
        event_tbl["events table"]
        session_tbl["sessions table"]
        msg_tbl["messages table"]
        tool_tbl["tool_results table"]
        ctx_tbl["context_epochs table"]
    end

    subgraph project["Projection"]
        project_fn["projectEvent()\n→ projectToDb()"]
        state_["SessionState\n(Equatable, not freezed)"]
    end

    subgraph repo_["SessionRepository"]
        replay_fn["replayEvents()\n(Iterable<SessionEvent>)"]
    end

    start -->|"SessionCreated"| append
    run_task -->|"ChildSessionCreated"| append
    append -->|"insert"| event_tbl
    event_tbl --> project_fn
    project_fn -->|"switch: write to"| msg_tbl
    project_fn -->|"switch: write to"| tool_tbl
    project_fn -->|"switch: write to"| ctx_tbl
    project_fn --> state_
    repo_ -->|"read events"| event_tbl
    repo_ --> project_fn
    state_ -->|"SessionID, agent,\nmessages (Equatable)"| runner
```
---
## Tool Execution Lifecycle

```mermaid
graph TD
    trigger["LLM requests tool call"]
    reg["ToolRegistry.get(toolName)"]
    perm_check["PermissionService.ask()\n(last-match-wins evaluator)"]
    decision{"Permission?"}
    ask_ui["Dialog: Once / Always / Reject"]
    cache["Cache dedup\n(question cooldown)"]
    doom["Doom-loop guard\n(max 3 steps/turn)"]
    exec["ToolExecutor.execute()\n(def.execute(input))"]
    trunc["TruncationService.output()\n2000 lines / 50 KB"]
    result["Map<String, dynamic>\n{output, metadata?, truncated?}"]
    stream_["Stream to ChatAiService\n→ UI"]

    trigger --> reg
    reg --> perm_check
    perm_check --> decision
    decision -->|"deny"| result
    decision -->|"ask"| ask_ui
    ask_ui -->|"rejected"| result
    ask_ui -->|"allowed (once)"| run_once["return result"]
    ask_ui -->|"always"| promote["promote to session ruleset"]
    promote --> run_once
    decision -->|"allow"| run_once

    run_once --> cache
    cache -->|"hit"| cached_result["return cached"]
    cache -->|"miss"| doom
    doom -->|"blocked"| doom_result["doom-loop error result"]
    doom -->|"ok"| exec
    exec --> trunc
    trunc --> result
    result --> stream_
```
---
## MCP Connection Architecture

```mermaid
graph LR
    subgraph app["ChatORAI App"]
        mcp_svc["McpClientService"]
        cfg["McpConfig\n(McpServerConfig)"]
    end

    subgraph transports["Transports (mcp_dart)"]
        stdio["StdioClientTransport\n(local servers)"]
        http_["StreamableHttpClientTransport\n(remote servers)"]
    end

    subgraph servers["MCP Servers"]
        local_srv["Local Process\n(e.g. npx my-server)"]
        remote_srv["Remote HTTP\n(e.g. https://…)"]
    end

    cfg -->|"type: local"| stdio
    cfg -->|"type: remote"| http_
    mcp_svc --> stdio
    mcp_svc --> http_
    stdio --> local_srv
    http_ --> remote_srv
    local_srv -->|"listTools / callTool"| mcp_svc
    remote_srv -->|"listTools / callTool"| mcp_svc
```
---
## Config Resolution Chain

```mermaid
graph TD
    start_["App start"]
    project["Project config\n<project>/.chatorai/chatorai.json\n(highest priority)"]
    global["Global config\n~/.config/chatorai/chatorai.json\n(fallback)"]
    schema["Validate against JSON Schema\n(chatorai_schema.dart)"]
    fallback["Empty config {} fallback\n(if neither file exists)"]
    providers_["configProvider\n(FutureProvider<ChatOrAIConfig>)"]

    start_ --> project
    project -->|"found"| schema
    project -->|"not found"| global
    global -->|"found"| schema
    global -->|"not found"| fallback
    schema --> providers_
    fallback --> providers_
```

**Note:** First-found-wins — no CLI/env overrides, no merging of multiple configs.
---
## Reference

| Diagram | Described in | Source files |
|---------|-------------|--------------|
| High-Level Data Flow | `ARCHITECTURE.md` | `main.dart`, `lib/features/`, `lib/core/` |
| Session Event Pipeline | `docs/API.md` → SessionRunner | `lib/core/session/session_runner.dart`, `event_store.dart`, `projector.dart` |
| Tool Execution Lifecycle | `docs/API.md` → Tools | `lib/core/tools/tool_registry.dart`, `tool_execution.dart` |
| MCP Connection Architecture | `docs/API.md` → McpClientService | `lib/core/mcp/mcp_client_service.dart` |
| Config Resolution Chain | `docs/configuration.md` | `lib/core/config/config_loader.dart`, `docs/xdg-paths.md` |
