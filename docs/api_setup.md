# HTTP API & Webhook Setup

IronClad includes a high-performance, hardened Axum-based HTTP server for submitting tasks externally, serving an OpenAI-compatible gateway, distributing multi-instance collaboration workloads, and receiving authenticated GitHub webhooks.

---

## Configuration

To enable the HTTP API, configure the `[api]` section in your `settings.toml` or `.env` file:

```toml
[api]
enabled = true
# Choose an IP to bind to. "127.0.0.1" binds only to local loopback.
# Binding to non-loopback (e.g., "0.0.0.0" or LAN IP) STRICTLY requires an api_key.
host = "127.0.0.1"
port = 3000

# API key for authenticating requests:
# - Required if binding to non-loopback host (0.0.0.0) — server refuses to start without it.
# - If running on 127.0.0.1 and omitted, IronClad auto-generates a secure ephemeral session key:
#   "ironclad-sec-<uuid>" printed to the terminal on startup.
api_key = "your-secure-api-key"

# Secret token for authenticating inbound GitHub webhooks via HMAC-SHA256:
# Must match the Secret configured in your GitHub repository Webhook settings.
webhook_secret = "your-github-webhook-secret"
```

### Environment Variables

```bash
IRONCLAD__API__ENABLED=true
IRONCLAD__API__HOST=127.0.0.1
IRONCLAD__API__PORT=3000
IRONCLAD__API__API_KEY="your-secure-api-key"
IRONCLAD__API__WEBHOOK_SECRET="your-github-webhook-secret"
```

> [!IMPORTANT]
> **Authentication Enforcement:**
> 1. **Non-Loopback Hosts**: If `host` is set to `0.0.0.0` or any non-loopback address, an `api_key` **must** be explicitly configured. If missing, IronClad terminates immediately with a critical security error to prevent exposing an unauthenticated agent to the network.
> 2. **Loopback Hosts**: If `api_key` is left blank on `127.0.0.1`, IronClad auto-generates an ephemeral bearer token (`ironclad-sec-<uuid>`) printed to the console.
> 3. **`allow_unauthenticated_localhost`**: This legacy option has been **deprecated and permanently disabled** for security.

---

## Running the Server

### 1. Headless Server (`ironclad serve`)
Run IronClad as a dedicated headless background server without launching the interactive Terminal UI:

```bash
# Start on configured port (default: 3000)
ironclad serve

# Override port from CLI
ironclad serve --port 3000
```

*When `[integrations.telegram]` is enabled, `ironclad serve` also runs the 24/7 background Telegram daemon automatically.*

### 2. Automatic Background Service
When `enabled = true` is configured under `[api]`, the HTTP server starts automatically as a background Tokio task whenever you launch the interactive TUI (`ironclad`).

---

## Security Middleware & Hardening

All inbound requests pass through strict security layers:
- **Security Headers**: Injects `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy`, and anti-MIME-sniffing headers.
- **Origin Validation**: Rejects cross-origin POST requests originating from untrusted web domains.
- **Request Body Limits**: Enforces a strict 1 MB body limit (`DefaultBodyLimit::max(1024 * 1024)`).
- **Rate Limiting**: Buffer layer with 100 requests/second rate limiting to prevent denial-of-service.

---

## API Endpoints Reference

### 1. `POST /api/v1/tasks`

Submits an autonomous task directly to the agent orchestrator.

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <your-api-key>
```

**Payload:**
```json
{
  "task": "Analyze src/api/routes.rs and list all security checks",
  "persona": "coder",
  "images": ["<optional-base64-encoded-image>"]
}
```

**Response (200 OK):**
```json
{
  "result": "Analysis complete: ..."
}
```

---

### 2. `POST /v1/chat/completions` & `POST /api/v1/chat/completions`

OpenAI-compatible chat completions gateway allowing IronClad to act as a backend drop-in replacement for OpenAI client libraries, third-party UIs, or benchmark harnesses (e.g. AgentBench).

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <your-api-key>
```

**Payload:**
```json
{
  "model": "ironclad",
  "messages": [
    {"role": "system", "content": "You are a helpful coding assistant."},
    {"role": "user", "content": "Write a Rust function to calculate SHA-256."}
  ],
  "temperature": 0.2,
  "max_tokens": 4096
}
```

---

### 3. `POST /api/v1/webhooks/github`

Ingests push and issue comment events from GitHub Webhooks.

**Security & Verification:**
- Inbound webhooks **strictly require** `webhook_secret` configured in `settings.toml` or `IRONCLAD__API__WEBHOOK_SECRET`.
- The incoming request must include the `X-Hub-Signature-256` header formatted as `sha256=<hex-digest>`.
- IronClad verifies the payload using **HMAC-SHA256** with constant-time equality check (`subtle::ConstantTimeEq`).
- If `webhook_secret` is unset, the endpoint returns `403 Forbidden` (`Webhook secret not configured`).
- If the signature is invalid or missing, it returns `401 Unauthorized` (`Invalid webhook signature`).

**GitHub Configuration:**
1. Payload URL: `http://your-server:3000/api/v1/webhooks/github`
2. Content type: `application/json`
3. Secret: `<your-webhook-secret>`
4. Events: Select individual events (e.g., `Pushes`, `Issue comments`).

---

### 4. `GET /api/v1/sessions/{id}/status`

Poll the current execution status of a session.

**Response (200 OK):**
```json
{
  "session_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "state": "running",
  "last_tool": "read_file",
  "result": null
}
```

**Status Values:**
- `running`: Currently executing agent turn or tool.
- `completed`: Task finished successfully with final result.
- `failed`: Task terminated with an error.

---

### 5. Multi-Instance Collab Endpoints (`collab/v1`)

Endpoints used for distributed swarm execution between peer IronClad nodes:

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/collab/health` | `GET` | None | Health check returning node capability, version, and load status |
| `/api/collab/tasks` | `POST` | Bearer | Submit a distributed DAG node task |
| `/api/collab/tasks/:id` | `GET` | Bearer | Poll distributed task status and unified git diff |

---

### 6. `GET /metrics`

Prometheus metrics endpoint exporting internal telemetry counters, scraper metrics, planner/worker latencies, and tool invocation statistics.

---

## Verification via cURL

```bash
# 1. Test task submission
curl -X POST http://127.0.0.1:3000/api/v1/tasks \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer your-secure-api-key" \
     -d '{"task": "Echo test", "persona": "default"}'

# 2. Test OpenAI chat completion gateway
curl -X POST http://127.0.0.1:3000/v1/chat/completions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer your-secure-api-key" \
     -d '{
       "model": "ironclad",
       "messages": [{"role": "user", "content": "Hello!"}]
     }'

# 3. Check Prometheus metrics
curl http://127.0.0.1:3000/metrics
```
