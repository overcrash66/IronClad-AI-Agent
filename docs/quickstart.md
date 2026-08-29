# Quick Start Guide

Get IronClad running and completing your first task in under 5 minutes.

---

## Step 1 — Install Prerequisites

| Tool | How to install |
|------|----------------|
| **Rust** (stable) | [rustup.rs](https://rustup.rs/) — required for building from source |
| **LM Studio** *(Recommended)* | [lmstudio.ai](https://lmstudio.ai/) — fast GPU local inference with 1-click model downloads |
| **Ollama** | [ollama.com](https://ollama.com/) — CLI-first local model runtime |
| **WSL2** *(Windows only)* | `wsl --install` in PowerShell as Administrator |

> **Platform Notes for Rust:**
> - **Linux**: May need `sudo apt-get install build-essential pkg-config libssl-dev`
> - **macOS**: Run `xcode-select --install` first
> - **Windows**: Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++"

**Local Model Setup (Choose LM Studio or Ollama):**
- **LM Studio (Recommended for v0.6.7+)**: Download a model (e.g. `Qwen 2.5 Coder 32B`, `DeepSeek-R1`, `Llama 3`), click **Start Server** on port `1234`.
- **Ollama**: Run `ollama pull llama3` in your terminal.

> **No cloud API key needed.** IronClad works entirely offline with LM Studio or Ollama.

---

## Step 2 — Install IronClad

**Install via Cargo (Recommended)**

```bash
cargo install ironclad-ai-agent
```

Verify the installation:

```bash
ironclad --version
```

---

## Step 3 — Configure (`settings.toml` or `.env`)

Open or create `settings.toml` in your working directory and set your execution backend and LLM provider.

**Local Models (Ollama, LM Studio / vLLM):**
```toml
[sandbox]
backend = "local"           # Or "wsl", "docker"

[llm]
default_provider = "ollama" # Or "openai", "anthropic", "gemini", "nvidia"
agentic_mode = true

[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"            # Or "qwen2.5-coder:32b", "qwen3.8", "deepseek-r1:32b"

# Local / Custom OpenAI-compatible endpoints:
[llm.openai]
base_url = "http://127.0.0.1:1234/v1"
model = "unsloth/qwen3.8-27b" # Or "meta-muse-glimmer", "gpt-4o"
```

**Cloud Providers (Anthropic, OpenAI, Gemini, NVIDIA):**
```toml
[llm]
default_provider = "anthropic"

[llm.anthropic]
model = "claude-3-5-sonnet-20240620"
```

Set your API keys via `.env` or environment variables:

```bash
# Windows PowerShell
$env:ANTHROPIC_API_KEY="sk-ant-..."
$env:OPENAI_API_KEY="sk-..."
$env:GEMINI_API_KEY="AIzaSy..."
$env:NVIDIA_API_KEY="nvapi-..."

# Linux / macOS / Bash
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="AIzaSy..."
export NVIDIA_API_KEY="nvapi-..."
```

---

## Step 4 — Run

```bash
# Launch interactive mode (installed binary)
ironclad

# Or run directly with cargo in your project directory
cargo run

# Or execute a one-shot autonomous task
ironclad orchestrate --task "Analyze codebase and summarize architecture"
# or
cargo run -- orchestrate --task "Analyze codebase and summarize architecture"
```

IronClad opens the interactive Terminal UI (TUI). You will see:

```
╔═══════════════════════════════════╗
║  IronClad — Secure AI Agent       ║
╚═══════════════════════════════════╝
Persona: default  │  Provider: ollama  │  Model: llama3

Type a task and press Enter. Type /help for commands.
>
```

---

## Step 5 — Web Dashboard & Interactive Guides (Recommended)

To unlock the easiest setup and learning experience, navigate to `http://127.0.0.1:8080` in your browser while the application is running.

- **⚙ Settings Tab**: Configure all settings, switch LLM providers, and safely manage API Keys visually without directly editing `settings.toml`.
- **📖 Guides Tab**: Follow 9 step-by-step interactive guides to learn how to test multi-agent research, RAG indexing, MCP integrations, Telegram, and background Scheduled jobs. You can click "Copy & Open Chat" to seamlessly deploy example prompts right to the dashboard Chat.

---

## Step 6 — Your First Tasks

Try these to verify everything is working:

```
> List the files in the current directory
```

```
> Read Cargo.toml and tell me the project version
```

```
> Search for all TODO comments in src/ and summarize them
```

```
> Run cargo check and tell me if there are any errors
```

Each task follows the **Think → Act → Observe** cycle. You will see the agent's reasoning and each tool call in the terminal.

---

## Common TUI Commands

| Command | What it does |
|---------|-------------|
| `/help` | Show all available slash commands |
| `/persona coder` | Switch to the Coder persona |
| `/persona researcher` | Switch to the Researcher persona |
| `/session` | Show current session ID |
| `/tools` | List all registered skills |
| `/clear` | Clear the screen |
| `Ctrl+C` | Exit |

---

## Running a One-Shot Task

```bash
# Run a task directly from the command line
./ironclad orchestrate --task "Write a summary of all Rust source files in src/"

# With a specific persona
./ironclad orchestrate --task "Review src/api/routes.rs for security issues" --persona coder
```

---

## What to Try Next

| Goal | What to do |
|------|------------|
| Enable cloud providers | [Configuration Reference](configuration.md) |
| Use a specific persona | [Personas](configuration.md#personas) |
| Schedule background jobs | [Pulse Scheduler](pulse_scheduler.md) |
| Connect via Telegram | [Integrations](integrations.md) |
| Submit tasks via HTTP | [HTTP API Setup](api_setup.md) |
| Research GitHub + papers | [Deep Research](deep_research.md) |
| Run in CI/CD | [GitHub Action](github-action.md) |
| Understand the security model | [Architecture](architecture.md) |
| See all options | [Configuration Reference](configuration.md) |

---

## Troubleshooting

### "connection refused" connecting to Ollama

Make sure Ollama is running:

```bash
ollama serve
```

On Windows with WSL2, use `127.0.0.1` (not `localhost`) in `settings.toml`:

```toml
[llm.ollama]
base_url = "http://127.0.0.1:11434"
```

### WSL2 command failures

Verify your WSL distro name matches `settings.toml`:

```bash
wsl --list
```

### Model responds slowly

Enable turbo mode and keep-alive:

```toml
[llm]
turbo_mode = true

[llm.ollama]
keep_alive = "10m"
```

Or switch to the `local` backend to eliminate sandbox overhead.

### "Blocked" actions

IronClad's Traffic Light policy blocks certain operations by design.  For a task that requires write operations in `autonomous_mode`, add to `settings.toml`:

```toml
[security]
autonomous_mode = true
```

This skips TUI approval dialogs for Yellow/Red intents while still enforcing hard-blocked operations (e.g. force-push, path traversal).
