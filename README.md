# 🛡️ IronClad AI Agent

**The Secure-by-Design, Local-First Autonomous AI Agent Runtime & Multi-Agent Orchestration Harness — Built in Rust.**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/rust-stable-orange.svg)](https://www.rust-lang.org/)
[![Crates.io](https://img.shields.io/badge/crates.io-ironclad--ai--agent-red.svg)](https://crates.io/crates/ironclad-ai-agent)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()
[![Privacy: Local-First](https://img.shields.io/badge/privacy-100%25%20local--first-green.svg)]()
[![Security: Zero--Trust](https://img.shields.io/badge/security-three--ring%20zero--trust-blueviolet.svg)]()

<p align="center">
  <img src="docs/images/IronClad_Logo.png" alt="IronClad Logo" width="280" />
</p>

---

## 🌟 What is IronClad? (In Simple Terms)

Think of IronClad as an **armored operating system for AI agents**.

Most traditional AI agents give language models direct, unfettered access to your terminal and files, risking destructive mistakes, data leaks, and sky-high cloud bills.

**IronClad solves this with three foundational pillars:**

1. 🔒 **100% Private & Local-First**: Run entirely on your own machine using **Ollama, LM Studio, llama.cpp, or vLLM**. Zero subscription costs, zero token bills, and zero data leaving your hardware. *(Cloud LLMs like OpenAI, Claude, Gemini, and NVIDIA NIM are also fully supported when you need massive scale).*
2. 🛡️ **Zero-Trust Security Governor (Three-Ring Model)**: IronClad treats the AI as an *untrusted component*. Every single file edit, shell execution, or git command is inspected and gated by **The Governor** using a strict Traffic Light policy (Green/Yellow/Red/Blocked), Python venv isolation, and secret scrubbing before executing in sandboxes (Docker, WSL2, or Local host).
3. ⚡ **Autonomous Multi-Agent & CLI Harness**: IronClad is much more than a single-turn chatbot. It orchestrates background cron jobs (*Pulse*), runs Karpathy-style autonomous optimization loops (*Experiment Loop*), auto-detects and drives external AI CLI agents (*Pi Agent, Claude Code, Aider, OpenCode, Gemini CLI*), performs automated security scanning (*Bug Bounty*), and produces media (*Faceless YouTube Studio*).

---

## 🚀 Why IronClad? (The Hidden Superpowers)

| Capability | Traditional AI Agents | 🛡️ IronClad AI Agent |
|------------|----------------------|------------------------|
| **Security Architecture** | Direct shell/file access (High risk) | **Zero-Trust Three-Ring Model** (Governor + Sandbox isolation) |
| **Privacy & Cost** | Requires cloud API keys ($$$) | **100% Local-First** via Ollama / LM Studio ($0 & zero leaks) |
| **Execution Sandboxes** | Host execution only | Pluggable **Docker**, **WSL2**, or **Local** execution |
| **External Agent Orchestration** | Siloed / None | Auto-detects & drives **Pi Agent, Claude Code, Aider, OpenCode** via PTY |
| **Autonomous Optimization** | Manual trial-and-error | **Autonomous Experiment Loop** with automated `git stash` rollbacks |
| **Code Understanding** | Naive text grep / chunking | **Tree-sitter AST Graph RAG** (Rust, Python, JS, TS) |
| **Task Quality Control** | Single-shot output | **Two-Tier QA Review** (Plan QA + Step QA with auto-replanning) |
| **Autonomous Scheduling** | Interactive prompts only | **Pulse Scheduler** (Hourly workers, midnight reviews, memory summarization) |
| **User Experience** | CLI only | **Real-Time Web Dashboard** (`http://127.0.0.1:8080`) + **Interactive Ratatui TUI** |

---

## 🏗️ The Three-Ring Zero-Trust Architecture

IronClad enforces absolute separation of concerns between thinking, permissioning, and execution:

```
  ┌────────────────────────────────────────────────────────────┐
  │  Ring 1 — The Dreamer (LLM)                                │
  │  Proposes intentions & tool calls. Has ZERO direct access. │
  └─────────────────────────────┬──────────────────────────────┘
                                │  proposed actions
  ┌─────────────────────────────▼──────────────────────────────┐
  │  Ring 2 — The Governor & Quality Gate (Policy Engine)      │
  │  Traffic Light (Green/Yellow/Red/Blocked) · Secret Scrub   │
  │  Python Venv Guard · Workspace Jails · Path Traversal Gate │
  └─────────────────────────────┬──────────────────────────────┘
                                │  approved actions
  ┌─────────────────────────────▼──────────────────────────────┐
  │  Ring 3 — The Executor (Sandboxed Runtime)                 │
  │  WSL2 · Docker Container · Local Host Isolation            │
  └────────────────────────────────────────────────────────────┘
```

---

## 🎯 Real-World Capabilities & Use Cases

### 1. 💻 Autonomous Software Engineering & Code Review
Decomposes complex engineering goals into parallel Directed Acyclic Graphs (DAG), executes step-by-step with continuous QA verification, and writes code safely:
```
> Refactor the authentication module in src/api/routes.rs to use JWT tokens
> Review src/governor/policy.rs for security vulnerabilities and race conditions
> Run cargo test and fix any failing unit tests until 100% pass
```

### 2. 🔬 Autonomous Experiment Loop (Karpathy Autoresearch Pattern)
Inspired by Andrej Karpathy's `autoresearch` concept. Proposes code optimizations, runs test/benchmark metric commands, and automatically runs `git stash` to revert failed experiments:
```
> Use experiment_loop to optimize the query latency of the API with at most 10 iterations
```

### 3. 🤖 External CLI Agent Orchestration Hub
IronClad auto-detects external AI coding tools installed on your machine and can delegate complex programming tasks directly to them via virtual terminals (PTY):
```
> Delegate this refactoring task to Pi Agent
> Have Claude Code analyze the frontend components and fix CSS layout bugs
> Run Aider to generate complete integration test coverage
```

### 4. 🧠 AST-Level Codebase Search & RAG Knowledge Base
Constructs a semantic knowledge graph using **Tree-sitter AST parsers** for Rust, Python, JavaScript, and TypeScript with local vector embeddings:
```
> Query the knowledge base to explain how the Governor evaluates Traffic Light policies
> Where are all database session connections initialized across the codebase?
```

### 5. 🔍 Autonomous Bug Bounty & Reconnaissance
Monitors bug bounty programs, runs Nmap port discovery, filters false positives with AI verification, and notifies your team via Telegram:
```
> Run a quick bug bounty scan on the configured HackerOne targets
> Schedule a weekly vulnerability reconnaissance scan every Sunday at 2 AM
```

### 6. 🎬 Autonomous Faceless YouTube Studio
An end-to-end autonomous media creation pipeline. Scrapes trending topics, writes hook-heavy scripts, translates into multiple languages, synthesizes Edge-TTS voiceovers, downloads B-roll video clips, and burns subtitles into an exported MP4:
```
> Generate a faceless YouTube video about the latest breakthroughs in AI in English and French
> Schedule the faceless YouTube pipeline to run every morning at 4 AM for the tech niche
```

### 7. ⏰ Pulse Background Scheduler & Memory Summarization
Autonomous cron scheduling with natural-language parsing:
```
> Schedule a job every day at 9 AM to check disk usage and alert me if above 80%
> Schedule the hourly autonomous worker to evaluate backlog tasks
```

---

## 🖥️ Choose Your Interface

IronClad gives you five versatile ways to interact:

```
┌────────────────────────────────────────────────────────────────────────┐
│                      5 Ways to Experience IronClad                     │
├────────────────────┬────────────────────┬──────────────────────────────┤
│ 🌐 Web Dashboard   │ 💻 Terminal TUI    │ ⚡ CLI One-Shot Orchestrator  │
│ Control center at  │ Rich interactive   │ Single-command execution:    │
│ 127.0.0.1:8080     │ terminal with live │ `ironclad orchestrate        │
│ with visual config │ streaming & slash  │   --task "..."`              │
│ & guides.          │ commands.          │                              │
├────────────────────┴────────────────────┴──────────────────────────────┤
│ 🔗 Headless REST API & Webhooks         │ 📱 Telegram Remote Bot       │
│ Axum API (`POST /api/v1/tasks`) and     │ Control your agent & receive │
│ GitHub Webhook ingestion.               │ voice/text alerts remotely.  │
└─────────────────────────────────────────┴──────────────────────────────┘
```

---

## ⚡ Quick Start (Up & Running in 3 Minutes)

### Step 1 — Prerequisites
1. **Rust Stable Toolchain**: [rustup.rs](https://rustup.rs/) (if compiling or using `cargo install`)
2. **LLM Provider (Choose Local or Cloud)**:
   - **Local (100% Free & Private — Recommended)**: Install [Ollama](https://ollama.com/) and pull a model:
     ```bash
     ollama pull llama3
     ```
   - **Cloud (Optional)**: Export your OpenAI, Anthropic Claude, Google Gemini, or NVIDIA NIM API key.

### Step 2 — Install IronClad

**Install via Cargo (Recommended)**
```bash
cargo install ironclad-ai-agent
```

### Step 3 — Setup Configuration (`settings.toml` or `.env`)

IronClad works out of the box with zero setup when Ollama is running. You can configure your providers and models using `settings.toml` or environment variables in `.env`:

#### Option 1: Edit `settings.toml`
Create or edit `settings.toml` in your working directory:

```toml
[llm]
default_provider = "ollama"  # Options: "ollama", "openai", "anthropic", "gemini", "nvidia"
agentic_mode = true

# Local Models (Ollama)
[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"             # Or "qwen2.5-coder:32b", "qwen3.8", "deepseek-r1:32b"

# Local / Custom Models via OpenAI-compatible endpoints (LM Studio, vLLM)
[llm.openai]
base_url = "http://127.0.0.1:1234/v1"
model = "unsloth/qwen3.8-27b" # Or "meta-muse-glimmer", "gpt-4o"

# Cloud Providers (Anthropic, Gemini, NVIDIA)
[llm.anthropic]
model = "claude-3-5-sonnet-20240620"

[llm.gemini]
model = "gemini-1.5-pro"

[llm.nvidia]
model = "meta/llama-3.3-70b-instruct" # Or "meta-muse-glimmer"
```

#### Option 2: Environment Variables (`.env`)
You can export API keys in your environment or place them into a `.env` file:

```bash
# Cloud API Keys
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GEMINI_API_KEY="AIzaSy..."
export NVIDIA_API_KEY="nvapi-..."

# Local Endpoints & Custom Models (e.g. Qwen 3.8 / Meta Muse Glimmer)
export OPENAI_BASE_URL="http://127.0.0.1:1234/v1"
export OLLAMA_BASE_URL="http://127.0.0.1:11434"

# Optional Remote Telegram Bot
export IRONCLAD_TELEGRAM_KEY="123456:ABC-..."
```

### Step 4 — Launch IronClad

```bash
# Launch interactive mode (if installed via cargo)
ironclad

# Or run directly via cargo in your project/workspace
cargo run

# Or run a one-shot autonomous task
ironclad orchestrate --task "Analyze src/ and list all TODO comments"

# Or run one-shot task with cargo
cargo run -- orchestrate --task "Analyze src/ and list all TODO comments"
```

### Step 5 — Open the Web Dashboard (Recommended)
Navigate to **`http://127.0.0.1:8080`** in your browser to:
- ⚙️ **Configure Settings Visually**: Change models, execution backends, and API keys with a single click.
- 📖 **Follow Interactive Guides**: Step-by-step interactive walkthroughs for multi-agent workflows, RAG indexing, MCP integrations, and Pulse jobs.

---

## 🤖 Supported LLM Providers & Extended Models

IronClad is completely provider-agnostic and provides robust XML, JSON, and native tool-calling parsers for next-generation models:

| Provider | Type | Supported Models & Architectures | Native Tool Calling | Configuration Example (`settings.toml`) |
|----------|------|-----------------------------------|---------------------|-----------------------------------------|
| **Ollama** *(Default)* | Local | `llama3`, `qwen2.5-coder:32b`, `qwen3.8`, `deepseek-r1:32b` | ✅ XML / Structured | `default_provider = "ollama"`, `model = "llama3"` |
| **LM Studio / llama.cpp / vLLM** | Local | `unsloth/qwen3.8-27b`, `meta-muse-glimmer`, `qwen2.5-72b` | ✅ Compatible | Set `default_provider = "openai"`, `base_url = "http://127.0.0.1:1234/v1"` |
| **Anthropic Claude** | Cloud | `claude-3-5-sonnet-20240620`, `claude-3-5-haiku` | ✅ Native `tool_use` | `default_provider = "anthropic"`, `model = "claude-3-5-sonnet-20240620"` |
| **OpenAI** | Cloud | `gpt-4o`, `gpt-4o-mini`, `o1`, `o3-mini` | ✅ Native Function Calling | `default_provider = "openai"`, `model = "gpt-4o"` |
| **Google Gemini** | Cloud | `gemini-1.5-pro`, `gemini-1.5-flash`, `gemini-2.0-flash` | ✅ Multimodal Support | `default_provider = "gemini"`, `model = "gemini-1.5-pro"` |
| **NVIDIA NIM** | Cloud | `meta/llama-3.3-70b-instruct`, `meta-muse-glimmer`, `deepseek-r1` | ✅ High-throughput | `default_provider = "nvidia"`, `model = "meta/llama-3.3-70b-instruct"` |

---

## 🧰 Built-in Skills (Tools Matrix)

| Category | Available Skills |
|----------|------------------|
| 📁 **File System** | `read_file`, `write_file`, `list_directory`, `replace_in_file`, `grep_search` |
| 💻 **Shell & Sandbox** | `shell_execute`, `run_tests`, `system_info`, `reviewer`, `post_mortem` |
| 🌿 **Git Version Control** | `git_ops` (status, diff, log, branch, stash — write operations Traffic Light gated) |
| 🌐 **Web & Browsing** | `search_web`, `browser_scrape`, `browser_visit` (Playwright-powered) |
| 🔬 **Deep Research** | `deep_research` (Multi-source querying across GitHub, arXiv, and Semantic Scholar) |
| 🐙 **GitHub Integration** | `github_list_issues`, `github_list_prs` |
| 🧠 **Memory & Database** | `remember`, `search_history`, `query_history`, `query_logs`, `core_memory_*` |
| 👥 **Multi-Agent & Swarm** | `delegate_task`, `delegate_to_cli_agent`, `subprocess_manager`, `agent_coordination`, `self_improve` |
| 🧭 **Planning & Reasoning** | `list_tools`, `ask_user`, `write_todos`, `think`, `reflection`, `research_plan` |
| 📚 **AST Codebase RAG** | `query_knowledge_base` (Tree-sitter AST indexed vector database) |
| ⏰ **Autonomous Scheduling** | `schedule_job` (Pulse cron engine) |
| 🎬 **Autonomous Pipelines** | `experiment_loop`, `bug_bounty_scan`, `faceless_yt_pipeline` |
| 🗣️ **Voice & Translation** | `speak` (TTS), `transcribe` (Whisper STT), `translate` |
| 🔌 **External Tool Protocol** | Model Context Protocol (**MCP**) server auto-wrapping |

---

## 📖 Documentation Hub

Explore the complete documentation in the [`docs/`](docs/) directory:

- 🚀 **[Quick Start Guide](docs/quickstart.md)** — Step-by-step setup in under 5 minutes.
- ⚙️ **[Configuration Reference](docs/configuration.md)** — Complete `settings.toml` options and environment variables.
- 🏛️ **[Architecture Overview](docs/architecture.md)** — Three-Ring security model, DAG planner, and data flow.
- 📊 **[Web Dashboard Guide](docs/dashboard.md)** — Control center, SSE streaming, and settings editor.
- 💻 **[TUI Guide](docs/tui.md)** — Keyboard shortcuts, slash commands, and persona management.
- 🔬 **[Experiment Loop](docs/experiment_loop.md)** — Autonomous code optimization loops.
- 📚 **[RAG Knowledge Base](docs/rag.md)** — Codebase AST parsing and semantic vector search.
- ⏰ **[Pulse Scheduler](docs/pulse_scheduler.md)** — Natural language cron scheduling and autonomous background workers.
- 🔌 **[Integrations Guide](docs/integrations.md)** — CLI agents (Pi, Claude, Aider), LangGraph checkpoints, and Telegram.
- 🛠️ **[Custom Tools Guide](docs/custom_tools.md)** — Write custom Python/Bash/PowerShell tools with hot-reloading.
- 🛡️ **[Bug Bounty Scanner](docs/bug_bounty.md)** — Automated reconnaissance and AI vulnerability verification.
- 🎬 **[Faceless YouTube Pipeline](docs/faceless_youtube.md)** — End-to-end automated video production company.
- 📐 **[Architecture Decision Records (ADRs)](docs/adr/)** — Low-level engineering design decisions.

---

## 🛠️ Development & Testing

```bash
# Type check the codebase
cargo check

# Run all unit and integration tests
cargo test

# Run the deterministic offline benchmark suite
cargo test --test benchmarks

# Lint with Clippy
cargo clippy
```

---

## 📄 License

IronClad is open-source software licensed under the **[GNU General Public License v3.0](LICENSE)**.
