#!/usr/bin/env bash
# ============================================================
#  IronClad AI Agent — Automated Installer (Linux / macOS / WSL2)
#  Usage: curl -fsSL https://overcrash66.github.io/ironclad-docs/install.sh | bash
# ============================================================
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  echo -e "${BLUE}${BOLD}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║          IronClad AI Agent — Installer           ║"
  echo "  ║      Secure-by-Design Autonomous AI Agent        ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[  OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

# ── OS & Package Manager Detection ──────────────────────────
detect_os() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$OS" in
    Linux*)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
      elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
      elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
      else
        DISTRO="unknown"
      fi
      ;;
    Darwin*) DISTRO="macos" ;;
    *)       fail "Unsupported OS: $OS. Use Windows PowerShell script instead." ;;
  esac

  info "Detected: ${BOLD}$OS${NC} ($DISTRO) — $ARCH"
}

# ── Install System Dependencies ─────────────────────────────
install_deps() {
  info "Installing system dependencies..."

  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop)
      sudo apt-get update -qq
      sudo apt-get install -y -qq build-essential pkg-config libssl-dev curl git
      ;;
    fedora)
      sudo dnf install -y gcc pkgconf-pkg-config openssl-devel curl git
      ;;
    centos|rhel|rocky|alma)
      sudo dnf install -y gcc pkgconf-pkg-config openssl-devel curl git || \
      sudo yum install -y gcc pkgconfig openssl-devel curl git
      ;;
    arch|manjaro|endeavouros)
      sudo pacman -Syu --noconfirm base-devel openssl curl git
      ;;
    opensuse*|sles)
      sudo zypper install -y gcc make pkg-config libopenssl-devel curl git
      ;;
    macos)
      if ! command -v xcode-select &>/dev/null || ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        warn "Please complete the Xcode CLT installation dialog, then re-run this script."
        exit 0
      fi
      # Homebrew (optional but recommended)
      if command -v brew &>/dev/null; then
        brew install openssl pkg-config 2>/dev/null || true
      fi
      ;;
    *)
      warn "Unknown distro '$DISTRO'. Please install a C compiler, pkg-config, and OpenSSL dev headers manually."
      ;;
  esac

  success "System dependencies installed."
}

# ── Install Rust ─────────────────────────────────────────────
install_rust() {
  if command -v rustup &>/dev/null; then
    success "Rust is already installed ($(rustc --version 2>/dev/null || echo 'unknown version'))."
    info "Updating Rust toolchain..."
    rustup update stable --no-self-update 2>/dev/null || true
  else
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"
    success "Rust installed: $(rustc --version)."
  fi

  # Ensure cargo is in PATH for the rest of this script
  export PATH="$HOME/.cargo/bin:$PATH"
}

# ── Install IronClad ─────────────────────────────────────────
install_ironclad() {
  info "Installing ironclad-ai-agent from crates.io (this may take a few minutes)..."
  cargo install ironclad-ai-agent
  success "ironclad-ai-agent installed: $(ironclad-ai-agent --version 2>/dev/null || echo 'installed')."
}

# ── Generate Default settings.toml ───────────────────────────
generate_config() {
  local CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ironclad"
  local CONFIG_FILE="$CONFIG_DIR/settings.toml"

  if [ -f "$CONFIG_FILE" ]; then
    success "Config already exists at $CONFIG_FILE — skipping."
    return
  fi

  mkdir -p "$CONFIG_DIR"

  cat > "$CONFIG_FILE" << 'TOML'
# IronClad Default Configuration
# Override nested config values via environment variable: IRONCLAD__<SECTION>__<KEY>
# e.g. IRONCLAD__LLM__DEFAULT_PROVIDER=openai

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
backend = "local"      # "docker" | "wsl" | "local"
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
TOML

  success "Config generated at ${BOLD}$CONFIG_FILE${NC}"
}

# ── Optional: Install Ollama ─────────────────────────────────
install_ollama() {
  if command -v ollama &>/dev/null; then
    success "Ollama is already installed."
    return
  fi

  echo ""
  echo -e "${YELLOW}Would you like to install Ollama (local LLM runtime)? [Y/n]${NC}"
  read -r -t 30 answer || answer="y"
  answer="${answer:-y}"

  if [[ "$answer" =~ ^[Yy]$ ]]; then
    info "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    success "Ollama installed. Pull a model with: ${BOLD}ollama pull llama3${NC}"
  else
    info "Skipping Ollama — you can install it later from https://ollama.com"
  fi
}

# ── Post-Install Summary ────────────────────────────────────
print_summary() {
  local CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ironclad"

  echo ""
  echo -e "${GREEN}${BOLD}  ✅  IronClad AI Agent installed successfully!${NC}"
  echo ""
  echo -e "  ${BOLD}Quick start:${NC}"
  echo -e "    1. Pull an LLM model:  ${CYAN}ollama pull llama3${NC}"
  echo -e "    2. Run IronClad:       ${CYAN}ironclad-ai-agent${NC}"
  echo -e "    3. Open dashboard:     ${CYAN}http://127.0.0.1:8080${NC}"
  echo ""
  echo -e "  ${BOLD}Configuration:${NC}  ${CONFIG_DIR}/settings.toml"
  echo ""
  echo -e "  ${BOLD}API Keys (set as environment variables):${NC}"
  echo -e "    export IRONCLAD_OPENAI_KEY=\"sk-...\"          ${BOLD}# OpenAI${NC}"
  echo -e "    export IRONCLAD_ANTHROPIC_KEY=\"sk-ant-...\"   ${BOLD}# Anthropic${NC}"
  echo -e "    export IRONCLAD_GITHUB_KEY=\"ghp_...\"         ${BOLD}# GitHub${NC}"
  echo -e "    export IRONCLAD_TELEGRAM_KEY=\"123456:ABC-..\" ${BOLD}# Telegram${NC}"
  echo ""
  echo -e "  ${BOLD}Environment flags:${NC}"
  echo -e "    export IRONCLAD_ALLOW_LOCAL_EXEC=1           ${BOLD}# Allow local tool execution${NC}"
  echo ""
  echo -e "  ${BOLD}Docs:${NC}  https://overcrash66.github.io/ironclad-docs/"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────
main() {
  banner
  detect_os
  install_deps
  install_rust
  install_ironclad
  generate_config
  install_ollama
  print_summary
}

main "$@"
