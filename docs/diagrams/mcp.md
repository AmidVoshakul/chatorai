# MCP Integration Diagrams

**Last updated:** 2026-07-07

This file documents the Model Context Protocol (MCP) client architecture: transport
selection, connection lifecycle, and tool proxying.  MCP extends ChatORAI's tool
system with external capabilities from local processes or remote servers.
---
## Transport Topology

```mermaid
graph TB
    subgraph chatorai["ChatORAI Application"]
        mcp_svc["McpClientService\n(lib/core/mcp/)"]
        mcp_cfg["McpConfig\n(McpServerConfig map)"]
        tool_reg_["ToolRegistry\n(extends with MCP tools)"]
    end

    subgraph local_transport["Local Transport (stdio)"]
        stdio_transport["StdioClientTransport\n(mcp_dart)"]
        proc["Child Process\n(e.g. npx, python, binary)"]
    end

    subgraph remote_transport["Remote Transport (HTTP)"]
        http_transport["StreamableHttpClientTransport\n(mcp_dart)"]
        endpoint["HTTPS Endpoint\n(/mcp, /sse, /messages)"]
    end

    mcp_cfg -->|"type: local"| stdio_transport
    mcp_cfg -->|"type: remote"| http_transport
    mcp_svc --> stdio_transport
    mcp_svc --> http_transport

    stdio_transport -->|"spawns"| proc
    http_transport -->|"POST / GET"| endpoint

    proc -->|"stdio (JSON-RPC)"| stdio_transport
    endpoint -->|"JSON response"| http_transport

    stdio_transport -->|"listAllTools()"| mcp_svc
    http_transport -->|"listAllTools()"| mcp_svc
    mcp_svc -->|"register as ToolDef"| tool_reg_
```
---
## MCP Connection Lifecycle

```mermaid
stateDiagram-v2
    [*] --> disabled : McpClientService created

    disabled --> connecting : connect(serverName)
    connecting --> connected : handshake OK\n(initialize + tools listed)
    connecting --> failed : handshake failed

    connected --> calling : callTool(name, args)
    calling --> connected : result returned
    calling --> failed : tool execution failed

    connected --> needsAuth : OAuth required
    needsAuth --> connecting : auth completed

    connected --> needsClientRegistration : OAuth registration required
    needsClientRegistration --> connecting : registration completed

    connected --> disabled : disconnect(serverName)
    failed --> disabled : cleanup / retry
    disabled --> [*] : dispose()

    note right of connecting
        Local: spawns child process
        Remote: HTTP POST request
        Reads McpServerConfig from McpConfig
    end note

    note right of connected
        Tools available via
        mcp_svc.getToolDefs() / listAllTools()
        → merged into ToolRegistry
    end note
```
---
## MCP Config Model

```mermaid
classDiagram
    class McpConfig {
        +int? defaultTimeout "nullable, ms"
        +Map~String,McpServerConfig~ servers
    }

    class McpServerConfig {
        +String type "local | remote"
        +bool enabled
        +int? timeout "override per-server"
        +String command "for local (e.g. npx)"
        +List~String~ args "for local"
        +String? cwd "working dir (local)"
        +Map~String,String~ environment "env vars (local)"
        +String? url "for remote"
        +Map~String,String~? headers "for remote"
        +McpOAuthConfig? oauth "optional"
    }

    class McpOAuthConfig {
        +String clientId
        +String? clientSecret
        +String scope "singular, not scopes"
        +int callbackPort
        +String redirectUri
    }

    class McpToolInfo {
        +String name
        +String? description
        +Map~String, dynamic~ inputSchema
    }

    class McpContentPart {
        +String type "text / image / …"
        +String text "content for text parts"
    }

    class McpCallResult {
        +List~McpContentPart~ content
        +Map~String, dynamic~? structuredContent
        +bool isError
    }

    class McpConnectionStatus {
        <<enumeration>>
        connected
        disabled
        failed
        needsAuth
        needsClientRegistration
    }

    class McpServerStatus {
        +String name
        +McpConnectionStatus status
        +String? error
    }

    McpConfig "1" --> "*" McpServerConfig : servers
    McpServerConfig --> McpOAuthConfig : oauth
```
---
## Reference

| Diagram | Source |
|---------|--------|
| Transport Topology | `lib/core/mcp/mcp_client_service.dart` |
| Connection Lifecycle | `lib/core/mcp/mcp_client_service.dart` (`connect`, `disconnect`) |
| Config Models | `lib/core/mcp/mcp_config.dart` |
| Types | `lib/core/mcp/mcp_types.dart` |
| JSON config | `docs/configuration.md` → `mcp` section |
