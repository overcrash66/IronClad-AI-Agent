# Model Context Protocol (MCP) Integration

IronClad natively supports the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/), allowing you to quickly expand the agent's capabilities by connecting to external data sources and tools without writing custom Rust code.

## What is MCP?

MCP is an open standard that enables AI models to securely interact with local or remote resources. By running an MCP Server, you expose specific tools (e.g., reading files, querying a database, interacting with GitHub) that the IronClad "Dreamer" (LLM) can invoke during its planning and execution phases.

## Configuring MCP Servers

MCP servers are configured in your `settings.toml` file under the `[mcp.<server_name>]` sections.

### Local Command Execution

The most common way to run an MCP server is via local commands (e.g., Node.js or Python scripts).

**Example: Local Filesystem Access**

This exposes the `/workspace` directory to the agent.

```toml
[mcp.filesystem]
# The command to execute the MCP server
command = "npx"
# Arguments passed to the command
args = ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
```

**Example: SQLite Database Access**

This allows the agent to inspect and query a specific database (like IronClad's own memory).

```toml
[mcp.database]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-sqlite", "memory.db"]
```

## How It Works in IronClad

1. **Startup Initialization**: On startup, IronClad reads the `settings.toml` and launches all configured MCP servers as background processes via `stdin/stdout` communication.
2. **Tool Discovery**: IronClad queries each MCP server for its list of available tools.
3. **Agent Prompting**: These tools are translated into JSON schemas and injected into the LLM's system prompt.
4. **Execution**: When the LLM decides to use an MCP tool, IronClad routes the execution request to the respective MCP server, awaits the result, and feeds the output back into the conversation context.

## Security Considerations

- **Isolation**: Because MCP servers define their own bounds (e.g., the `server-filesystem` only allows access to the directories passed in its arguments), they act as an additional sandbox layer.
- **Governor Policy**: IronClad's Governor still evaluates the text generated *before* the tool call, but the actual execution happens within the MCP server process.
- **Node/Python Dependencies**: Ensure that commands like `npx` or `python` are available in the PATH of the environment running IronClad.

## Developing Your Own MCP Server

You are not limited to pre-built servers! You can write your own MCP server in TypeScript, Python, or Go to glue IronClad to your company's internal APIs.

1. Create a simple script that implements the MCP JSON-RPC protocol over standard input/output.
2. Define your custom tools (e.g., `get_user_profile`, `deploy_to_staging`).
3. Add it to `settings.toml`:
   ```toml
   [mcp.my_custom_integration]
   command = "python"
   args = ["/path/to/my_mcp_server.py"]
   ```

For tutorials on building MCP servers, refer to the [official MCP documentation](https://modelcontextprotocol.io/docs/first-server).
