# IronClad Web Dashboard — Observability & Control Center

The IronClad Dashboard is a secure, lightweight single-page web interface (`http://127.0.0.1:8080`) providing full real-time visibility, mission control, secrets management, and system administration.

---

## Quick Start & First-Run Setup

### 1. Enable in `settings.toml` or `.env`

```toml
[dashboard]
enabled = true
port = 8080
# Optional: pre-configure credentials, or set them interactively via First-Run Setup
username = "admin"
password = "your-secure-password"
```

Or via environment variables:
```bash
IRONCLAD__DASHBOARD__ENABLED=true
IRONCLAD__DASHBOARD__PORT=8080
IRONCLAD__DASHBOARD__USERNAME=admin
IRONCLAD__DASHBOARD__PASSWORD=your-secure-password
```

### 2. Launch IronClad

```bash
cargo run
# or
ironclad
```

### 3. First-Run Setup Token (Initial Admin Claim)

If no username/password is pre-configured, IronClad enters **First-Run Setup Mode** for security. On startup, a high-entropy one-time setup token is printed in a console banner:

```
╔════════════════════════════════════════════════════════════════════════════════╗
║                    🛡️ IRONCLAD DASHBOARD FIRST-RUN SETUP                      ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ Setup Token:  a1b2c3d4e5f67890abcdef1234567890                                ║
║ Enter this token on the dashboard or pass 'setup_token' in POST /api/setup     ║
╚════════════════════════════════════════════════════════════════════════════════╝
```

1. Open `http://127.0.0.1:8080` in your browser.
2. Enter the **Setup Token** printed in your terminal.
3. Choose your administrator username and password.
4. Once submitted, the setup token is immediately cleared and invalidated.

> [!NOTE]
> If port `8080` is already in use, IronClad automatically tries the next three ports (`8081`–`8083`). Check the startup logs for the bound port.

---

## 🛡️ Security Architecture & Hardening

The dashboard enforces strict defense-in-depth measures:

1. **Loopback Exclusive (`127.0.0.1`)**: The HTTP listener binds strictly to the loopback interface, preventing external network access.
2. **Terminal Setup Token**: First-time admin creation requires proof of local console access, eliminating unauthenticated takeover risks.
3. **Session Cookies & Sliding Refresh**: Successful authentication issues a cryptographically secure HTTP-only cookie (`ironclad_session`) with constant-time token comparison and a 24-hour sliding inactivity expiration (`SESSION_TTL_SECS = 86400`).
4. **Per-IP Lockout Throttling**: Repeated authentication failures result in progressive per-IP lockout delays.
5. **Dangerous Config Modification Gating**: Dangerous options (e.g. relaxing security policies or escaping directory bounds) cannot be modified via the `/api/config` web API.
6. **Chat Rate Limiting**: Interactive web chat enforces per-session rate limits (10 requests/minute, 4096-character max message length).

---

## 🌟 Dashboard Tabs & Features

### 1. ⚙️ Settings Management
- Visually configure LLM providers, model preferences, sandboxes, and integrations without touching TOML syntax.
- View active environment variable overrides (`GET /api/config/env-check`).
- Trigger a graceful runtime restart (`POST /api/config/restart`) to reload configuration seamlessly.

### 2. 🔐 Secrets Vault Tab
- Manage API keys, bearer tokens, HTTP basic credentials, and database connection strings.
- Enforce strict per-secret `allowed_domains` to govern outbound network egress.
- **Database Probing**: Test database connectivity with non-destructive TCP handshake probes (`POST /api/vault/probe-db`) for PostgreSQL, MySQL, SQLite, MongoDB, and Redis.
- Inspect an immutable audit log of all vault operations (`GET /api/vault/audit`).

### 3. 🎯 Mission Control Tab
- Create, track, checkpoint, and manage long-running multi-hour or multi-day missions.
- Inspect milestone breakdown, step progress, and hierarchical checklists.
- Enforces strict mission gates: missions cannot be marked complete until all milestones and steps succeed (or explicit forced overrides are logged).

### 4. 🤝 Multi-Instance Collab Tab
- Inspect connected peer IronClad nodes and their real-time health (`GET /api/collab/health`).
- Distribute DAG sub-tasks across peers with automatic unified diff collection.
- Monitor active advisory path claims and conflict-avoidance locks.

