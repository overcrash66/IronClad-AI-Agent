# IronClad User Guide

A comprehensive guide to understanding and using IronClad, the secure autonomous AI agent.

## What is IronClad?

IronClad is a secure autonomous AI agent built in Rust that treats the LLM (Large Language Model) as an untrusted component. Every action the LLM proposes passes through a policy engine (called "The Governor") before reaching the system, providing autonomous capability without sacrificing security.

## What Problem Does IronClad Solve?

Traditional AI agents give LLMs direct access to system tools, creating significant security risks. IronClad solves this by implementing a three-ring security architecture that isolates the LLM from direct system access while still allowing it to perform useful autonomous tasks through controlled tool execution.

## Key Features

### Core Agent Capabilities
- **ReAct Loop**: Think → Act → Observe cycles with multi-tool dispatch per turn
- **Native Tool Calling**: Structured APIs for OpenAI and Anthropic; XML parsing fallback for others
- **Self-Reflection**: After completing a task, the agent critiques its own output and loops back to fix issues
- **DAG Planner**: Decomposes complex tasks into a parallel directed acyclic graph
- **DAG Re-planning**: When a node fails, the planner LLM generates a revised sub-DAG (max 2 attempts)
- **Sub-Agent Delegation**: `delegate_task` spawns an isolated sub-agent for focused sub-tasks
- **Context Compression**: Optionally summarizes dropped messages before applying the sliding window
- **Session Budget**: Wall-clock time limit that gracefully stops runaway sessions

### Built-in Skills (Tools)
- **File Operations**: read, write, list, search, replace files
- **Shell Commands**: Execute commands, run tests, get system info
- **Git Operations**: Status, diff, log, branch, stash (with safety controls)
- **Web & Research**: Web search, browser automation, deep research (GitHub + arXiv + Semantic Scholar)
- **GitHub Integration**: List issues and pull requests
- **Memory**: Remember facts, search history, query logs
- **Planning & Coordination**: Delegate tasks, list tools, ask user, write todos
- **Scheduling**: Schedule recurring jobs
- **Workspace Management**: List workspaces, browse, create tools
- **Knowledge Base**: Query RAG (Retrieval-Augmented Generation) system
- **Media**: Text-to-speech, speech-to-text, translation
- **Remote Agents**: Delegate to external HTTP endpoints

### Security Features
- **Three-Ring Architecture**: LLM → Governor → Executor — the LLM never touches the system directly
- **Traffic Light Policy**: Every action classified: Green (auto), Yellow (notify), Red (confirm), Blocked
- **Secret Scrubbing**: API keys are redacted from all LLM context
- **Workspace Boundary**: File and shell skills cannot escape the configured workspace
- **Git Safety**: Force-push, `--no-verify`, and `../` traversal are hard-blocked
- **Audit Log**: Every prompt, response, and command recorded in `ironclad_audit.db` (SQLite)

## Why IronClad is Powerful

IronClad combines the autonomy of AI agents with enterprise-grade security. Unlike other agents that either sacrifice security for functionality or vice versa, IronClad provides both through its innovative Three-Ring Security Model. This allows organizations to safely deploy AI agents that can:
- Perform complex multi-step tasks autonomously
- Access and manipulate files, code, and data within safe boundaries
- Integrate with existing systems via APIs and webhooks
- Operate continuously with built-in safety controls
- Scale from development to production with different execution backends

## Installation and Getting Started

