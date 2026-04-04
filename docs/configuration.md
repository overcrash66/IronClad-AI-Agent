# IronClad Configuration Guide

> 💡 **Tip:** The easiest way to configure IronClad is via the **Web Dashboard**. Enable the dashboard and navigate to the **⚙ Settings** tab to securely edit these values visually without manual TOML formatting.

This document describes all configuration options for IronClad.

## Configuration Sources

IronClad loads configuration from multiple sources in order of priority:

1. **CLI arguments** (highest priority)
2. **Environment variables** (`IRONCLAD__SECTION__KEY` for nested config values)
3. **Configuration file** (`settings.toml`)
4. **Default values** (lowest priority)

## Configuration File

The main configuration file is `settings.toml` in the working directory.

### Example Configuration

```toml
[general]
workspace_dir = "./workspace"
log_level = "info"
audit_db = "ironclad_audit.db"

[security]
autonomous_mode = false

[sandbox]
backend = "docker"
socket = ""
default_image = "alpine:latest"
timeout_secs = 60
memory_limit_mb = 128
cpu_limit = 0.5
network_enabled = false

[llm]
default_provider = "ollama"
timeout_secs = 120
loop_timeout_secs = 300
max_retries = 3
qa_enabled = true
orchestrator_enabled = true
planner_cache_ttl_secs = 300
planner_cache_max_entries = 100
force_use_default_model = false
max_tool_chain_depth = 150
max_tool_calls = 30
agentic_mode = true
# session_budget_secs = 600  # optional wall-clock budget in seconds
# max_parallel_tools = 4     # max concurrent tool calls per turn
# context_compression = false # summarize dropped messages before sliding window

[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"
vision = false
planner_model = null
qa_model = null
keep_alive = "10m"

[llm.openai]
base_url = "https://api.openai.com/v1"
model = "gpt-4o"

[llm.anthropic]
base_url = "https://api.anthropic.com/v1"
model = "claude-sonnet-4-20250514"

[llm.translation]
enabled = false
base_url = ""
model = ""

[integrations.telegram]
enabled = false
allowed_chat_ids = []
trusted_chat_ids = []

[integrations.remote_agents]
enabled = false
# [[integrations.remote_agents.endpoints]]
# name = "my-langgraph"
# url  = "http://localhost:8123/invoke"
# key  = ""

[browser]
headless = true

# Web Dashboard
[dashboard]
enabled = false
port = 8080
username = ""
password = ""

# MCP Servers
[mcp.filesystem]
command = "mcp-filesystem"
args = ["/workspace"]

[mcp.database]
command = "mcp-sqlite"
args = ["memory.db"]
```

## Configuration Sections

### `[general]`

General application settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace_dir` | string | `"./workspace"` | Directory for workspace files |
| `log_level` | string | `"info"` | Logging level: trace, debug, info, warn, error |
| `audit_db` | string | `"ironclad_audit.db"` | Path to audit database |

### `[security]`

Path authorization and safety settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowed_path_patterns` | [string] | `["**"]` | Path patterns that are explicitly allowed (glob) |
| `blocked_path_patterns` | [string] | `["**/.env", ...]`| Path patterns that are explicitly blocked |
| `strict_path_validation`| boolean | `true` | Whether to enforce strict path validation |
| `max_path_length` | number | `4096` | Maximum path length (characters) |
| `autonomous_mode` | boolean | `false` | Skip TUI approval dialogs for Yellow/Red intents while still enforcing blocked operations |

### `[api]`

HTTP interface and webhook configuration.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable the HTTP API and Webhook server |
| `host` | string | `"127.0.0.1"` | Host IP to bind the server to |
| `port` | number | `3000` | Port to listen on |
| `api_key` | string? | `null` | Optional API key for authenticating tasks |

### `[dashboard]`

Web dashboard for observability and management.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable the web dashboard |
| `port` | number | `8080` | Port to listen on (bound to 127.0.0.1 only) |
| `username` | string? | `null` | Username for Basic Auth |
| `password` | string? | `null` | Password for Basic Auth |

**Security Note:** The dashboard binds exclusively to `127.0.0.1` and cannot be accessed from external networks. Always set credentials when enabling the dashboard.

