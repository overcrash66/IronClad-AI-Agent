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