### 5. 🤖 CLI Agents Tab
- Displays live status of auto-detected external CLI AI tools (*Pi Agent*, *Claude Code*, *Aider*, *OpenCode*, *Gemini CLI*).
- Enable or disable specific agents on the fly; choices persist across sessions.

### 6. 🧹 Project Maintenance Tab
- Inspect database storage metrics and file sizes.
- **Vacuum Databases**: Run SQLite `VACUUM` and optimize `memory.db`, `ironclad_vault.db`, and `ironclad_audit.db`.
- **Prune Old Sessions & Logs**: Clean up stale interactive sessions, old audit records, log files, and temporary scratch files.

### 7. 🌿 Workspace & Git Branch Management
- **Visual Diff Viewer**: Inspect modified files and view unified side-by-side git diffs before approving changes.
- **Agent Branch Isolation**: Safe git branch creation (`agent/*` scope), branch switching, and downloading zipped branch snapshots.

### 8. 📖 Interactive Learning Guides
- 9 step-by-step interactive tutorials covering APIs, Webhooks, RAG indexing, MCP tool integration, Telegram bots, Pulse jobs, and Sandboxes.
- Click "Copy & Open Chat" to load guided prompt examples directly into the dashboard chat interface.

### 9. 📊 Real-Time Observability
- **Live Step Feed**: Server-Sent Events (SSE) stream displaying current reasoning steps and Traffic Light status (🟢 Green, 🟡 Yellow, 🔴 Red, 🚫 Blocked).
- **Log Viewer**: Live streaming logs with search, filtering, and export capabilities.

---

## REST API Reference

| Endpoint | Method | Description |
|---|---|---|
| `/api/setup/status` | `GET` | Returns whether dashboard is in first-run setup mode |
| `/api/setup` | `POST` | Sets initial admin credentials (requires `setup_token`) |
| `/api/config` | `GET` | Returns `settings.toml` with sensitive credentials masked |
| `/api/config` | `POST` | Updates `settings.toml` safely preserving masked values |
| `/api/config/restart` | `POST` | Initiates graceful process restart |
| `/api/config/env-check` | `GET` | Lists keys overridden by environment variables |
| `/api/audit` | `GET` | Returns recent audit log entries (supports `?limit=N`) |
| `/api/audit/export` | `GET` | Exports audit log as downloadable JSON |
| `/api/jobs` | `GET` | Lists all scheduled Pulse cron jobs |
| `/api/jobs/:id/toggle` | `POST` | Toggles job active state |
| `/api/sessions` | `GET` | Lists recent interactive and autonomous sessions |
| `/api/sessions/:id/messages` | `GET` | Fetches conversation messages for a session |
| `/api/status` | `GET` | SSE stream of real-time execution steps and Traffic Light status |
| `/api/logs` | `GET` | SSE stream of live log lines |
| `/api/vault/secrets` | `GET` / `POST` | List or create Secrets Vault credentials |
| `/api/vault/secrets/:id` | `PUT` / `DELETE`| Update or delete a secret |
| `/api/vault/probe-db` | `POST` | TCP connectivity probe on database DSN |
| `/api/vault/audit` | `GET` | View Vault access audit events |
| `/api/missions` | `GET` / `POST` | List or create persistent missions |
| `/api/missions/:id` | `GET` / `PATCH` / `DELETE` | View, update, or delete a mission |
| `/api/missions/:id/steps/:step` | `POST` | Update mission step status |
| `/api/collab/peers` | `GET` | Lists configured multi-instance collab peers |
| `/api/collab/claims` | `GET` | Lists active advisory path claims |
| `/api/cli-agents` | `GET` | Lists detected external CLI agents and enabled status |
| `/api/cli-agents/:name/enable` | `POST` | Enables an external CLI agent |
| `/api/cli-agents/:name/disable` | `POST` | Disables an external CLI agent |
| `/api/workspace/changes` | `GET` | Lists uncommitted file modifications in workspace |
| `/api/workspace/diff` | `GET` | Returns unified diff for a modified workspace file |
| `/api/git/branches` | `GET` / `POST` | List or create git branches |
| `/api/maintenance/stats` | `GET` | Storage usage statistics across databases and logs |
| `/api/maintenance/vacuum` | `POST` | Runs SQLite VACUUM on databases |
| `/api/maintenance/prune-sessions` | `POST` | Prunes sessions older than configured retention |
| `/api/maintenance/prune-audit` | `POST` | Prunes audit records older than configured retention |
