# IronClad Integrations

This document covers the external integrations and interoperability features available in IronClad.

---

## LangGraph Checkpoint Compatibility

IronClad can export and import session state in a format compatible with the [LangGraph](https://github.com/langchain-ai/langgraph) `BaseCheckpointSaver` schema (v0.2+). This enables interoperability with LangGraph-based agents and tools.

### Structs

| Struct | Description |
|--------|-------------|
| `IronCladCheckpoint` | Top-level checkpoint, mirrors LangGraph's checkpoint format |
| `CheckpointConfig` | Thread/session identity (`thread_id`, optional `checkpoint_ns`) |
| `ChannelValues` | Holds the `messages` array and any extra state |
| `CheckpointMetadata` | IronClad-specific metadata (`ironclad_version`, `persona`, `tool_call_count`) |

### Functions

```rust
use ironclad::integrations::langgraph::{export_checkpoint, import_checkpoint, CheckpointConfig};

// Export current session to a LangGraph-compatible checkpoint
let config = CheckpointConfig::new("my-session-id");
let checkpoint = export_checkpoint(&config, &message_history).await?;
let json = serde_json::to_string_pretty(&checkpoint)?;

// Import a checkpoint back into IronClad messages
let messages = import_checkpoint(&checkpoint);
```

### JSON Schema (abbreviated)

```json
{
  "config": {
    "thread_id": "my-session-id",
    "checkpoint_ns": null,
    "checkpoint_id": null
  },
  "channel_values": {
    "messages": [
      { "role": "user", "content": "Hello" },
      { "role": "assistant", "content": "Hi! How can I help?" }
    ]
  },
  "channel_versions": { "messages": 2 },
  "versions_seen": { "__start__": { "messages": 2 } },
  "metadata": {
    "ironclad_version": "0.1.0",
    "persona": "developer",
    "tool_call_count": 5,
    "source": "ironclad"
  },
  "created_at": 1700000000
}
```

### Notes

- `role` values use LangGraph conventions: `"user"`, `"assistant"`, `"system"`, `"tool"`
- `channel_versions.messages` equals the number of messages in the checkpoint
- The `metadata.source` field is always `"ironclad"` to identify the origin
- Only text content is exported; image attachments are not included in checkpoints

---

## Remote Agents

IronClad can delegate sub-tasks to remote IronClad instances via the `remote_agent` skill.

Configure remote agents in `settings.toml`:

```toml
[integrations.remote_agents]
enabled = true

[[integrations.remote_agents.endpoints]]
name = "staging"
url  = "http://staging-ironclad:8080"
key  = ""          # set via IRONCLAD_REMOTE_KEY env var
timeout_secs = 60
```

---

## GitHub Webhooks

IronClad exposes `POST /api/v1/webhooks/github` for GitHub event handling. See `docs/github-action.md` for the full GitHub Actions integration guide.

---

## Telegram

Real-time progress notifications are sent to a Telegram chat when `telegram.enabled = true` in `settings.toml`. See `settings.toml` for the full configuration reference.

---

## Faceless YouTube Pipeline

The faceless YouTube pipeline is integrated as a core skill (`faceless_yt_pipeline`). 

Configuration is done via `settings.toml` under `[faceless_yt]` section.

**Key Features:**
- Configurable TTS voices per language
- Optional subtitle generation and burning
- Improved Pexels search with example topics
- Uses default LLM model from `[llm]` section

See [Faceless YouTube Documentation](faceless_youtube.md) for full details.

---

## External CLI Agents Hub (`delegate_to_cli_agent`)

IronClad includes an auto-detection registry (`CliAgentRegistry`) that scans your system for external AI coding tools and CLI agents. When detected, IronClad can orchestrate and delegate coding tasks directly to them:

| Detected Agent | CLI Command | Purpose |
|----------------|-------------|---------|
| **Pi Agent** | `pi` | Specialized autonomous TypeScript/Python/Rust coding agent |
| **Claude Code** | `claude` | Anthropic's interactive CLI coding assistant |
| **Aider** | `aider` | AI pair programmer with git tracking |
| **OpenCode** | `opencode` | Open-source terminal coding assistant |
| **Gemini CLI** | `gemini` | Google Gemini developer assistant |

### Usage:
You can invoke or delegate directly from the TUI / chat prompt:
> "Delegate this refactoring task to Pi Agent."
> "Run aider to write unit tests for the authentication module."

---

## Subprocess & PTY Manager (`subprocess_manager`)

IronClad includes a background process manager (`src/subprocess`) capable of orchestrating child CLI processes with virtual PTY terminals or piped standard IO:
- **`spawn`**: Start a background process (e.g. dev server, file watcher, compiler).
- **`send`**: Send interactive input to stdin.
- **`read`**: Stream stdout/stderr in real time.
- **`kill`**: Gracefully terminate background processes.
- **`list`**: Inspect active agent subprocesses.

---

## Multi-Agent Coordination & Shared Blackboard (`agent_coordination`)

IronClad supports multi-agent coordination backed by a persistent SQLite database (`coordination.db`):
- **Task Claiming & Locking**: Agents claim sub-tasks with lease timers to prevent race conditions.
- **Shared Blackboard**: Agents post intermediate artifacts, architectural designs, and review results for other agents to consume.
- **Actor-Based Swarm**: Coordinates specialized roles (*Architect*, *Coder*, *SecurityReviewer*, *TestEngineer*) in parallel execution pipelines.

---