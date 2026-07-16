# Tool System Diagrams

**Last updated:** 2026-07-08

This file documents the tool registry, conditional registration, and execution
lifecycle.  See also `docs/API.md` → Tools for the full input-schema table.
---
## Tool Registry: Conditional Registration

```mermaid
graph TD
    app_start["App startup\n(session_providers.dart)"]
    reg_call["registerBuiltInTools()"]

    subgraph unconditional["17 unconditional (always registered)"]
        bash["bash\n(execute shell)"]
        read["read\n(file contents)"]
        edit["edit\n(text replace)"]
        write["write\n(create/overwrite)"]
        glob_["glob\n(pattern match)"]
        grep_["grep\n(content search)"]
        webfetch_["webfetch\n(url fetch)"]
        websearch_["websearch\n(SearXNG)"]
        task_["task\n(subagent spawn)"]
        question_["question\n(user prompt)"]
        todowrite_["todowrite\n(todo list)"]
        apply_patch_["apply_patch\n(diff apply)"]
        invalid_["invalid\n(placeholder)"]
        external_dir["external_directory\n(dir ops)"]
        plan_enter_["plan_enter\n(switch to plan agent)"]
        plan_exit_["plan_exit\n(exit plan mode)"]
        json_schema_["json_schema\n(schema validate)"]
    end

    subgraph conditional["3 conditional (independent checks)"]
        lsp_cond{"lspService\n!= null?"}
        fmt_cond{"formatService\n!= null?"}
        skill_cond{"skillService\n!= null?"}
        lsp_["lsp\n(LSP hover/signature)"]
        format_["format\n(code formatting)"]
        skill_["skill\n(dynamic loading)"]
    end

    reg_call --> unconditional
    reg_call --> lsp_cond
    lsp_cond -->|"yes"| lsp_
    lsp_cond -->|"no"| fmt_cond
    fmt_cond -->|"yes"| format_
    fmt_cond -->|"no"| skill_cond
    skill_cond -->|"yes"| skill_

    unconditional --> tool_registry["ToolRegistry\n(17 unconditional\n+ 0–3 conditional\n= 17–20 total)"]
    lsp_ --> tool_registry
    format_ --> tool_registry
    skill_ --> tool_registry

    tool_registry -->|"toSDKTools()"| ai_sdk["ai_sdk_dart Tool[]\n(sent to LLM)"]
```

**Registration source:** `lib/core/tools/built_in/built_in_tools.dart`
**Conversion:** `ToolRegistry.toSDKTools()` → `ai_sdk_dart` `Tool` objects

**Note:** All three conditional checks are independent `if` statements — `lsp`,
`format`, and `skill` can all be registered simultaneously if all services are
provided.  `skill` is NOT unconditional; it is only registered when
`skillService != null`.
---
## Tool Execution Request Flow

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
## Tool Output Truncation

```mermaid
graph LR
    raw["Raw tool output\n(any size)"]
    check{"Lines > 2000\nOR size > 50 KB?"}
    full["Use full output"]
    trunc["TruncationService.output()\ntrim to last 2000 lines\nOR first 50 KB"]
    copy["Full content saved to\noutputPath (shareable)"]
    display["Truncated content\n→ Map['output']"]
    ui_["UI: expandable\n(✓ icon to expand)"]

    raw --> check
    check -->|"no"| full --> display
    check -->|"yes"| trunc --> copy
    copy --> display
    display --> ui_
```
---
## Reference

| Diagram | Source |
|---------|--------|
| Conditional Registration | `lib/core/tools/built_in/built_in_tools.dart` |
| Execution Request Flow | `lib/core/tools/tool_execution.dart` |
| Truncation Service | `lib/core/tools/truncation_service.dart` |
| Permission Pipeline | `lib/core/permission/evaluator.dart`, `ruleset.dart` |
| Tool Definitions | `lib/core/tools/built_in/*.dart` (one file per tool) |
