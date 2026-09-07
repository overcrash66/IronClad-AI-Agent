# IronClad Architecture

This document provides a high-level overview of IronClad's architecture and design decisions.

## Overview

IronClad is a secure autonomous AI agent built with a "Zero Trust" architecture. The system treats the LLM as an untrusted component and enforces strict policies on all actions.

## Core Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                           IronClad                                   │
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │     TUI      │    │   Telegram   │    │   HTTP API   │    │  Orchestrator │  │
│  │   (Input)    │    │   (Remote)   │    │ (Webhooks/API)│    │   (Router)    │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                   │                   │                   │          │
│         └───────────────────┼───────────────────┼───────────────────┘          │
│                             │                   │                              │
│  ┌──────────────┐   ┌───────▼───────┐           │                              │
│  │  Dashboard   │   │   Governor    │           │                              │
│  │ (Observability)│  │  (Security)   │           │                              │
│  └──────────────┘   └───────┬───────┘           │                              │
│                             │                   │                              │
│         ┌───────────────────┼───────────────────┐                              │
│         │                   │                   │                               │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐                       │
│  │   Sandbox   │    │   Skills    │    │     MCP     │                       │
│  │ (Execution) │    │   (Tools)   │    │  (External) │                       │
│  └─────────────┘    └─────────────┘    └─────────────┘                       │
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │    Vault     │    │    Memory    │    │    Audit     │    │     RAG      │ │
│  │   (Secrets)  │    │   (History)  │    │   (Logging)  │    │ (Knowledge)  │ │
│  └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Security Model

### Three-Ring Architecture

1. **The Dreamer (LLM)**: Generates intentions but has no direct system access
2. **The Governor**: Validates and gates all LLM outputs through Traffic Light policy
3. **The Executor (Sandbox)**: Runs approved commands in isolated (Docker/WSL) or native (Local) environments

### Traffic Light Policy

Commands are classified into four categories:

| Level | Meaning | Examples |
|-------|---------|----------|
| 🟢 Green | Auto-approved | `ls`, `cat`, `grep` |
| 🟡 Yellow | User notification | `touch`, `mkdir`, `cp` |
| 🔴 Red | Explicit confirmation | `curl`, `rm`, `sudo` |
| 🚫 Blocked | Cannot be approved | `/etc/passwd`, `../secrets` |

See [ADR-001](adr/001-traffic-light-policy.md) for details.

### Systemic Guardrails

In addition to the per-command classification, IronClad provides global security toggles:

- **ALLOW_SYSTEM_COMMANDS**: A global filter that must be `true` to permit any command classified as **RED** (e.g., `sudo`, `apt`) or **BLOCKED**. If `false` (default), these commands are denied even if a skill attempts to run them.
- **PYTHON_VENV_ENFORCED**: Ensures all Python-based tool execution is isolated within a virtual environment, protecting the host system from dependency corruption.

## LLM Integration

### Multi-Provider Support

IronClad supports multiple LLM providers:

- **Ollama**: Local inference (default)
- **OpenAI**: GPT-4 and compatible APIs — supports native function calling (`send_with_tools`)
- **Anthropic**: Claude models — supports native function calling via `tool_use` content blocks
- **Google Gemini**: Multimodal support
- **NVIDIA NIM**: Cloud-hosted inference

### Native Function Calling

When the active provider implements `supports_native_tools() → true` (currently OpenAI and
Anthropic), the agentic ReAct loop bypasses XML tag parsing entirely and uses the provider's
structured tool-call API. This yields higher accuracy and removes the regex/XML parsing
overhead. Providers that do not support native calling fall back to the existing XML path
automatically.

### Orchestrator

The Orchestrator handles:
- Task routing to appropriate models
- Quality assurance loops
- Tool execution coordination via the ReAct loop

### Agentic ReAct Loop

The core execution engine in `src/llm/qa_loop.rs` implements:

1. **Think** — model generates a thought and (optionally) a tool call
2. **Act** — tool is identified and dispatched (native or XML)
3. **Observe** — output is injected back into context
4. **Reflect** — after the loop converges, a one-shot self-critique pass checks the result against the original task and loops back if issues are found
5. **QA** — dedicated QA model reviews the final output (when enabled)

