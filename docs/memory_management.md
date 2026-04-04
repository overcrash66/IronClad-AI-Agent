# Memory & Session Persistence

IronClad keeps a comprehensive "Long-Term Memory" of every conversation and action ever taken. This is not just a simple chat history; it's a persistent, searchable knowledge base for your AI assistant.

## Persistent Storage

IronClad uses two local SQLite databases:
1. **`memory.db`**: Stores all chat history, session metadata, and persona-specific context.
2. **`ironclad_audit.db`**: A read-only append-only log of every tool execution, shell command, and system action.

## Sessions & Personas

Each conversation with IronClad is a **Session**.
- **Cross-Session Awareness**: You can ask IronClad about things discussed yesterday or in a different chat.
- **Persona Isolation**: Using a different persona (e.g., "Researcher" vs "Coder") helps the agent focus its retrieved context onto specialized knowledge.

### Common Memory Skills

| Skill | Usage |
|-------|-------|
| `remember` | Manually tag a piece of information for long-term storage in the `memory.db` |
| `search_history` | Semantic search across all past conversations to find a specific fact |
| `query_history` | Retrieve the last N messages from the current or a specific session |
| `query_logs` | Search the audit log for specific command outputs or errors |

## Context Compression

As sessions grow long, the LLM's context window can become full. IronClad uses **Recursive Summarization** to manage this:
1. When a session exceeds the `max_messages_per_session` limit, the oldest messages are compressed into a "context summary."
2. This summary is injected at the beginning of future turns, preserving the "gist" of the conversation indefinitely without wasting tokens.

## Configuration (`settings.toml`)

```toml
[memory]
max_messages_per_session = 1000
max_session_age_days = 30
auto_archive = true # Periodically move old sessions to cold storage

[memory.summarization]
enabled = true
min_session_age_days = 7
schedule = "0 0 3 * * *" # Daily cleanup at 3 AM
```

## Security & Maintenance

- **SQLite Backend**: Your data stays 100% local on your machine.
- **Audit Logs**: Cannot be modified by the agent, ensuring a trustworthy record of what happened.
- **Database Vacuuming**: IronClad automatically compacts the databases during the [Pulse Scheduler](pulse_scheduler.md) daily run to maintain high performance.