If the configured dashboard port is unavailable, IronClad will try the next three ports automatically before giving up.

**Environment Variables:**
```bash
IRONCLAD__DASHBOARD__ENABLED=true
IRONCLAD__DASHBOARD__PORT=8080
IRONCLAD__DASHBOARD__USERNAME=admin
IRONCLAD__DASHBOARD__PASSWORD=your_secure_password
```

See [Dashboard Documentation](dashboard.md) for more details.

### `[sandbox]`

Sandbox execution settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `backend` | string | `"docker"` | Backend: "docker", "wsl", or "local" |
| `socket` | string | `""` | Docker socket path (auto-detected if empty) |
| `default_image` | string | `"alpine:latest"` | Default container image or WSL distro |
| `timeout_secs` | number | `60` | Command timeout in seconds |
| `memory_limit_mb` | number | `128` | Memory limit in MB (Docker only) |
| `cpu_limit` | number | `0.5` | CPU limit (Docker only) |
| `network_enabled` | boolean | `false` | Enable network access |

### `[llm]`

LLM provider settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `default_provider` | string | `"ollama"` | Default provider name |
| `timeout_secs` | number | `120` | Request timeout in seconds |
| `loop_timeout_secs` | number | `300` | QA loop timeout in seconds |
| `max_retries` | number | `3` | Maximum retry attempts |
| `qa_enabled` | boolean | `true` | Enable QA review loop |
| `max_model_size_b` | number | `null` | Max Ollama model size in billions of parameters |
| `orchestrator_enabled`| boolean | `true` | Enable intelligent model routing |
| `planner_cache_ttl_secs` | number | `300` | Planner cache TTL in seconds |
| `planner_cache_max_entries` | number | `100` | Maximum cached planner entries |
| `force_use_default_model`| boolean | `false` | Always execute on the default provider even if routing suggests another model |
| `max_tool_chain_depth` | number | `150` | Maximum autonomous tool-chain depth |
| `turbo_mode` | boolean | `false`| Disable orchestrator routing and QA for maximum speed |
| `max_tool_calls` | number | `30` | Maximum tool calls allowed per task |
| `agentic_mode` | boolean | `true` | Enable ReAct-style reasoning and multi-step autonomous execution |
| `session_budget_secs` | integer? | `null` | Wall-clock seconds before the session exits gracefully; `null` = no limit |
| `max_parallel_tools` | integer | `4` | Maximum number of tool calls dispatched concurrently in a single turn |
| `context_compression` | boolean | `false` | Summarize dropped messages before applying the sliding window (requires an LLM call) |
| `local_stt_cmd` | string? | `null` | Local STT command template |
| `local_tts_cmd` | string? | `null` | Local TTS command template |

### `[llm.ollama]`

Ollama-specific settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `base_url` | string | `"http://127.0.0.1:11434"` | Ollama API URL |
| `model` | string | `"llama3"` | Model name |
| `vision` | boolean | `false` | Enable vision support |
| `planner_model` | string? | `null` | Model for planning tasks |
| `qa_model` | string? | `null` | Optional model dedicated to QA review |
| `keep_alive` | string | `"10m"` | Keep the model loaded in memory between requests |
| `thinking_model_patterns` | [string] | `["qwen", "qwq", "deepseek-r1"]` | Patterns used to detect thinking/reasoning models |

### `[llm.openai]`

OpenAI-specific settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `base_url` | string | `"https://api.openai.com/v1"` | API URL |
| `model` | string | `""` | Model name |
| `vision` | boolean? | `null` | Override model vision capability when needed |
| `thinking_model_patterns` | [string] | `["qwen", "qwq", "deepseek-r1"]` | Patterns for OpenAI-compatible thinking models |
| `reasoning_effort` | string? | `null` | Native OpenAI o-series reasoning effort (`low`, `medium`, `high`) |

### `[llm.anthropic]`

Anthropic-specific settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `base_url` | string | `"https://api.anthropic.com/v1"` | API URL |
| `model` | string | `""` | Model name |
| `vision` | boolean? | `null` | Override model vision capability when needed |

### `[llm.gemini]`