### Prerequisites
- [Ollama](https://ollama.com/) with a model pulled (e.g., `ollama pull llama3`)
- WSL2 or Docker (optional, only needed for `wsl` / `docker` backends)
- Rust stable toolchain (only required if building from source)

### Installation

#### Option 1: Download Release (Recommended)
The fastest way to get started is to download the latest pre-built binary from the [Releases](https://github.com/overcrash66/IronClad/releases) page for your operating system.
1. Download the archive (`.zip` for Windows, `.tar.gz` for Linux/macOS).
2. Extract the archive to a folder.

#### Option 2: Build from Source
If you prefer to build manually or are contributing to development:
```bash
git clone https://github.com/overcrash66/IronClad.git
cd IronClad
cargo build --release
```

### Running IronClad

If you downloaded the release:
- **Windows**: Run `ironclad.exe`
- **Linux/macOS**: Run `./ironclad`

If you built from source:
```bash
cargo run
# or directly
./target/release/ironclad
```

### First Run Experience
Once IronClad starts, you have two primary interfaces:
1. **Web Dashboard** (Recommended): Open `http://127.0.0.1:8080` in your browser for visual configuration and monitoring
2. **Terminal User Interface (TUI)**: IronClad opens an interactive TUI in your terminal where you can type tasks and press Enter

The Web Dashboard provides the easiest way to configure IronClad entirely visually through its **⚙ Settings** and **📖 Guides** tabs.

## How to Use IronClad

### Basic Usage
1. Start IronClad using `cargo run` or the release binary
2. Choose your interface:
   - **Web Dashboard**: Visit `http://127.0.0.1:8080` for a graphical experience
   - **Terminal**: Type your task directly in the TUI and press Enter
3. Watch as IronClad:
   - Understands your request
   - Plans the necessary steps using its DAG planner
   - Executes actions through secure tool calls
   - Reflects on results and improves output
   - Returns the completed task

### Running Examples
IronClad includes several example programs in the `examples/` directory:
- `examples/basic_usage.rs` - Simple agent interaction
- `examples/audit_logging.rs` - Working with audit logs
- `examples/governor_policy.rs` - Understanding traffic light policies
- `examples/mcp_tools.rs` - Using Model Context Protocol
- `examples/sandbox_execution.rs` - Testing different backends
- `examples/skills_registry.rs` - Exploring available skills

To run an example:
```bash
cargo run --example basic_usage
```

## How to Integrate IronClad

### HTTP API
IronClad provides an Axum-based REST API:
- **POST /api/v1/tasks** - Submit a new task
- **GET /api/v1/sessions/:id/status** - Check task status
- **POST /api/v1/webhooks/github** - Receive GitHub webhook events

Example API usage:
```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": "Check the last 10 git commits and write a release summary", "persona": "coder"}'
```

### GitHub Integration
- **GitHub Actions**: Use the ready-made workflow template in `workspace/templates/ironclad-agent.yml`
- **GitHub Webhooks**: Configure webhooks to trigger IronClad tasks on push/issue events

### Telegram Bot
IronClad includes a Telegram bot for remote control:
- Configure allowed and trusted chat IDs in settings
- Use `/ask` commands to interact with IronClad from Telegram
- Example: `/ask Summarize my unread GitHub notifications`

### Model Context Protocol (MCP)
IronClad supports MCP server integration for extending capabilities with additional tools.

### LangGraph Compatibility
Export/import session state as LangGraph-compatible checkpoints for workflow integration.

### Remote Agents
Bridge to any OpenAI-compatible or LangGraph endpoint using the remote agent skill.

### RAG (Retrieval-Augmented Generation)
Local vector database using Ollama/OpenAI/NVIDIA embeddings for knowledge retrieval.

## Configuration Overview

All configuration lives in `settings.toml`. Here are the most important sections:

### Sandbox Configuration
```toml
[sandbox]
backend = "wsl"          # "wsl" | "docker" | "local"
```

### LLM Configuration
```toml
[llm]
default_provider = "ollama"   # "ollama" | "openai" | "anthropic" | "gemini" | "nvidia"
turbo_mode = false            # true = skip orchestrator and QA (fastest)
agentic_mode = true           # ReAct loop (recommended)
max_tool_calls = 30           # tool budget per task
max_parallel_tools = 4        # concurrent tool calls per turn
context_compression = false   # summarize dropped messages
# session_budget_secs = 600   # optional time cap
```

### Provider-Specific Settings (Example: Ollama)
```toml
[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"
keep_alive = "10m"
```

### Important Notes
- **API Keys**: Read from environment variables (never put them in settings.toml):
  ```bash
  export IRONCLAD_OPENAI_KEY="sk-..."
  export IRONCLAD_ANTHROPIC_KEY="sk-ant-..."
  export IRONCLAD_GITHUB_KEY="ghp_..."
  export IRONCLAD_TELEGRAM_KEY="123456:ABC-..."
  ```
- **Web Dashboard**: The easiest way to configure IronClad visually
- **Performance Tuning**: Use turbo_mode for speed or local backend for maximum performance (with security trade-offs)

## Use Cases

### Software Development
```
> Refactor the authentication module to use JWT tokens
> Review src/api/routes.rs for security vulnerabilities
> Write unit tests for the DAG planner and verify they pass
> Find all TODO comments in the codebase and create a task list
```

### Research & Analysis
```
> Research the latest transformer attention mechanisms across GitHub and arXiv
> Search Semantic Scholar for papers on retrieval-augmented generation with 1000+ citations
> Summarize the top 5 Rust async runtime projects and compare their architectures
```

### DevOps & CI
```bash
# Trigger via HTTP API
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": "Check the last 10 git commits and write a release summary", "persona": "coder"}'

# Or via GitHub Actions
gh workflow run ironclad-agent.yml --field task="Review the PR diff and suggest improvements"
```

### Automated Monitoring
```toml
# In settings.toml — schedule a nightly health check
[pulse]
enabled = true
```
```
> Schedule a job every day at 9am to check disk usage and alert if above 80%
> Set up a weekly job to scan open GitHub issues and draft a triage summary
```

### Long-Running Autonomous Tasks (Experiment Loop)
```
> Use experiment_loop to optimize the response latency of the API with at most 10 iterations
```
The `experiment_loop` skill proposes code changes, runs a metric command, and uses git stash to revert failed attempts — fully automated.

### Telegram Remote Control
```
# Send from Telegram (after configuring the bot)
/ask Summarize my unread GitHub notifications
/ask Run cargo test and tell me what failed
```

## Conclusion

IronClad represents a new paradigm in AI agent design — one that doesn't force you to choose between power and security. By treating the LLM as an untrusted component and implementing rigorous policy controls, IronClad enables organizations to safely harness the capabilities of autonomous AI agents for software development, research, DevOps, monitoring, and countless other use cases.

Whether you're a developer looking to automate tedious tasks, a researcher needing to synthesize information from multiple sources, or an operations team seeking to improve system reliability, IronClad provides a secure, extensible platform that grows with your needs.

Get started today by cloning the repository, installing the prerequisites, and experiencing the future of secure AI automation.