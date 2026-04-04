# HTTP API & Webhook Setup

IronClad includes an optionally configurable Axum-based HTTP server for submitting tasks externally and receiving GitHub webhooks. 

## Configuration

To enable the HTTP API, modify your `settings.toml` file to configure the `[api]` block:

```toml
[api]
enabled = true
# Choose an IP to bind to. "0.0.0.0" allows external network requests (useful within docker), 
# while "127.0.0.1" allows only requests from the same machine.
host = "127.0.0.1"
port = 3000

# Optional API key for authenticating requests.
# If set, clients must supply an Authorization header (`Authorization: Bearer <your-key>`).
api_key = "optional-secret-key"
```

## API Endpoints

### `POST /api/v1/tasks`

Used to submit standard conversational tasks directly to the agent.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <your-key> (If `api_key` is set in settings.toml)
```

**Payload:**
```json
{
  "task": "Summarize the current news",
  "persona": "researcher",
  "images": ["<base64-image>"]
}
```
*The `persona` and `images` fields are optional. `images` should contain base64-encoded image payloads for multimodal requests.*

**Response:**
Returns a JSON object upon completion of the LLM pipeline:
```json
{
  "result": "Here is the summary of the latest news: ..."
}
```
*Note: This is a synchronous blocking request that waits for the model to finish streaming output and QA. Depending on your model setup, this might take several minutes and could trigger timeouts on normal HTTP clients depending on their config. Ensure your client allows long timeouts.*

### `POST /api/v1/webhooks/github`

Used to ingest events coming from GitHub Webhooks.

When you configure this webhook inside GitHub repository settings:
1. Set the payload URL to your server address (e.g., `http://your-server.com:3000/api/v1/webhooks/github`)
2. Set the Content type to `application/json`
3. Trigger on `push` and `issue_comment` events.

IronClad will automatically receive these events in the background and spawn an Orchestrator Task to summarize or analyze the event context.
Since this endpoint serves as an event ingestion tool, it responds immediately with an `HTTP 200 OK` ("Webhook received") before continuing analysis in the background. Note that this endpoint currently bypasses the standard API key authentication, relying instead on obfuscated IPs or reverse proxy validation if deployed publicly.

### `GET /api/v1/sessions/{id}/status`

Poll the current status of a running or completed session.

**Path Parameters:**

| Parameter | Description |
|-----------|-------------|
| `id` | Session ID returned by a previous `POST /api/v1/tasks` call |

**Response (200):**
```json
{
  "session_id": "abc-123",
  "status": "running",
  "last_tool_call": "read_file",
  "message": null
}
```

**Status values:**

| Value | Meaning |
|-------|---------|
| `running` | Session is currently executing |
| `completed` | Session finished successfully |
| `failed` | Session terminated with an error |

Returns `404 Not Found` for unknown session IDs.

**Example:**
```bash
curl http://127.0.0.1:3000/api/v1/sessions/abc-123/status \
     -H "Authorization: Bearer optional-secret-key"
```

## Manual Testing

Once the server is running (with `api.enabled = true`), you can verify operation via cURL:

```bash
curl -X POST http://127.0.0.1:3000/api/v1/tasks \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer optional-secret-key" \
  -d '{"task": "Say hello world", "persona": "researcher"}'
```