Maximum tool calls per turn and per task are independently configurable.

### DAG Planner

`src/planner/dag.rs` provides a parallel execution layer on top of the sequential
`TaskPlanner`. It decomposes a task into a `DagPlan` (directed acyclic graph of `DagNode`s)
where nodes only execute once their dependencies are `Completed`. Independent nodes are
launched concurrently via `tokio::spawn`.

```
TaskPlanner (sequential)    DagPlanner (parallel)
┌────────────────────┐      ┌─────────────────────────────┐
│  step 1            │      │  node 0 (no deps)            │
│  step 2            │      │  ├── node 1 (dep: 0) ─┐      │
│  step 3            │      │  └── node 2 (dep: 0) ─┤      │
└────────────────────┘      │       node 3 (deps: 1,2)      │
                            └─────────────────────────────┘
```

#### DAG Re-planning on Failure

When a DAG node fails, `replan_from_failure()` calls the planner LLM with the original
goal, the set of completed nodes, the failed node, and the error message.  The planner
returns a revised replacement sub-DAG which is grafted into the running plan.

- At most **2 re-plan attempts per node** to prevent infinite loops.
- Each re-plan event is recorded in the audit log with `actor = "dag_planner"`.
- If re-planning also fails, the node is marked `Failed` and the run continues (or stops,
  depending on whether the failed node is a dependency of remaining work).

## Execution Backends

### Sandbox Abstraction

Commands are executed in isolated environments:

- **Docker**: Ephemeral containers with resource limits
- **WSL**: Windows Subsystem for Linux integration
- **Local**: Direct host execution for maximum speed (no isolation)

See [ADR-002](adr/002-sandbox-backend-abstraction.md) for details.

## Tool System

### Built-in Skills

Some skills are conditional on configured integrations, but the runtime names below match the current registered surface.

| Skill | Description |
|-------|-------------|
| `shell_execute` | Execute commands in sandbox |
| `read_file`, `write_file`, `list_directory`, `replace_in_file` | File system operations |
| `system_info` | Get host system information |
| `grep_search` | Regex search across workspace files |
| `run_tests` | Run the project test suite inside the sandbox |
| `git_ops` | Git operations with safety filters and Traffic Light policy |
| `browser_scrape` | Web scraping with Playwright |
| `browser_visit` | Open URLs visually |
| `query_history` | Query chat history |
| `query_logs` | Query audit logs (read-only SQL) |
| `remember` | Store long-term learnings or user preferences |
| `search_history` | Search prior conversations and stored learnings |
| `search_web` | Web search |
| `deep_research` | Multi-step GitHub and web research |
| `list_tools` | Discover the currently registered tools at runtime |
| `schedule_job` | Schedule cron jobs |
| `github_list_issues` | List GitHub issues |
| `github_list_prs` | List GitHub pull requests |
| `ask_user` | Pause and request clarification from the user via TUI dialog |
| `delegate_task` | Spawn a focused sub-agent for a specific sub-task |
| `list_workspaces` | List sibling project directories |
| `browse_workspace` | Walk a workspace directory tree |
| `create_tool` | Create new tool scripts at runtime (with force/validate flags) |
| `subprocess_manager` | Manage background child CLI processes (`spawn`, `send`, `read`, `kill`, `list`) |
| `write_todos` | Persistent JSON task tracking across agent turns |
| `experiment_loop` | Autonomous iterative metric-driven code optimization loop |
| `bug_bounty_scan_py` | Blue team host OS security hardening, open-source repo SAST, and ethical bug bounty recon |
| `faceless_yt_pipeline` | Autonomous video production pipeline with TTS and subtitles |
| `delegate_to_cli_agent` | Orchestrate and delegate to external CLI coding agents (Pi, Claude Code, Aider, OpenCode, Gemini) |
| `agent_coordination` | Multi-agent coordination with task locking and shared blackboard |
| `core_memory_read`, `core_memory_write`, `core_memory_append`, `core_memory_delete` | Structured core persona and user memory block management |
| `query_knowledge_base` | Query the RAG knowledge base when RAG is enabled |
| `translate` | Translate text between languages |
| `speak` (tts) | Text-to-speech output |
| `transcribe` (stt) | Speech-to-text input |