Google Gemini-specific settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `base_url` | string | `"https://generativelanguage.googleapis.com/v1beta"` | API URL |
| `model` | string | `"gemini-1.5-pro"` | Model name |
| `vision` | boolean | `true` | Whether the selected Gemini model supports vision |

### `[llm.nvidia]`

NVIDIA-specific settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `base_url` | string | `"https://integrate.api.nvidia.com/v1"` | API URL |
| `model` | string | `"meta/llama-3.1-70b-instruct"` | Model name |
| `api_key` | string? | `null` | Optional inline API key override |
| `vision` | boolean? | `null` | Override model vision capability when needed |

### `[llm.translation]`

Translation settings for multilingual support.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable translation |
| `base_url` | string | `""` | Translation API URL |
| `model` | string | `""` | Translation model |

## Performance Tuning

IronClad provides several options to optimize performance when using Ollama locally.

### Turbo Mode

Enable turbo mode for maximum speed by setting `turbo_mode = true` in the `[llm]` section:

```toml
[llm]
turbo_mode = true
```

This disables:
- Orchestrator routing (model selection)
- QA review loop

**Best for**: Simple queries, quick tasks, when you know the default model is appropriate.

### Local Execution Backend (No Sandbox)

For absolute maximum speed, use the `local` backend to run commands directly on the host system without the overhead of containerization or virtualization:

```toml
[sandbox]
backend = "local"
```

**Impact**: Command execution starts instantly and has full access to host resources.

**Security Warning**: This backend provides **NO isolation**. Use it only in trusted environments.

### Keep-Alive Configuration

Keep the model loaded in memory between requests:

```toml
[llm.ollama]
keep_alive = "10m"  # Keep model loaded for 10 minutes
```

Values:
- `"10m"` - 10 minutes (default)
- `"1h"` - 1 hour
- `"-1"` - Keep indefinitely
- `""` - Unload immediately after request

**Impact**: Subsequent requests are 0.5-2 seconds faster as the model is already in memory.

#### Simple Query Detection

The system automatically skips QA review for simple conversational inputs:
- Greetings: "hello", "hi", "hey", etc.
- Acknowledgments: "thanks", "ok", "yes", "no", etc.
- Very short queries (< 10 characters)

This saves 1-3 seconds per simple query.

### Disabling QA Review

For faster responses, disable QA review:

```toml
[llm]
qa_enabled = false
```

**Trade-off**: No quality validation of responses. Best for simple, well-defined tasks.

### Disabling Orchestrator

Skip model routing and use the default model directly:

```toml
[llm]
orchestrator_enabled = false
```

**Trade-off**: No intelligent model selection. Best when you have a single capable model.

### Performance Profiles

| Profile | Orchestrator | QA | Use Case |
|--------|-------------|-----|---------|
| Maximum Speed | Disabled | Disabled | Quick responses, simple tasks |
| Balanced | Enabled | Enabled | Complex tasks requiring quality |
| Maximum Quality | Enabled | Enabled | Full planning and review |
| Maximum Performance| Disabled | Disabled | Low-latency local mode |

#### Maximum Speed (Turbo)
```toml
[llm]
turbo_mode = true
[llm.ollama]
keep_alive = "10m"
```

#### Balanced (Default)
```toml
[llm]
orchestrator_enabled = true
force_use_default_model = false
qa_enabled = true
[llm.ollama]
keep_alive = "10m"
```

#### Maximum Quality
```toml
[llm]
orchestrator_enabled = true
force_use_default_model = false
qa_enabled = true
[llm.ollama]
keep_alive = "30m"
```

### Expected Performance

| Configuration | Simple Query | Complex Task |
|--------------|--------------|--------------|
| Maximum Speed | 2-5s | 10-30s |
| Balanced | 5-15s | 15-45s |
| Maximum Quality | 10-30s | 30-90s |

## Other Configuration Sections

### `[memory]`

Memory persistence and retention policy settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `max_messages_per_session` | number | `1000` | Max messages to keep in history per session |
| `max_session_age_days` | number | `30` | Days before archiving sessions |
| `auto_archive` | boolean | `true` | Automatically archive old sessions |
| `max_connections` | number | `10` | Max database connections |
| `cleanup_interval_hours`| number | `24` | Interval in hours between cleanup runs |

