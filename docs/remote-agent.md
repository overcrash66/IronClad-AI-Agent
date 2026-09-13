# remote_agent — HTTP Sub-Agent Bridge

The `remote_agent` skill delegates tasks to an external HTTP agent endpoint such as a [LangGraph](https://github.com/langchain-ai/langgraph) server, a [DeepAgents](https://github.com/langchain-ai/deepagents) Python harness, or any OpenAI-compatible `/invoke` endpoint.

This gives IronClad access to the Python/LangGraph tool ecosystem without embedding a Python runtime in the binary.

## Configuration

Add the following to `settings.toml`:

```toml
[integrations.remote_agents]
enabled = true

[[integrations.remote_agents.endpoints]]
name            = "my-langgraph"
url             = "http://localhost:8123/invoke"
key             = ""                 # optional plaintext fallback token
vault_secret_id = "langgraph_token"  # recommended: resolve bearer token from Secrets Vault
tls_pin         = ""                 # optional SHA-256 fingerprint or CA cert path
timeout_secs    = 120                # default: 120
```

Multiple endpoints can be declared; each registered endpoint is securely bound to its designated name and target URL.

### Field Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable the remote agent integration |
| `endpoints[].name` | string | — | Friendly name (used in log output and telemetry) |
| `endpoints[].url` | string | — | Full URL of the `/invoke` or OpenAI-compatible endpoint |
| `endpoints[].key` | string | `""` | Bearer token sent as `Authorization: Bearer <key>` (plaintext fallback) |
| `endpoints[].vault_secret_id` | string | `""` | ID of secret in Secrets Vault (`vault_secret_id` takes precedence over `key`) |
| `endpoints[].tls_pin` | string | `""` | Optional SHA-256 certificate fingerprint or CA bundle path for certificate pinning |
| `endpoints[].timeout_secs` | number | `120` | Per-request timeout in seconds (default: 120s) |

## Runtime Usage

The LLM calls the skill with:

```json
{
  "task": "Summarize the last 10 git commits in this repo",
  "context": "Repository: my-project, Branch: main"
}
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `task` | yes | The task description to send to the remote agent |
| `context` | no | Optional context string prepended to the task |

If `context` is non-empty the request body will contain:

```
<context>\n\n<task>
```

## Request Format

IronClad sends an OpenAI-compatible messages payload:

```json
{
  "messages": [
    { "role": "user", "content": "<task>" }
  ]
}
```

## Response Parsing

The remote agent's JSON response is parsed in this priority order:

| Shape | Extracted field |
|-------|----------------|
| `{ "output": "..." }` | `output` |
| `{ "result": "..." }` | `result` |
| `{ "content": "..." }` | `content` |
| OpenAI Chat format | `choices[0].message.content` |
| LangGraph format | `messages[-1].content` |
| Any other shape | Pretty-printed full JSON |

## Governor Classification

All remote agent calls are classified **Yellow** by the Governor — they require user approval in non-autonomous mode.  In autonomous mode (`autonomous_mode = true`) they proceed automatically.

## Security Considerations

- **SSRF & Target Hijack Prevention**: The endpoint URL is strictly fixed at startup via configuration. The LLM agent cannot override the target URL via runtime arguments (`endpoint`, `url`, etc.) — any attempt to redirect the invocation to arbitrary internal or external targets is immediately rejected with a permission error.
- **Credential Protection**: Never store bearer keys in plaintext in `settings.toml`. Instead, store the token in the encrypted [Secrets Vault](secrets_vault.md) and reference it via `vault_secret_id = "my-secret-id"`, or provide it via environment variables:
  ```bash
  export IRONCLAD__INTEGRATIONS__REMOTE_AGENTS__ENDPOINTS__0__KEY="my-secret"
  ```
- **TLS Certificate Pinning (`tls_pin`)**: When connecting to remote agents over public networks, configure `tls_pin` with a SHA-256 fingerprint or trusted CA bundle to guard against MITM interception.
- **Output Sanitization & Isolation**: The remote agent output is treated as untrusted external data:
  - Wrapped in an untrusted instruction envelope to prevent prompt injection.
  - Sanitized of control and execution tokens (`<execute>`, `</execute>`, `[Tool Output]`).
  - Strict payload limit capped at 50 KB to prevent context denial-of-service.
- **Traffic Light Telemetry**: Each remote agent invocation broadcasts a Yellow status event to the live dashboard for transparent auditability.

## Example: LangGraph Server

```python
# server.py — minimal LangGraph HTTP wrapper
from fastapi import FastAPI
from langchain_core.messages import HumanMessage
from my_graph import compiled_graph

app = FastAPI()

@app.post("/invoke")
async def invoke(body: dict):
    msgs = body.get("messages", [])
    result = await compiled_graph.ainvoke({"messages": msgs})
    return {"output": result["messages"][-1].content}
```

Start with `uvicorn server:app --port 8123` and IronClad will route tasks to it.

## Logging

Two log events are emitted at `INFO` level for each remote call:

```
Delegating task to remote agent  agent=my-langgraph endpoint=http://localhost:8123/invoke
Remote agent completed task       agent=my-langgraph output_len=342
```

Failures are returned as `Tool` errors and surfaced to the LLM as an observation.
