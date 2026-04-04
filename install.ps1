#Requires -Version 5.1
<#
.SYNOPSIS
  IronClad AI Agent — Automated Installer (Windows PowerShell)
.DESCRIPTION
  Downloads and installs Rust, compiles ironclad-ai-agent from crates.io,
  generates a default settings.toml, and optionally installs Ollama.
.EXAMPLE
  iwr -useb https://overcrash66.github.io/IronClad-AI-Agent/install.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

# ── Colours / Helpers ────────────────────────────────────────
function Write-Banner {
  Write-Host ""
  Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Blue
  Write-Host "  ║          IronClad AI Agent — Installer           ║" -ForegroundColor Blue
  Write-Host "  ║      Secure-by-Design Autonomous AI Agent        ║" -ForegroundColor Blue
  Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Blue
  Write-Host ""
}

function Write-Info    { param($Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Ok      { param($Msg) Write-Host "[  OK]  $Msg" -ForegroundColor Green }
function Write-Warn    { param($Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Fail    { param($Msg) Write-Host "[FAIL]  $Msg" -ForegroundColor Red; exit 1 }

# ── Check Visual Studio Build Tools ──────────────────────────
function Test-BuildTools {
  Write-Info "Checking for Visual Studio Build Tools..."

  $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vsWhere) {
    $installed = & $vsWhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($installed) {
      Write-Ok "Visual Studio Build Tools found."
      return
    }
  }

  # Fallback: check for cl.exe
  if (Get-Command cl.exe -ErrorAction SilentlyContinue) {
    Write-Ok "C++ compiler (cl.exe) found in PATH."
    return
  }

  Write-Warn "Visual Studio Build Tools with 'Desktop development with C++' NOT detected."
  Write-Warn "Download from: https://visualstudio.microsoft.com/downloads/"
  Write-Warn "Select 'Desktop development with C++' workload during installation."
  Write-Host ""
  $proceed = Read-Host "Continue anyway? (Rust compilation may fail) [y/N]"
  if ($proceed -notin @('y','Y','yes','Yes')) { exit 0 }
}

# ── Install Rust ─────────────────────────────────────────────
function Install-Rust {
  if (Get-Command rustup -ErrorAction SilentlyContinue) {
    $ver = (rustc --version 2>$null) -join ''
    Write-Ok "Rust is already installed ($ver)."
    Write-Info "Updating Rust toolchain..."
    rustup update stable 2>$null
    return
  }

  Write-Info "Installing Rust via rustup-init.exe..."
  $rustupUrl = "https://win.rustup.rs/x86_64"
  $rustupExe = "$env:TEMP\rustup-init.exe"

  Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupExe -UseBasicParsing
  & $rustupExe -y --default-toolchain stable
  Remove-Item $rustupExe -Force -ErrorAction SilentlyContinue

  # Add cargo to current session PATH
  $cargoPath = "$env:USERPROFILE\.cargo\bin"
  if ($env:PATH -notlike "*$cargoPath*") {
    $env:PATH = "$cargoPath;$env:PATH"
  }

  Write-Ok "Rust installed: $(rustc --version)"
}

# ── Install IronClad ─────────────────────────────────────────
function Install-IronClad {
  Write-Info "Installing ironclad-ai-agent from crates.io (this may take a few minutes)..."
  cargo install ironclad-ai-agent
  Write-Ok "ironclad-ai-agent installed successfully."
}

# ── Generate settings.toml ───────────────────────────────────
function New-Config {
  $configDir = "$env:USERPROFILE\.config\ironclad"
  $configFile = "$configDir\settings.toml"

  if (Test-Path $configFile) {
    Write-Ok "Config already exists at $configFile — skipping."
    return
  }

  New-Item -ItemType Directory -Force -Path $configDir | Out-Null

  @'
# IronClad Default Configuration
# Override nested config values via environment variable: IRONCLAD__<SECTION>__<KEY>

[general]
workspace_dir = "./scratchpad"
log_level = "info"
audit_db = "ironclad_audit.db"

[security]
allowed_path_patterns = ["**"]
blocked_path_patterns = ["**/.env", "**/.git/**", "**/secrets/**", "**/*.pem", "**/*.key"]
strict_path_validation = true
max_path_length = 4096
autonomous_mode = false

[sandbox]
backend = "local"
default_image = "Ubuntu"
timeout_secs = 60
memory_limit_mb = 4096
cpu_limit = 2.0
network_enabled = true

[llm]
default_provider = "ollama"
timeout_secs = 420
loop_timeout_secs = 180
max_retries = 2
max_model_size_b = 0
qa_enabled = true
orchestrator_enabled = true
force_use_default_model = true
turbo_mode = false
max_tool_calls = 30
agentic_mode = true

[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llama3"
vision = false
keep_alive = "10m"

[llm.openai]
base_url = "https://api.openai.com/v1"
model = "gpt-4o"

[llm.anthropic]
base_url = "https://api.anthropic.com/v1"
model = "claude-3-5-sonnet-20240620"

[llm.nvidia]
base_url = "https://integrate.api.nvidia.com/v1"
model = "meta/llama-3.1-70b-instruct"

[integrations.telegram]
enabled = false
# telegram_key = ""   # Set via env: IRONCLAD_TELEGRAM_KEY
allowed_chat_ids = []
trusted_chat_ids = []

[browser]
headless = true

[memory]
max_messages_per_session = 50
max_session_age_days = 30
auto_archive = true
cleanup_interval_hours = 24

[api]
enabled = false
host = "127.0.0.1"
port = 3000
api_key = ""

[dashboard]
enabled = true
port = 8080
username = ""
password = ""

[rag]
enabled = true
db_path = "memory.db"
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"
chunk_size = 512
chunk_overlap = 50
max_results = 10
min_similarity = 0.7
include_patterns = ["**/*.rs", "**/*.py", "**/*.js", "**/*.ts", "**/*.md", "**/*.txt"]
exclude_patterns = ["**/target/**", "**/node_modules/**", "**/.git/**", "**/dist/**", "**/build/**"]
auto_index = true
watch_changes = true
watch_debounce_ms = 1000
max_file_size_kb = 500
auto_inject_context = true
max_context_tokens = 2000

[tools]
python_venv_enforced = true
allow_system_commands = false

[tools.extensions]
py = "python3"
sh = "bash"
js = "node"
ps1 = "powershell -ExecutionPolicy Bypass -File"
'@ | Set-Content -Path $configFile -Encoding UTF8

  Write-Ok "Config generated at $configFile"
}

# ── Optional: Install Ollama ─────────────────────────────────
function Install-Ollama {
  if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Ok "Ollama is already installed."
    return
  }

  Write-Host ""
  $answer = Read-Host "Would you like to install Ollama (local LLM runtime)? [Y/n]"
  if ([string]::IsNullOrWhiteSpace($answer)) { $answer = 'y' }

  if ($answer -in @('y','Y','yes','Yes')) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
      Write-Info "Installing Ollama via winget..."
      winget install Ollama.Ollama --accept-source-agreements --accept-package-agreements 2>$null
      Write-Ok "Ollama installed. Pull a model with: ollama pull llama3"
    } else {
      Write-Warn "winget not found. Download Ollama manually from: https://ollama.com/download/windows"
    }
  } else {
    Write-Info "Skipping Ollama — install later from https://ollama.com"
  }
}

# ── Summary ──────────────────────────────────────────────────
function Write-Summary {
  $configDir = "$env:USERPROFILE\.config\ironclad"

  Write-Host ""
  Write-Host "  ✅  IronClad AI Agent installed successfully!" -ForegroundColor Green
  Write-Host ""
  Write-Host "  Quick start:" -ForegroundColor White
  Write-Host "    1. Pull an LLM model:  " -NoNewline; Write-Host "ollama pull llama3" -ForegroundColor Cyan
  Write-Host "    2. Run IronClad:       " -NoNewline; Write-Host "ironclad-ai-agent" -ForegroundColor Cyan
  Write-Host "    3. Open dashboard:     " -NoNewline; Write-Host "http://127.0.0.1:8080" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Configuration:  $configDir\settings.toml" -ForegroundColor White
  Write-Host ""
  Write-Host "  API Keys (set as environment variables):" -ForegroundColor White
  Write-Host '    $env:IRONCLAD_OPENAI_KEY    = "sk-..."'          -ForegroundColor DarkGray
  Write-Host '    $env:IRONCLAD_ANTHROPIC_KEY = "sk-ant-..."'      -ForegroundColor DarkGray
  Write-Host '    $env:IRONCLAD_GITHUB_KEY    = "ghp_..."'         -ForegroundColor DarkGray
  Write-Host '    $env:IRONCLAD_TELEGRAM_KEY  = "123456:ABC-..."'  -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "  Environment flag:" -ForegroundColor White
  Write-Host '    $env:IRONCLAD_ALLOW_LOCAL_EXEC = "1"' -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "  Docs:  https://overcrash66.github.io/IronClad-AI-Agent/" -ForegroundColor Cyan
  Write-Host ""
}

# ── Main ─────────────────────────────────────────────────────
Write-Banner
Test-BuildTools
Install-Rust
Install-IronClad
New-Config
Install-Ollama
Write-Summary