### `[memory.summarization]`

Memory summarization settings for condensing old sessions into learnings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable automatic summarization of old sessions |
| `min_session_age_days` | number | `7` | Minimum age in days before a session can be summarized |
| `max_sessions_per_run` | number | `10` | Maximum sessions to summarize in one run |
| `delete_after_summarization` | boolean | `true` | Whether to delete raw logs after summarization |
| `max_learnings_in_context` | number | `20` | Maximum learnings to include in context |
| `schedule` | string | `"0 0 3 * * *"` | Cron schedule for summarization job (default: 3 AM daily) |

**Environment Variables:**
```bash
IRONCLAD__MEMORY__SUMMARIZATION__ENABLED=true
IRONCLAD__MEMORY__SUMMARIZATION__MIN_SESSION_AGE_DAYS=7
IRONCLAD__MEMORY__SUMMARIZATION__MAX_SESSIONS_PER_RUN=10
IRONCLAD__MEMORY__SUMMARIZATION__DELETE_AFTER_SUMMARIZATION=true
IRONCLAD__MEMORY__SUMMARIZATION__MAX_LEARNINGS_IN_CONTEXT=20
IRONCLAD__MEMORY__SUMMARIZATION__SCHEDULE="0 0 3 * * *"
```

### `[integrations.telegram]`

Telegram bot integration.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable Telegram integration |
| `allowed_chat_ids` | [number] | `[]` | Allowed chat IDs |
| `trusted_chat_ids` | [number] | `[]` | Trusted chat IDs (auto-approve commands) |

### `[integrations.remote_agents]`

HTTP bridge to external agent endpoints (LangGraph, DeepAgents, or any OpenAI-compatible server).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable the remote agent integration |
| `endpoints[].name` | string | — | Friendly endpoint name |
| `endpoints[].url` | string | — | Full URL of the `/invoke` endpoint |
| `endpoints[].key` | string | `""` | Optional bearer token |
| `endpoints[].timeout_secs` | number | `30` | Per-request timeout |

Example:

```toml
[integrations.remote_agents]
enabled = true

[[integrations.remote_agents.endpoints]]
name         = "my-langgraph"
url          = "http://localhost:8123/invoke"
key          = ""
timeout_secs = 30
```

Only the first configured endpoint is registered.  See [remote-agent.md](remote-agent.md) for full details.

### GitHub Integration

GitHub integration and the `deep_research` skill can use a GitHub personal access token stored in the vault:

```powershell
$env:IRONCLAD_GITHUB_KEY="ghp_..."
```

The token needs the following scopes depending on what you want to access:

| Scope | Skills enabled |
|-------|----------------|
| `repo` (read) | `github_list_issues`, `github_list_prs`, and access to private repositories during `deep_research` |
| `read:org` | Deep research across org repos |

When the token is present, IronClad currently registers the read-only GitHub skills `github_list_issues` and `github_list_prs`.
GitHub write skills exist in source but are intentionally disabled at runtime until a dedicated approval workflow exists for external repository mutations.

### `[browser]`

Browser automation settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `headless` | boolean | `true` | Run browser in headless mode |

Set `headless = false` if you want `browser_visit` to open a visible browser window.

### `[tools]`

Local tool execution and security settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `python_venv_enforced`| boolean | `true` | Enforce Python venv isolation for all tool execution |
| `allow_system_commands`| boolean | `false` | Allow all execution paths (Local Tools, Shell, specialized Skills) to run system commands |

#### `[tools.extensions]`

Mapping of file extensions to execution commands.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `py` | string | `"python3"` | Command used to execute Python tools |
| `sh` | string | `"bash"` | Command used to execute shell tools |
| `js` | string | `"node"` | Command used to execute JavaScript tools |
| `ps1` | string | `"powershell -ExecutionPolicy Bypass -File"` | Command used to execute PowerShell tools |

## Tool Security & Isolation

IronClad is "Secure-by-Default," meaning that out-of-the-box, the agent is restricted from making unauthorized changes to your system.

### Python Isolation (`python_venv_enforced`)

