# ADR-003: Model Context Protocol Integration

## Title

Model Context Protocol (MCP) Integration Pattern

## Status

Accepted

## Context

IronClad needs a way to extend its capabilities with external tools. The Model Context Protocol (MCP) provides a standardized way for AI models to interact with external tools and data sources.

Requirements:
1. Support multiple MCP servers simultaneously
2. Discover tools automatically from servers
3. Execute tools with proper argument validation
4. Handle server failures gracefully
5. Maintain persistent connections for performance

## Decision

We implement MCP support using a client-based architecture:

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        IronClad                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   SkillRegistry                       │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │    │
│  │  │ Built-in│ │  MCP    │ │  MCP    │ │  Local  │   │    │
│  │  │ Skills  │ │ Skill 1 │ │ Skill 2 │ │ Tools   │   │    │
│  │  └─────────┘ └────┬────┘ └────┬────┘ └─────────┘   │    │
│  └───────────────────┼───────────┼─────────────────────┘    │
│                      │           │                            │
│  ┌───────────────────┴───────────┴─────────────────────┐    │
│  │                    McpClient                          │   │
│  │  ┌─────────────────┐  ┌─────────────────┐           │    │
│  │  │ Persistent Conn │  │ Request/Response │           │    │
│  │  │ Process Manager │  │ Handler          │           │    │
│  │  └─────────────────┘  └─────────────────┘           │    │
│  └──────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
  ┌─────────────┐      ┌─────────────┐
  │ MCP Server  │      │ MCP Server  │
  │ (filesystem)│      │ (database)  │
  └─────────────┘      └─────────────┘
```

### McpClient Design

```rust
pub struct McpClient {
    command: String,
    args: Vec<String>,
    child: Mutex<Option<Child>>,
    request_id: AtomicI64,
}
```

Key features:
- **Persistent Connection**: Spawns server process once and maintains connection
- **Auto-Reconnect**: Detects dead connections and reconnects automatically
- **Request ID Tracking**: Atomic counter for JSON-RPC request IDs
- **Graceful Shutdown**: Proper cleanup on drop

### Tool Discovery

On startup, IronClad:
1. Reads MCP server configurations from `settings.toml`
2. Spawns each MCP server process
3. Calls `tools/list` to discover available tools
4. Wraps each tool as a `Skill` in the registry

### Tool Execution

```rust
pub struct McpSkill {
    client: Arc<McpClient>,
    tool_def: Tool,
}

#[async_trait]
impl Skill for McpSkill {
    async fn execute(&self, args: Value) -> Result<String> {
        self.client.call_tool(&self.tool_def.name, args).await
    }
}
```

## Configuration

```toml
[mcp.filesystem]
command = "mcp-filesystem"
args = ["/path/to/workspace"]

[mcp.database]
command = "mcp-sqlite"
args = ["memory.db"]
```

## Consequences

### Positive
- Standardized tool interface
- Easy to add new tools without code changes
- Tools run in separate processes (isolation)
- Automatic tool discovery

### Negative
- Process management complexity
- Potential for zombie processes if not cleaned up
- Latency from IPC
- Error handling across process boundaries

## Security Considerations

1. **Process Isolation**: MCP servers run as separate processes
2. **Argument Validation**: JSON schema validation before execution
3. **Timeout Protection**: Configurable timeout for tool calls
4. **Rate Limiting**: Prevent runaway tool calls (planned)

## Alternatives Considered

### 1. In-Process Tools Only
Only built-in tools compiled into the binary. Rejected as too limiting for extensibility.

### 2. HTTP-Based Tools
REST API for tool integration. Rejected as MCP is becoming the standard.

### 3. Plugin Architecture
Dynamic library loading for tools. Rejected due to security concerns and platform complexity.

### 4. One-Off Process Spawning
Spawn new process for each tool call. Rejected due to performance overhead.

## Implementation Details

### JSON-RPC Protocol

MCP uses JSON-RPC 2.0:

```json
// Request
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "read_file",
    "arguments": { "path": "test.txt" }
  },
  "id": 1
}

// Response
{
  "jsonrpc": "2.0",
  "result": {
    "content": [{ "type": "text", "text": "file contents" }]
  },
  "id": 1
}
```

### Error Handling

```rust
pub enum McpError {
    ConnectionFailed(String),
    ToolNotFound(String),
    InvalidArguments(String),
    ExecutionFailed(String),
    Timeout,
}
```

## Future Enhancements

1. **Tool Versioning**: Support multiple versions of same tool
2. **Tool Dependencies**: Declare and resolve tool dependencies
3. **Hot Reloading**: Add/remove MCP servers without restart
4. **Tool Marketplace**: Discover and install MCP servers
5. **Sandboxed MCP**: Run MCP servers in containers

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [MCP TypeScript SDK](https://github.com/anthropics/mcp-typescript-sdk)