GitHub write skills exist in source but are not currently registered at runtime. They remain disabled until a dedicated approval workflow exists for external repository mutations.

### Subprocess Orchestration Engine (`src/subprocess`)

IronClad provides multi-agent CLI subprocess management via `CliManager` and `PipedDriver`:
- Spawns background process instances using `tokio::process::Command` with piped `stdin`/`stdout`/`stderr`.
- Provides async `SubprocessHandle` for sending commands, streaming output via broadcast channels, matching patterns with regex timeouts, and sending kill signals.
- Exposes `subprocess_manager` skill for LLM control over spawned CLI instances.

### Constrained ReAct Harness (`src/react`)

Implements a typestate ReAct loop (`ReactStep<ThinkState>` → `ReactStep<ActState>` → `ReactStep<ObserveState>`):
- **Structured Output**: JSON schema validation parsing with `parse_react_response()` and automatic markdown/codeblock un-escaping.
- **Self-Correction**: Automatically generates reflection prompts when tool calls fail, forcing the LLM to analyze the error before retrying with alternative arguments.
- **Context Formulation**: Assembles user preferences, project context, and learned corrections into system prompts.

### Episodic Memory & Semantic Profiles (`src/memory`)

- **Episodic Memory**: Stores complete task trajectories (`Episode` and `Vec<TrajectoryStep>`) in the `episodic_memory` SQLite table. Used by the `AutonomousWorker` job to automatically resume failed tasks with historical step context.
- **Semantic Profiles**: Manages key-value preferences, project context, and learned corrections in the `semantic_profiles` table, auto-injecting relevant entries into system prompts during context formulation.

### Security Filters on Skills

