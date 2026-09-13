# Telegram Bot Integration

IronClad can be used as a conversational agent and monitoring tool via Telegram. It supports receiving tasks, providing live updates, and sending notifications for long-running autonomous background processes.

## Setup Instructions

### 1. Create a Telegram Bot
1. Search for **@BotFather** on Telegram and start a conversation.
2. Send the command: `/newbot`.
3. Follow the instructions to choose a name and username for your bot.
4. BotFather will provide an **API Token**. *Keep this secret!*

### 2. Find Your Chat ID
For security, IronClad only responds to authorized Chat IDs.
1. Start a chat with your new bot.
2. Send the message: `/id`.
3. If IronClad is not already configured, use a Telegram ID bot (like **@userinfobot**) to find your unique numeric ID.

### 3. Configure IronClad
Add your token and authorized IDs to `settings.toml` or set them as environment variables:

```toml
[integrations.telegram]
enabled = true
allowed_chat_ids = [123456789, -100987654321] # Whitelisted users/groups
trusted_chat_ids = [123456789]                # Elevated operators (Governor bypass)
verbosity = "compact"                          # "quiet" | "compact" | "verbose"
send_typing_action = true                      # Send "typing" action while working
show_tool_progress = false                     # Broadcast individual tool invocations
voice_reply = false                            # Return audio replies via TTS
```

> **Security Note on Tokens:** Store your bot token in the `.env` file or environment variable as `IRONCLAD_TELEGRAM_KEY="123456:ABC-..."` rather than committing it to version control.

### 4. Authorize Groups or Channels
To use IronClad in a group or channel:
1. Add your bot as an **Administrator**.
2. Send `/id` in the group/channel.
3. Add the resulting *negative* ID (e.g., `-100...`) to your `allowed_chat_ids` list.

## 24/7 Headless Daemon (`ironclad serve`)

When running IronClad as a long-running service (`ironclad serve`), IronClad automatically spawns a background **Headless Telegram Daemon** if `[integrations.telegram].enabled = true` and `IRONCLAD_TELEGRAM_KEY` (or the `telegram` secret in Secrets Vault) is present.

The daemon provides continuous, unassisted remote control:
- **Zero-poll manual interaction**: Polling runs asynchronously in the background alongside the HTTP API, Webhook server, and Dashboard.
- **Persistent Sessions**: Each Telegram user chat receives an isolated conversational session (`telegram:<chat_id>`) backed by SQLite memory (`ironclad_memory.db`), preserving task history and context across turns.
- **Instance Conflict Resolution**: Detects `409 Conflict` errors if another process is polling the same bot token and gracefully backs off.

```bash
# Launch IronClad server with headless Telegram polling daemon
ironclad serve
```

---

## Built-in Commands

Authorized users can issue the following quick commands:

| Command | Description |
|---|---|
| `/status`, `/ping` | Displays active server status, current default LLM model, chat ID, and active workspace path. |
| `/id` | Replies with the sender's Telegram chat ID (useful for initial verification). |
| `/help` | Shows available command overview and interaction capabilities. |

---

## Multimodal Capabilities

The headless daemon natively handles voice, video notes, and visual media:

### 1. Voice Notes & Audio (STT)
When a voice message, video note, or audio file (`.ogg`, `.mp4`, `.mp3`) is received:
1. IronClad downloads the media file to a secure temporary path.
2. Transcribes audio using either:
   - **Local STT**: Configured via `llm.local_stt_cmd` (e.g., local Whisper Python script).
   - **Cloud STT**: OpenAI Whisper via the `openai` secret in Secrets Vault or `llm.openai.api_key`.
3. Sends the transcribed text to the LLM orchestrator as the prompt.
4. Cleans up temporary audio files immediately after transcription.

### 2. Photos & Vision Analysis
When an image or photo is sent with or without a caption:
1. IronClad downloads the highest-resolution photo variant and encodes it into base64.
2. Injects the image into the orchestrator prompt using the message caption (defaults to `"Analyze this image."` if no caption is provided).
3. Vision-capable models (e.g. Claude 3.5 Sonnet, GPT-4o) analyze diagrams, error screenshots, architectural drawings, or code snippets directly.

---

## Features

### Conversational Tasks
Message your bot directly with any task:
> "Check the status of the bug bounty scans."  
> "Run cargo test and let me know if everything passes."  
> "Investigate the memory leak in auth middleware."

### Verbosity & Progress Streaming
Control how much information IronClad sends during task execution:

- **`verbosity = "quiet"`** (Default): Sends only task receipts, final completions, and errors. Minimal message volume.
- **`verbosity = "compact"`**: Sends concise milestone progress messages.
- **`verbosity = "verbose"`**: Automatically broadcasts every intermediate tool execution (`🌐 Browsing...`, `💻 Running command...`, `🔬 Researching...`).
- **`send_typing_action = true`**: Sends Telegram's native "typing" status while the agent is reasoning or waiting for tool execution, giving visual feedback that work is in progress.
- **`show_tool_progress = true/false`**: Explicitly override whether intermediate tool progress notices are sent as chat messages regardless of verbosity setting.

### Autonomous Notifications
Various background skills use Telegram to notify you upon completion:
- **Faceless YouTube**: Sends a video preview and completion summary.
- **Bug Bounty**: Broadcasts findings that exceed the configured `confidence_threshold`.
- **Pulse Jobs**: Alerts you when scheduled background tasks start and finish.

---

## Security & Privacy (Strict Fail-Closed)

- **Fail-Closed Whitelist (`allowed_chat_ids`)**: IronClad enforces strict authorization before processing **any** commands or revealing any system metadata. Messages from chat IDs not in `allowed_chat_ids` are immediately rejected with an alert (`⚠️ Unauthorized. This bot is private.`) and logged to the audit log (`telegram_unauthorized`, `Denied`).
- **Anti-Spam Rate Limiting**: Unauthorized access notifications are rate-limited to once per 60 seconds per unknown chat ID to avoid log or notification flood.
- **Operator Bypass (`trusted_chat_ids`)**: Users listed in `trusted_chat_ids` are recognized as trusted operators; commands initiated by these IDs automatically pass the Governor's confirmation gate for Yellow/Red operations.
- **Audit Logging**: All incoming authorized prompts are recorded with `telegram_headless_prompt` in `ironclad_audit.db` along with execution status.
- **Secrets Protection**: Bot tokens can be managed securely in the [Secrets Vault](secrets_vault.md) under secret ID `telegram` or via `IRONCLAD_TELEGRAM_KEY`. Any bot token or authorization key sent in prompt output is dynamically scrubbed by the Aho-Corasick memory scrubber.
