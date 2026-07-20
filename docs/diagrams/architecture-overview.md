# Architecture Overview Diagrams

**Last updated:** 2026-07-08

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
    global["Global config\n~/.config/chatorai/chatorai.json\n(base layer)"]
    project["Project config\n<project>/.chatorai/chatorai.json\n(overlay, wins on conflict)"]
    merge["Deep merge\n(project overrides global;\nlists concatenated, deduped)"]
    schema["Validate against JSON Schema\n(chatorai_schema.dart)"]
    fallback["Empty config {} fallback\n(if neither file exists)"]
    providers_["configProvider\n(FutureProvider<ChatOrAIConfig>)"]

    start_ --> global
    global --> project
    project -->|"found"| merge
    project -->|"not found"| schema
    global -->|"not found"| fallback
    merge --> schema
    schema --> providers_
    fallback --> providers_
```

**Note:** The two layers are deep-merged: project config keys win over global base keys, while absent keys are inherited from global. Lists are concatenated with duplicates removed.
---
## Install / Upgrade Flow (Linux)

```mermaid
graph TD
    start_["User runs installer"]
    sudo_check{"Running\nas root?"}
    arch_detect["Detect architecture\n(x64 / arm64)"]
    version_resolve{"Version\nspecified?"}
    resolve_latest["Resolve latest release\nvia GitHub API"]
    use_specified["Use specified version\n(e.g. 0.1.1 or v0.1.1)"]
    download["Download tarball\nchatorai-linux-{arch}.tar.gz"]
    extract["Extract bundle"]
    install_files["Copy to /usr/local/lib/chatorai"]
    gl_check{"OpenGL\n>= 3.0?"}
    soft_gl_flag["Create .force_soft_gl flag\n(/usr/local/lib/chatorai/.force_soft_gl)"]
    create_launcher["Create /usr/local/bin/chatorai\nwith GL self-healing logic"]
    desktop_entry["Create .desktop entry\n/usr/share/applications"]
    finish["Installation complete"]

    start_ --> sudo_check
    sudo_check -->|"no"| error_sudo["Error: please run with sudo"]
    sudo_check -->|"yes"| arch_detect
    arch_detect --> version_resolve
    version_resolve -->|"no"| resolve_latest
    version_resolve -->|"yes"| use_specified
    resolve_latest --> download
    use_specified --> download
    download --> extract
    extract --> install_files
    install_files --> gl_check
    gl_check -->|"no / llvmpipe"| soft_gl_flag
    gl_check -->|"yes"| create_launcher
    soft_gl_flag --> create_launcher
    create_launcher --> desktop_entry
    desktop_entry --> finish

    %% Upgrade path (in-app)
    upgrade_cmd["chatorai upgrade [target]"]
    upgrade_download["Download tarball"]
    upgrade_extract["Extract to staging"]
    upgrade_rm["rm -rf InstallPaths.installDir\n(~/.local/share/chatorai)"]
    upgrade_cp["cp -r new bundle"]
    upgrade_done["Upgrade complete\n(launcher handles GL)\nno sudo required"]

    upgrade_cmd --> upgrade_download
    upgrade_download --> upgrade_extract
    upgrade_extract --> upgrade_rm
    upgrade_rm --> upgrade_cp
    upgrade_cp --> upgrade_done
```

**Notes:**
- Installer script: `install_chatorai.sh` (system-wide, requires `sudo`)
- In-app upgrade: `chatorai upgrade [target]` installs to user directory (`InstallPaths.installDir`), no `sudo` required
- Launcher auto-detects OpenGL < 3.0 via `glxinfo`, switches to `LIBGL_ALWAYS_SOFTWARE=1` + `GALLIUM_DRIVER=llvmpipe`
- Override with `CHATORAI_FORCE_SOFT_GL=0/1`; persistence flag `.force_soft_gl`
- On SIGSEGV=139 / SIGABRT=134, launcher transparently retries with software rendering
---
## Reference

| Diagram | Described in | Source files |
|---------|-------------|--------------|
| High-Level Data Flow | `ARCHITECTURE.md` | `main.dart`, `lib/features/`, `lib/core/` |
| Session Event Pipeline | `docs/API.md` → SessionRunner | `lib/core/session/session_runner.dart`, `event_store.dart`, `projector.dart` |
| Tool Execution Lifecycle | `docs/API.md` → Tools | `lib/core/tools/tool_registry.dart`, `tool_execution.dart` |
| MCP Connection Architecture | `docs/API.md` → McpClientService | `lib/core/mcp/mcp_client_service.dart` |
| Config Resolution Chain | `docs/configuration.md` | `lib/core/config/config_loader.dart`, `docs/xdg-paths.md` |
| Install / Upgrade Flow | `README.md`, `docs/COMMANDS.md` | `install_chatorai.sh`, `lib/core/cli/cli_commands.dart` |
