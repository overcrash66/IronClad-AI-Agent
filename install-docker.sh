#!/usr/bin/env bash
# ============================================================
#  IronClad AI Agent — Docker Quick-Start
#  Usage: curl -fsSL https://overcrash66.github.io/ironclad-docs/install-docker.sh | bash
# ============================================================
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[  OK]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

echo -e "${BLUE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║    IronClad AI Agent — Docker Quick-Start        ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Check Docker ─────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Docker is not installed.${NC}"
  echo "Install Docker from: https://docs.docker.com/get-docker/"
  exit 1
fi

info "Docker found: $(docker --version)"

# ── Configuration directory ──────────────────────────────────
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ironclad"
WORKSPACE_DIR="$HOME/ironclad-workspace"

mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR"

# ── Generate settings.toml if missing ────────────────────────
if [ ! -f "$CONFIG_DIR/settings.toml" ]; then
  info "Generating default settings.toml..."
  cat > "$CONFIG_DIR/settings.toml" << 'TOML'
# IronClad Docker Configuration

[general]
workspace_dir = "/workspace"
log_level = "info"
audit_db = "ironclad_audit.db"

[security]
allowed_path_patterns = ["**"]
blocked_path_patterns = ["**/.env", "**/.git/**", "**/secrets/**", "**/*.pem", "**/*.key"]
strict_path_validation = true
autonomous_mode = false

[sandbox]
backend = "local"

[llm]
default_provider = "ollama"
timeout_secs = 420
max_tool_calls = 30
agentic_mode = true

[llm.ollama]
# Use host.docker.internal to reach Ollama on the host
base_url = "http://host.docker.internal:11434"
model = "llama3"
keep_alive = "10m"

[llm.openai]
base_url = "https://api.openai.com/v1"
model = "gpt-4o"

[llm.anthropic]
base_url = "https://api.anthropic.com/v1"
model = "claude-3-5-sonnet-20240620"

[integrations.telegram]
enabled = false
# telegram_key = ""   # Set via env: IRONCLAD_TELEGRAM_KEY
allowed_chat_ids = []
trusted_chat_ids = []

[dashboard]
enabled = true
port = 8080

[rag]
enabled = true
db_path = "memory.db"
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"

[tools]
python_venv_enforced = true
allow_system_commands = false
TOML
  success "Config generated at $CONFIG_DIR/settings.toml"
else
  success "Using existing config at $CONFIG_DIR/settings.toml"
fi

# ── Build Docker image ───────────────────────────────────────
DOCKERFILE="$CONFIG_DIR/Dockerfile"

cat > "$DOCKERFILE" << 'DOCKER'
FROM rust:1-bookworm AS builder
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
RUN cargo install ironclad-ai-agent
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates libssl3 curl git && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/cargo/bin/ironclad-ai-agent /usr/local/bin/ironclad-ai-agent
WORKDIR /workspace
EXPOSE 8080 3000
ENTRYPOINT ["ironclad-ai-agent"]
DOCKER

info "Building Docker image (this may take several minutes on first run)..."
docker build -t ironclad-ai-agent -f "$DOCKERFILE" "$CONFIG_DIR"
success "Docker image built: ironclad-ai-agent"

# ── Run ──────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✅  IronClad Docker image ready!${NC}"
echo ""
echo -e "  ${BOLD}Start IronClad:${NC}"
echo ""
echo -e "    ${CYAN}docker run -it --rm \\"
echo -e "      -v $CONFIG_DIR/settings.toml:/workspace/settings.toml \\"
echo -e "      -v $WORKSPACE_DIR:/workspace/scratchpad \\"
echo -e "      -p 8080:8080 -p 3000:3000 \\"
echo -e "      -e IRONCLAD_OPENAI_KEY=\$IRONCLAD_OPENAI_KEY \\"
echo -e "      -e IRONCLAD_TELEGRAM_KEY=\$IRONCLAD_TELEGRAM_KEY \\"
echo -e "      ironclad-ai-agent${NC}"
echo ""
echo -e "  ${BOLD}Dashboard:${NC} http://127.0.0.1:8080"
echo -e "  ${BOLD}Config:${NC}    $CONFIG_DIR/settings.toml"
echo -e "  ${BOLD}Workspace:${NC} $WORKSPACE_DIR"
echo ""
