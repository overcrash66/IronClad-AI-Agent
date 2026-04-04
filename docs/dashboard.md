# IronClad Dashboard - Control Center

The IronClad Dashboard provides a secure, lightweight web interface for real-time visibility into the agent's operations. It serves as the "Control Center" for monitoring and managing IronClad.

## Quick Start

1. Add to your `.env` file:
   ```bash
   IRONCLAD__DASHBOARD__ENABLED=true
   IRONCLAD__DASHBOARD__USERNAME=admin
   IRONCLAD__DASHBOARD__PASSWORD=your_password
   ```

2. Run IronClad:
   ```bash
   cargo run
   ```

3. Open `http://127.0.0.1:8080` in your browser

If port `8080` is already in use, IronClad will try the next three ports automatically. Check the startup logs for the final bound port.

## Features

- **⚙️ Settings Management**: Visually edit your `settings.toml`, securely manage API keys, and gracefully restart the platform directly from the UI.
- **📖 Interactive Guides**: Step-by-step interactive tutorials for Webhooks, APIs, Agent building, RAG indexing, MCP tools, Telegram bots, Pulse jobs, and Sandbox execution.
- **Task Visualization**: View Audit Log history and the Scheduler's upcoming cron jobs
- **Recent Sessions**: Inspect recent session IDs, personas, and creation timestamps
- **Live Monitoring**: Real-time feed via Server-Sent Events (SSE) displaying current execution steps and Traffic Light status
- **Raw Logs**: Streaming log output from the application

## Security

The dashboard enforces strict security constraints:

1. **Local Access Only**: The server binds exclusively to `127.0.0.1`, preventing any external network access
2. **Basic Authentication**: Username/password protection to restrict access to authorized users only

## Configuration

### Option 1: Environment Variables (.env file) - Recommended

Using environment variables keeps sensitive credentials out of your config file. Add these to your `.env` file:

```bash
# Enable the dashboard
IRONCLAD__DASHBOARD__ENABLED=true

# Set the port (defaults to 8080 if not specified)
IRONCLAD__DASHBOARD__PORT=8080

# Configure Basic Auth (highly recommended)
IRONCLAD__DASHBOARD__USERNAME=admin
IRONCLAD__DASHBOARD__PASSWORD=your_secure_password
```

### Option 2: settings.toml

Alternatively, enable the dashboard in your `settings.toml`:

```toml
[dashboard]
enabled = true
port = 8080
username = "admin"
password = "your-secure-password"
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | Enable/disable the dashboard server |
| `port` | u16 | `8080` | Preferred port for the dashboard (bound to 127.0.0.1 only; runtime retries up to `port + 3`) |
| `username` | string | `None` | Username for Basic Auth (optional) |
| `password` | string | `None` | Password for Basic Auth (optional) |

### Security Recommendations

- Always set a strong `username` and `password` when enabling the dashboard
- Use environment variables for sensitive credentials:
  ```bash
  export IRONCLAD__DASHBOARD__USERNAME="admin"
  export IRONCLAD__DASHBOARD__PASSWORD="your-secure-password"
  ```

## Accessing the Dashboard

Once enabled, access the dashboard at:

```
http://127.0.0.1:8080
```

You will be prompted for credentials if authentication is configured.

If the configured port is unavailable, look for the actual bound port in the startup logs.

## API Endpoints

The dashboard exposes the following REST API endpoints:

### `GET /api/config`
Returns the current `settings.toml` configuration as JSON, with sensitive fields masked securely.

### `POST /api/config`
Accepts a JSON payload to overwrite `settings.toml`. Unmodified sensitive fields are automatically restored from the existing config to prevent data loss.

### `POST /api/config/restart`
Initiates a graceful restart of the IronClad process to quickly apply configuration changes.

### `GET /api/config/env-check`
Returns a list of configuration keys currently overridden by environment variables (e.g., `IRONCLAD__LLM__OLLAMA__MODEL`).

### `GET /api/audit`

Returns the most recent audit log entries.

**Query Parameters:**
- `limit` (optional): Number of entries to return (default: 50)

**Response:**
```json
[
  {
    "id": "uuid",
    "timestamp": "2024-01-01T00:00:00Z",
    "actor": "user",
    "action_type": "prompt",
    "payload": "...",
    "status": "allowed"
  }
]
```

### `GET /api/jobs`

Returns all scheduled Pulse jobs.

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Daily Summary",
    "schedule": "0 0 9 * * *",
    "job_type": { "LlmTask": "Summarize activity" },
    "enabled": true
  }
]
```

### `GET /api/sessions`

Returns recent session metadata.

**Response:**
```json
[
  {
    "id": "uuid",
    "persona": "default",
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

### `GET /api/status` (SSE)

Server-Sent Events stream for real-time status updates.

**Event Format:**
```json
{
  "step": "Executing command",
  "traffic_light": "Green",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### `GET /api/logs` (SSE)

Server-Sent Events stream for real-time log output.

**Event Format:**
Plain text log lines.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     IronClad Dashboard                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Audit Log │  │  Job List   │  │   Live Status       │  │
│  │   (Table)   │  │   (Table)   │  │   (SSE Stream)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │               Raw Logs (SSE Stream)                  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      IronClad Core                           │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐              │
│  │   Audit    │ │   Pulse    │ │ Orchestrator│              │
│  │  Logger    │ │  Scheduler │ │             │              │
│  └────────────┘ └────────────┘ └────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Traffic Light Status

The dashboard displays the current Traffic Light classification:

| Status | Color | Description |
|--------|-------|-------------|
| Green | 🟢 | Safe, read-only operations - auto-approved |
| Yellow | 🟡 | Potentially impactful operations - user notified |
| Red | 🔴 | Dangerous operations - requires explicit confirmation |
| Blocked | 🚫 | Strictly forbidden operations - cannot be bypassed |

## Troubleshooting

### Dashboard not accessible

1. Verify `enabled = true` in `[dashboard]` section
2. Check the logs for the actual bound port; IronClad may have fallen back from the configured port to one of the next three ports
3. Ensure you're accessing via `127.0.0.1` (not `localhost` if there are DNS issues)

### Authentication fails

1. Verify credentials in `settings.toml` or environment variables
2. Ensure the Authorization header is being sent correctly
3. Check browser console for any 401 errors

### No live updates

1. Check browser console for SSE connection errors
2. Verify the IronClad application is running and logging
3. SSE connections may timeout after extended idle periods - refresh the page

## Development

The dashboard UI is a single HTML file with inline CSS and JavaScript, embedded directly into the binary via `include_str!()`. This approach:

- Eliminates the need for a separate build process
- Reduces binary dependencies
- Ensures the UI is always available with the binary

To modify the UI, edit `src/dashboard/index.html` and rebuild the project.