- **shell_execute**: Strictly enforces the `ALLOW_SYSTEM_COMMANDS` flag. Commands are classified via the Governor; **RED** commands are blocked unless explicitly permitted in configuration.
- **git_ops**: `is_blocked_git_command` rejects force-push, `--no-verify`, and `../` path traversal. Write operations are classified Red by the Governor.
- **bug_bounty_scan_py**: Respects both `PYTHON_VENV_ENFORCED` for virtual environment isolation and `ALLOW_SYSTEM_COMMANDS` for host tools (e.g. `nmap`). Enforces strict scope verification (`scope.allowed_domains`), authorization confirmations, and non-destructive policies across Blue Team host defense, repository SAST, and ethical recon modes.
- **browse_workspace**: Hard-blocks access to `/etc`, `/proc`, `.ssh`, `C:\Windows`, and prevents `..` path traversal.
- **delegate_task**: Cannot call itself recursively (filtered from the sub-agent's tool list).
- **create_tool**: Python tools are syntax-validated via `ast.parse` before writing; invalid files are auto-removed.

### MCP Integration

Model Context Protocol servers provide additional tools:

```toml
[mcp.filesystem]
command = "mcp-filesystem"
args = ["/workspace"]
```

See [ADR-003](adr/003-mcp-integration-pattern.md) for details.

## Data Storage

### SQLite Databases

- `memory.db`: Chat history and sessions
- `ironclad_audit.db`: Audit log of all actions

### Schema

```sql
-- Memory
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    persona TEXT,
    created_at TEXT
);

CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    session_id TEXT,
    role TEXT,
    content TEXT,
    timestamp TEXT
);

-- Audit
CREATE TABLE audit_events (
    id TEXT PRIMARY KEY,
    timestamp TEXT,
    actor TEXT,
    action_type TEXT,
    payload TEXT,
    status TEXT
);
```

## Configuration

Configuration is loaded from multiple sources (in order of priority):

1. CLI arguments
2. Environment variables (`IRONCLAD__SECTION__KEY`)
3. `settings.toml` file
4. Default values

## Web Dashboard

The Dashboard provides a localhost web interface for observability:

- **Audit Log**: View history of all agent actions
- **Pulse Jobs**: See scheduled cron jobs
- **Recent Sessions**: Inspect recent session IDs and personas
- **Live Status**: Real-time Traffic Light status via SSE
- **Raw Logs**: Streaming log output

### Security

- Binds exclusively to `127.0.0.1` (no external access)
- Basic Auth support for credential-based access
- Recommended to set credentials via environment variables

See [Dashboard Documentation](dashboard.md) for details.

### Example Configuration

```toml
[general]
workspace_dir = "./workspace"
log_level = "info"
audit_db = "ironclad_audit.db"

[sandbox]
backend = "docker"
default_image = "alpine:latest"
timeout_secs = 60
memory_limit_mb = 128
cpu_limit = 0.5
network_enabled = false

[llm]
default_provider = "ollama"

[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"

[integrations.telegram]
enabled = false
allowed_chat_ids = []
```

## Extension Points

### Adding a New LLM Provider

1. Implement the `ModelProvider` trait
2. Add configuration struct
3. Register in `create_provider()` factory

### Adding a New Skill

1. Implement the `Skill` trait
2. Register in `SkillRegistry`

### Adding a New Sandbox Backend

1. Implement the `SandboxBackend` trait
2. Add to `create_sandbox()` factory

## RAG Knowledge Base

The RAG (Retrieval-Augmented Generation) system provides local codebase indexing and retrieval capabilities, enabling the AI to access relevant code context before answering questions or making changes.

### Architecture

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   File Watcher │────▶│  Code Parser   │────▶│   Chunker      │
│  [Background]  │     │  [Tree-sitter] │     │  [Semantic]    │
└────────────────┘     └────────────────┘     └───────┬────────┘
                                                       │
                                                       ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Orchestrator  │────▶│  RAG Skill     │────▶│  Embedding     │
│  [Auto-query]  │     │[query_knowledge_base]│  [Ollama/Cloud]│
└────────────────┘     └───────┬────────┘     └───────┬────────┘
                               │                      │
                               ▼                      ▼
                      ┌─────────────────────────────────────┐
                      │         Vector Store                 │
                      │   [In-memory with persistence]       │
                      └─────────────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| **File Watcher** | Monitors workspace for file changes and triggers incremental indexing |
| **Code Parser** | Tree-sitter based parser for semantic code understanding |
| **Chunker** | Splits code into semantic chunks (functions, classes, modules) |
| **Embedding Client** | Generates vector embeddings using Ollama, OpenAI, or NVIDIA |
| **Vector Store** | In-memory vector database with disk persistence |
| **RAG Skill** | AI tool for querying the knowledge base |
| **Retriever** | Similarity search for finding relevant code chunks |

### Orchestrator Integration

When RAG is enabled and `auto_inject_context` is true, the Orchestrator automatically queries the knowledge base for relevant context before processing tasks:

1. User submits a task
2. Orchestrator queries RAG for relevant code chunks
3. Relevant context is injected into the system prompt
4. LLM generates response with full codebase context

This reduces hallucinations and improves code understanding for large codebases.

See [RAG Documentation](rag.md) for configuration and usage details.

## Performance Considerations

- **Context Window**: Sliding window with ~10 recent messages
- **Context Compression**: When `context_compression = true` in `[llm]`, messages dropped by the sliding window are summarized via the primary LLM provider before they are discarded. The summary is injected as a pinned system message so the model retains a condensed view of earlier history. Disabled by default due to the extra LLM call cost.
- **Connection Pooling**: SQLite pool with 5 connections
- **Async I/O**: Tokio runtime for all async operations
- **Background Tasks**: Pulse scheduler runs in separate tasks
- **RAG Indexing**: Background file watching with debounced updates

## Security Considerations

- **Secret Scrubbing**: API keys redacted before LLM context
- **Audit Logging**: All actions logged to SQLite
- **Workspace Boundary**: Commands cannot escape workspace
- **Trusted Users**: Telegram users can be pre-authorized
- **RAG Privacy**: All indexing and retrieval happens locally