By default, IronClad enforces virtual environment (venv) isolation for all Python-based tools. This prevents the "Externally Managed Environment" error (PEP 668) common on modern Linux distros and protects your system Python from dependency conflicts.

- **`true` (Default)**: IronClad creates and uses a dedicated `venv` in your tool directory.
- **`false`**: Allows falling back to the system Python. Use this if your environment is already isolated (e.g., inside a Docker container) and you need to use pre-installed system packages.

### System Command Control (`allow_system_commands`)

This flag provides a secondary security layer beyond simple path validation. It controls whether tools (and the LLM itself) can execute "dangerous" system-level commands.

- **`false` (Default)**: Every command is classified via the **Traffic Light** policy. Any command classified as **RED** (e.g., `sudo`, `apt-get`, `rm -rf`, or arbitrary `curl` downloads) is strictly blocked.
- **`true`**: Relaxes this restriction, allowing any command permitted by the host OS or sandbox.

**Environment Variables:**
```bash
# Security enforcement
IRONCLAD__TOOLS__PYTHON_VENV_ENFORCED=true
IRONCLAD__TOOLS__ALLOW_SYSTEM_COMMANDS=false

# Extension overrides (comma-separated if needed)
IRONCLAD__TOOLS__EXTENSIONS__PY="python3.11"
```

### `[mcp.*]`

MCP server configurations. Each server is defined as a separate section.

| Option | Type | Description |
|--------|------|-------------|
| `command` | string | Command to run MCP server |
| `args` | [string] | Arguments for the command |

### `[rag]`

RAG (Retrieval-Augmented Generation) knowledge base settings for codebase indexing and retrieval.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable RAG functionality entirely |
| `db_path` | string | `".ironclad/vectors"` | Vector database path (relative to workspace or absolute) |
| `embedding_provider` | string | `"ollama"` | Embedding provider: "ollama", "openai", or "nvidia" |
| `embedding_model` | string | `"nomic-embed-text"` | Model name for embeddings |
| `chunk_size` | number | `512` | Target chunk size in tokens (100-4000) |
| `chunk_overlap` | number | `50` | Overlap between chunks in tokens |
| `max_results` | number | `10` | Maximum number of chunks to retrieve per query (1-50) |
| `min_similarity` | number | `0.7` | Minimum similarity score threshold (0.0-1.0) |
| `include_patterns` | [string] | `["**/*.rs", "**/*.py", ...]` | Glob patterns for files to include |
| `exclude_patterns` | [string] | `["**/target/**", ...]` | Glob patterns for files to exclude |
| `auto_index` | boolean | `true` | Automatically index workspace on startup |
| `watch_changes` | boolean | `true` | Watch for file changes and update index |
| `watch_debounce_ms` | number | `1000` | Debounce interval for file changes in milliseconds |
| `max_file_size_kb` | number | `500` | Maximum file size to index in KB |
| `auto_inject_context` | boolean | `true` | Automatically inject RAG context into system prompt |
| `max_context_tokens` | number | `2000` | Maximum tokens of RAG context to inject |

#### Embedding Providers

**Ollama (Recommended for Local)**

```toml
[rag]
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"  # or "all-minilm", "mxbai-embed-large"
```

Pull the embedding model first:
```bash
ollama pull nomic-embed-text
```

**OpenAI (Cloud)**

```toml
[rag]
embedding_provider = "openai"
embedding_model = "text-embedding-3-small"  # or "text-embedding-3-large"
```

Requires `IRONCLAD_OPENAI_KEY` environment variable.

**NVIDIA NIM (Cloud)**

```toml
[rag]
embedding_provider = "nvidia"
embedding_model = "nvidia/nv-embedqa-e5-v5"
```

Requires `IRONCLAD_NVIDIA_KEY` environment variable.

#### File Patterns

Default include patterns:
```toml
include_patterns = [
    "**/*.rs", "**/*.py", "**/*.js", "**/*.ts",
    "**/*.jsx", "**/*.tsx", "**/*.go", "**/*.java",
    "**/*.md", "**/*.txt"
]
```

Default exclude patterns:
```toml
exclude_patterns = [
    "**/target/**", "**/node_modules/**", "**/.git/**",
    "**/dist/**", "**/build/**", "**/.venv/**"
]
```

#### Environment Variables

