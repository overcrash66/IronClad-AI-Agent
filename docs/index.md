# IronClad Documentation

Welcome to the IronClad documentation. Use the sections below to navigate by topic.

---

## Getting Started

New to IronClad? Start here.

| Document | Description |
|----------|-------------|
| [Quick Start Guide](quickstart.md) | Install, configure, and run your first task in 5 minutes |
| [Web Dashboard](dashboard.md) | **Recommended**: Manage settings visually and follow interactive use-case guides |
| [Configuration Reference](configuration.md) | Every `settings.toml` option with defaults and examples |
| [TUI Guide](tui.md) | Terminal UI layout, slash commands, and keyboard shortcuts |

---

## Core Concepts

Understand how IronClad works before diving into advanced features.

| Document | Description |
|----------|-------------|
| [Architecture Overview](architecture.md) | Three-Ring security model, data flow, component diagram |
| [System Prompts](prompts.md) | How prompts are assembled, personas, `program.md`, customisation |
| [Autonomy & Traffic Light Policy](autonomy.md) | How Green / Yellow / Red / Blocked classification works |
| [Concurrent Tool Dispatch](concurrent-tools.md) | Parallel tool execution and `max_parallel_tools` config |
| [Session Budget](session-budget.md) | Wall-clock time limits for runaway sessions |
| [Context Compression](configuration.md#llm) | Summarizing dropped messages to preserve long-session context |

---

## Skills & Tools

Built-in capabilities and how to use them.

| Document | Description |
|----------|-------------|
| [Deep Research](deep_research.md) | Multi-source research across GitHub, arXiv, and Semantic Scholar |
| [Experiment Loop](experiment_loop.md) | Autonomous iterative improvement with metric-driven git checkpointing |
| [RAG Knowledge Base](rag.md) | Local codebase indexing and similarity search |
| [Write Todos](write-todos.md) | Persistent JSON task lists across agent turns |
| [program.md](program-md.md) | Per-workspace instructions injected into every task's system prompt |
| [Benchmark Suite](benchmarks.md) | Deterministic offline tests, TOML task format, `bench_results.json` |
| [Faceless YouTube](faceless_youtube.md) | Automated media company pipeline for generating videos via AI |
| [Bug Bounty Scanning](bug_bounty.md) | Automated reconnaissance and vulnerability verification using AI |
| [Telegram Integration](telegram_setup.md) | Full setup for bots, channels, and authorized chat IDs |
| [Custom Tools & Scripts](custom_tools.md) | Extend the agent with native Python/PowerShell/Shell scripts |
| [Memory & Session Persistence](memory_management.md) | SQLite history, context compression, and semantic memory search |

---

## Integrations & Deployment

Connect IronClad to external services and automate workflows.

| Document | Description |
|----------|-------------|
| [HTTP API Setup](api_setup.md) | REST endpoints: submit tasks, poll session status, GitHub webhooks |
| [GitHub Action](github-action.md) | CI/CD workflow template — run IronClad as a CI agent |
| [Integrations](integrations.md) | LangGraph checkpoints, Remote Agents, Telegram, GitHub events |
| [Remote Agent Bridge](remote-agent.md) | Delegate tasks to external HTTP agents (LangGraph, custom) |
| [Web Dashboard](dashboard.md) | Localhost observability UI — audit log, live status, sessions |
| [Pulse Scheduler](pulse_scheduler.md) | Cron background jobs with natural-language scheduling |
| [MCP Setup](mcp_setup.md) | Add tools via Model Context Protocol servers |
| [Browser Automation](browser_automation.md) | Playwright web scraping and visual browsing |

---

## Execution Backends

| Document | Description |
|----------|-------------|
| [Local Backend](local_backend.md) | Direct host execution — fastest, no isolation |
| [Configuration: `[sandbox]`](configuration.md#sandbox) | WSL, Docker, and Local backend options |

---

## Multimodal & Voice

| Document | Description |
|----------|-------------|
| [Multimodal Setup](multimodal_setup.md) | Image input, TTS, STT configuration |
| [Local STT Setup](local_stt_setup.md) | Speech-to-text with a locally hosted model |

---

## Architecture Decision Records

Low-level design rationale for core systems.

| Document | Description |
|----------|-------------|
| [ADR-001 Traffic Light Policy](adr/001-traffic-light-policy.md) | Why and how intent classification works |
| [ADR-002 Sandbox Backend Abstraction](adr/002-sandbox-backend-abstraction.md) | Pluggable execution backends design |
| [ADR-003 MCP Integration Pattern](adr/003-mcp-integration-pattern.md) | How MCP tools are discovered and registered |

---

## Quick Reference

### Skill Categories

| Category | Skill names |
|----------|-------------|
| Files | `read_file` `write_file` `list_directory` `replace_in_file` |
| Search | `grep_search` `search_web` `deep_research` |
| Shell | `shell_execute` `run_tests` `system_info` |
| Git | `git_ops` |
| Browser | `browser_scrape` `browser_visit` |
| GitHub | `github_list_issues` `github_list_prs` |
| Memory | `remember` `search_history` `query_history` `query_logs` |
| Planning | `delegate_task` `list_tools` `ask_user` `write_todos` |
| Workspace | `list_workspaces` `browse_workspace` `create_tool` |
| RAG | `query_knowledge_base` |
| Schedule | `schedule_job` |
| Remote | `remote_agent` |
| Media | `speak` `transcribe` `translate` |

### Key Environment Variables

```bash
IRONCLAD_OPENAI_KEY        # OpenAI API key
IRONCLAD_ANTHROPIC_KEY     # Anthropic API key
IRONCLAD_GITHUB_KEY        # GitHub personal access token
IRONCLAD_NVIDIA_KEY        # NVIDIA NIM API key
IRONCLAD_TELEGRAM_KEY      # Telegram bot token
```

### Key Files

| File | Purpose |
|------|---------|
| `settings.toml` | Main runtime configuration |
| `personas.toml` | Persona definitions and system prompts |
| `workspace/program.md` | Per-project instructions injected into every task |
| `memory.db` | Chat history and session storage (SQLite) |
| `ironclad_audit.db` | Full audit log of all agent actions (SQLite) |
| `bench_results.json` | Latest benchmark run output |

### Performance Quick Reference

| Goal | `settings.toml` change |
|------|------------------------|
| Maximum speed | `turbo_mode = true`, `backend = "local"`, `keep_alive = "10m"` |
| Preserve context in long sessions | `context_compression = true` |
| Limit concurrent tool calls | `max_parallel_tools = 2` |
| Cap wall-clock time | `session_budget_secs = 300` |
| Skip model routing | `orchestrator_enabled = false` |
| Skip quality review | `qa_enabled = false` |
