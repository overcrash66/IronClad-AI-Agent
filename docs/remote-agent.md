# remote_agent — HTTP Sub-Agent Bridge

The `remote_agent` skill delegates tasks to an external HTTP agent endpoint such as a [LangGraph](https://github.com/langchain-ai/langgraph) server, a [DeepAgents](https://github.com/langchain-ai/deepagents) Python harness, or any OpenAI-compatible `/invoke` endpoint.

This gives IronClad access to the Python/LangGraph tool ecosystem without embedding a Python runtime in the binary.

## Configuration

Add the following to `settings.toml`:

```toml
[integrations.remote_agents]
enabled = true

[[integrations.remote_agents.endpoints]]
name    = "my-langgraph"
url     = "http://localhost:8123/invoke"
key     = ""           # optional bearer token
timeout_secs = 30
```

Multiple endpoints can be declared but **only the first** endpoint is registered as the `remote_agent` skill at startup.

### Field Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable the remote agent integration |
| `endpoints[].name` | string | — | Friendly name (used in log output) |
| `endpoints[].url` | string | — | Full URL of the `/invoke` endpoint |
| `endpoints[].key` | string | `""` | Bearer token sent as `Authorization: Bearer <key>` |
| `endpoints[].timeout_secs` | number | `30` | Per-request timeout |

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

- Only HTTPS endpoints should be used in production.  HTTP is accepted for local development (`localhost`, `127.0.0.1`).
- The bearer key is stored in `settings.toml` in plaintext.  Prefer using an environment variable override:
  ```bash
  export IRONCLAD__INTEGRATIONS__REMOTE_AGENTS__ENDPOINTS__0__KEY="my-secret"
  ```
- The remote agent can return arbitrary text that will be injected into the conversation context.  Only connect to trusted endpoints.

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
