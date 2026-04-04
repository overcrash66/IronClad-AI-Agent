# Quick Start Guide

Get IronClad running and completing your first task in under 5 minutes.

---

## Step 1 — Install Prerequisites

| Tool | How to install |
|------|----------------|
| **Rust** (stable) | [rustup.rs](https://rustup.rs/) — required for building from source |
| **Ollama** | [ollama.com](https://ollama.com/) |
| **WSL2** *(Windows only)* | `wsl --install` in PowerShell as Administrator |

> **Platform Notes for Rust:**
> - **Linux**: May need `sudo apt-get install build-essential pkg-config libssl-dev`
> - **macOS**: Run `xcode-select --install` first
> - **Windows**: Install [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/) with "Desktop development with C++"

After installing Ollama, pull a model:

```bash
ollama pull llama3
```

> **No cloud API key needed.** IronClad works entirely offline with Ollama.

---

## Step 2 — Install IronClad

### Option A — Install via crates.io (Recommended)

```bash
cargo install ironclad
```

Verify the installation:

```bash
ironclad --version
```

### Option B — Download Pre-built Binaries

Go to the [GitHub Releases](https://github.com/overcrash66/IronClad/releases) page and download the latest version for your platform:

| Platform | Artifact |
|----------|----------|
| **Windows** | `ironclad-windows-x86_64.zip` |
| **Linux (x86_64)** | `ironclad-linux-x86_64.tar.gz` |
| **macOS (Apple Silicon)** | `ironclad-macos-aarch64.tar.gz` |
| **macOS (Intel)** | `ironclad-macos-x86_64.tar.gz` |

Once downloaded, extract the archive to a folder of your choice.

### Option C — Build from Source (Developers)

```bash
git clone https://github.com/overcrash66/IronClad.git
cd IronClad
cargo build --release
```

---

## Step 3 — Configure

Open `settings.toml` and set your execution backend.

**Windows with WSL (default):**
```toml
[sandbox]
backend = "wsl"
default_image = "Ubuntu"   # name of your WSL distro

[llm]
default_provider = "ollama"

[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"
```

**Windows/Linux without a sandbox:**
```toml
[sandbox]
backend = "local"

[llm]
default_provider = "ollama"
turbo_mode = true   # fastest possible — skip orchestrator and QA
```

**Using OpenAI or Anthropic instead of Ollama:**
```toml
[llm]
default_provider = "anthropic"   # or "openai"

[llm.anthropic]
model = "claude-sonnet-4-20250514"
```

Set your API key in the environment (never in `settings.toml`):

```bash
# Windows PowerShell
$env:IRONCLAD_ANTHROPIC_KEY="sk-ant-..."

# Linux / macOS
export IRONCLAD_ANTHROPIC_KEY="sk-ant-..."
```

---

## Step 4 — Run

```bash
# Windows
.\ironclad.exe

# Linux / macOS
./ironclad
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

## Step 5 — Your First Tasks

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