```bash
# Enable/disable RAG
IRONCLAD__RAG__ENABLED=true

# Embedding configuration
IRONCLAD__RAG__EMBEDDING_PROVIDER=ollama
IRONCLAD__RAG__EMBEDDING_MODEL=nomic-embed-text

# Retrieval settings
IRONCLAD__RAG__MAX_RESULTS=15
IRONCLAD__RAG__MIN_SIMILARITY=0.75

# File patterns (comma-separated)
IRONCLAD__RAG__INCLUDE_PATTERNS="**/*.rs,**/*.py,**/*.md"
IRONCLAD__RAG__EXCLUDE_PATTERNS="**/target/**,**/node_modules/**"

# Indexing behavior
IRONCLAD__RAG__AUTO_INDEX=true
IRONCLAD__RAG__WATCH_CHANGES=true
```

#### Example Configurations

**Basic Local Setup (Ollama)**

```toml
[rag]
enabled = true
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"
auto_index = true
watch_changes = true
```

**Cloud Setup (OpenAI)**

```toml
[rag]
enabled = true
embedding_provider = "openai"
embedding_model = "text-embedding-3-small"
chunk_size = 1024
max_results = 15
```

**Large Codebase Optimization**

```toml
[rag]
enabled = true
embedding_provider = "ollama"
embedding_model = "mxbai-embed-large"
chunk_size = 256
chunk_overlap = 25
max_results = 20
min_similarity = 0.6
max_file_size_kb = 1000
exclude_patterns = [
    "**/target/**", "**/node_modules/**", "**/.git/**",
    "**/dist/**", "**/build/**", "**/.venv/**",
    "**/vendor/**", "**/__pycache__/**"
]
```

## Environment Variables

Environment variables override configuration file settings. Use the prefix `IRONCLAD_` and double underscores for nested keys.

### Examples

```bash
# Set LLM provider
export IRONCLAD__LLM__DEFAULT_PROVIDER="openai"

# Set Ollama model
export IRONCLAD__LLM__OLLAMA__MODEL="llama3"

# Enable Telegram
export IRONCLAD__INTEGRATIONS__TELEGRAM__ENABLED="true"

# Set allowed chat IDs
export IRONCLAD__INTEGRATIONS__TELEGRAM__ALLOWED_CHAT_IDS="123456,789012"
```

### API Keys

API keys are loaded from environment variables for security:

```bash
export IRONCLAD_OPENAI_KEY="sk-..."
export IRONCLAD_ANTHROPIC_KEY="sk-ant-..."
export IRONCLAD_GITHUB_KEY="ghp-..."
export IRONCLAD_NVIDIA_KEY="nvapi-..."
export IRONCLAD_TELEGRAM_KEY="123456:ABC-..."
```

## Personas

Personas are defined in `personas.toml`:

```toml
[coder]
name = "Coder"
description = "A coding-focused assistant"
system_prompt = """You are an expert software developer..."""

[analyst]
name = "Analyst"
description = "A data analysis assistant"
system_prompt = """You are a data analysis expert..."""
```

## CLI Arguments

Override configuration via command line:

```bash
# Use specific config file
ironclad --config custom-settings.toml

# Override workspace
ironclad --workspace /path/to/workspace

# Override provider
ironclad --provider openai

# Resume session
ironclad --session <session-id>

# List sessions
ironclad sessions

# Orchestration mode
ironclad orchestrate --task "Write a hello world program"
ironclad orchestrate --task "Analyze data" --persona analyst
```

## Validation

IronClad validates configuration on startup:

- `workspace_dir` cannot be system root (`/` or `C:\`)
- Required fields must be present
- Numeric values must be positive where applicable

## See Also

- [Architecture Documentation](architecture.md)
- [Contributing Guide](../CONTRIBUTING.md)
- [write_todos Skill](write-todos.md)
- [Remote Agent Bridge](remote-agent.md)
- [program.md Workspace Behaviour](program-md.md)
- [Session Budget](session-budget.md)
- [Concurrent Tool Dispatch](concurrent-tools.md)
- [GitHub Action Template](github-action.md)
- [Benchmark Suite](benchmarks.md)
- [System Prompts](prompts.md)
